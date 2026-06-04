extends Node
## Runtime singleton for Mimic connection setup and network state.
## [br][br]
## The Mimic autoload owns the active [MultiplayerPeer], starts and stops
## server/client connections, and emits connection lifecycle signals for game
## code and UI.

## Emitted when Mimic changes connection state.
## [param state] and [param previous_state] are [enum NetworkState] values.
signal state_changed(state: NetworkState, previous_state: NetworkState)
## Emitted when a server or client start attempt fails before reaching its target state.
## [param attempted_state] is a [enum NetworkState] value.
signal start_failed(attempted_state: NetworkState, error: Error, message: String)
## Emitted after a server peer starts listening.
signal server_started(port: int)
## Emitted after a client peer begins connecting.
signal client_started(address: String, port: int)
## Emitted after the local client connects to a server.
signal client_connected()
## Emitted after the local client fails to connect to a server.
signal client_connection_failed(message: String)
## Emitted on clients when the server disconnects.
signal server_disconnected()
## Re-emitted from [MultiplayerAPI.peer_connected].
signal peer_connected(peer_id: int)
## Re-emitted from [MultiplayerAPI.peer_disconnected].
signal peer_disconnected(peer_id: int)
## Emitted after [method stop] finishes shutting down the active peer.
## Use [signal state_changed], [signal server_disconnected], or
## [signal client_connection_failed] to react to involuntary disconnects.
signal stopped()
## Emitted after a background UPnP port mapping attempt succeeds or fails.
## [param result] is a [enum UPNP.UPNPResult] value.
signal port_mapping_finished(result: UPNP.UPNPResult, external_address: String)

## Transport backends Mimic can start.
enum TransportType {
	## No network transport.
	OFFLINE,
	## Godot's ENet transport.
	ENET,
	## Godot's WebSocket transport.
	WEBSOCKET,
	## Reserved for future WebRTC signaling support.
	WEBRTC,
}
## Editor-only connection action run automatically when the Mimic autoload starts.
enum EditorAutoConnectMode {
	## Do not start networking automatically.
	DISABLED,
	## Try server mode first, then join as a client on expected local hosting failures.
	SERVER_THEN_CLIENT,
	## Start a client automatically.
	CLIENT,
	## Start a server automatically.
	SERVER,
}
## Coarse connection lifecycle state for the local peer.
enum NetworkState {
	## No active network peer.
	OFFLINE,
	## Server peer is listening for clients.
	SERVER_LISTENING,
	## Client peer has started connecting but is not connected yet.
	CLIENT_CONNECTING,
	## Client peer is connected to a server.
	CLIENT_CONNECTED,
}
## Protocol selection for UPnP port mappings.
enum PortMappingProtocol {
	## Use UDP for ENet and TCP for WebSocket.
	TRANSPORT_DEFAULT,
	## Map TCP only.
	TCP,
	## Map UDP only.
	UDP,
	## Map both TCP and UDP.
	TCP_AND_UDP,
}

var _state: NetworkState = NetworkState.OFFLINE
var _last_client_address := ""
var _last_client_port := 0
var _port_mapper := MimicPortMapper.new()


func _ready() -> void:
	_connect_multiplayer_signals()
	if not _port_mapper.finished.is_connected(_finish_port_mapping):
		_port_mapper.finished.connect(_finish_port_mapping)

	if OS.has_feature("editor"):
		_start_editor_auto_connect.call_deferred()


func _exit_tree() -> void:
	_delete_port_mappings()
	_reset_peer_state()
	_port_mapper.wait_to_finish()


## Starts a server with the configured transport.
## [br][br]
## Pass [param port_override] or [param bind_address_override] to override the
## matching Project Settings value for this call only. The default [code]-1[/code]
## port and empty bind address use Project Settings.
func start_server(port_override: int = -1, bind_address_override: String = "") -> Error:
	return _start_server(port_override, bind_address_override)


## Starts a client connection with the configured transport.
## [br][br]
## Pass [param address_override] or [param port_override] to override the
## matching Project Settings value for this call only. The default empty address
## and [code]-1[/code] port use Project Settings.
func start_client(address_override: String = "", port_override: int = -1) -> Error:
	_connect_multiplayer_signals()

	var transport := _get_transport_type()
	var address := MimicProjectSettings.address.strip_edges()
	if not address_override.is_empty():
		address = address_override.strip_edges()

	var port := port_override if port_override > 0 else MimicProjectSettings.port
	if address.is_empty():
		return _fail_start(
			NetworkState.CLIENT_CONNECTING,
			ERR_INVALID_PARAMETER,
			"Client address is empty."
		)

	var error := _validate_start(NetworkState.CLIENT_CONNECTING, port)
	if error != OK:
		return error

	var peer: MultiplayerPeer = null
	MimicLog.log(
		"Connecting to",
		address,
		"port",
		port,
		"using",
		MimicTransport.get_display_name(transport)
	)
	var transport_result: MimicTransport.PeerResult = MimicTransport.create_client_peer(
		transport,
		address,
		port
	)
	error = transport_result.error
	peer = transport_result.peer
	if peer == null:
		if transport == TransportType.OFFLINE or transport == TransportType.WEBRTC:
			return _fail_unavailable_transport(NetworkState.CLIENT_CONNECTING)
		return _fail_unsupported_transport(NetworkState.CLIENT_CONNECTING)

	if error != OK:
		peer.close()
		var message := "Unable to start client: %s." % error_string(error)
		return _fail_start(NetworkState.CLIENT_CONNECTING, error, message)

	_last_client_address = address
	_last_client_port = port
	multiplayer.multiplayer_peer = peer
	_change_state(NetworkState.CLIENT_CONNECTING)
	MimicLog.log("Client connection started.")
	client_started.emit(address, port)
	return OK


## Tries to start a server, then falls back to [method start_client] on expected local hosting
## failures.
## Fallback is skipped on dedicated/server exports.
func start_server_or_client() -> Error:
	# This avoids Godot's noisy ENet bind error when the local port is already occupied.
	# The real _start_server call below remains authoritative when the best-effort probe passes.
	var preflight_error := MimicLocalAutoConnect.get_host_preflight_error(
		_get_transport_type(),
		MimicProjectSettings.port,
		MimicTransport.get_bind_address(),
		_has_active_peer()
	)
	if preflight_error != OK:
		if not MimicLocalAutoConnect.can_fallback_to_client(preflight_error, _has_active_peer()):
			return preflight_error

		return start_client()

	var server_error := _start_server(-1, "", true)
	if server_error == OK:
		return OK
	if not MimicLocalAutoConnect.can_fallback_to_client(server_error, _has_active_peer()):
		return server_error

	return start_client()


## Stops the active peer, requests owned UPnP mapping deletion when enabled, and returns to
## offline state.
func stop() -> void:
	if _state == NetworkState.OFFLINE and not _has_active_peer():
		return

	_delete_port_mappings()
	_reset_peer_state()
	MimicLog.log("Network stopped.")
	stopped.emit()


## Cancels an in-progress client connection.
func cancel_connection() -> void:
	if _state == NetworkState.CLIENT_CONNECTING:
		stop()


## Returns the current [enum NetworkState].
func get_state() -> NetworkState:
	return _state


## Returns the last external address reported by UPnP port forwarding.
func get_external_address() -> String:
	return _port_mapper.get_external_address()


## Returns the local multiplayer peer ID, or [code]0[/code] while offline or connecting.
func get_local_peer_id() -> int:
	if _state == NetworkState.OFFLINE or _state == NetworkState.CLIENT_CONNECTING:
		return 0
	if not multiplayer.has_multiplayer_peer():
		return 0
	return multiplayer.get_unique_id()


## Returns connected remote peer IDs, or an empty array when no multiplayer peer is active.
func get_peer_ids() -> PackedInt32Array:
	if _state == NetworkState.OFFLINE or not multiplayer.has_multiplayer_peer():
		return PackedInt32Array()
	return multiplayer.get_peers()


## Returns [code]true[/code] while the local peer is listening as a server.
func is_server() -> bool:
	return _state == NetworkState.SERVER_LISTENING


## Returns [code]true[/code] after the local peer has connected as a client.
func is_client() -> bool:
	return _state == NetworkState.CLIENT_CONNECTED


## Returns [code]true[/code] while a client connection attempt is in progress.
func is_connecting() -> bool:
	return _state == NetworkState.CLIENT_CONNECTING


## Returns [code]true[/code] when Mimic is not hosting, connecting, or connected.
func is_offline() -> bool:
	return _state == NetworkState.OFFLINE


func _start_server(
	port_override: int = -1,
	bind_address_override: String = "",
	quiet_expected_failure: bool = false
) -> Error:
	_connect_multiplayer_signals()

	var transport := _get_transport_type()
	var port := port_override if port_override > 0 else MimicProjectSettings.port
	var error := _validate_start(NetworkState.SERVER_LISTENING, port)
	if error != OK:
		return error

	var peer: MultiplayerPeer = null
	MimicLog.log(
		"Starting server on port",
		port,
		"using",
		MimicTransport.get_display_name(transport)
	)
	var bind_address := MimicTransport.get_bind_address(bind_address_override)
	var transport_result: MimicTransport.PeerResult = MimicTransport.create_server_peer(
		transport,
		port,
		bind_address
	)
	error = transport_result.error
	peer = transport_result.peer
	if peer == null:
		if transport == TransportType.OFFLINE or transport == TransportType.WEBRTC:
			return _fail_unavailable_transport(NetworkState.SERVER_LISTENING)
		return _fail_unsupported_transport(NetworkState.SERVER_LISTENING)

	if error != OK:
		peer.close()
		if quiet_expected_failure and MimicLocalAutoConnect.is_expected_host_failure(error):
			return error
		var message := "Unable to start server: %s." % error_string(error)
		return _fail_start(NetworkState.SERVER_LISTENING, error, message)

	multiplayer.multiplayer_peer = peer
	_change_state(NetworkState.SERVER_LISTENING)
	_add_port_mapping(port)
	MimicLog.log("Server listening on port", port)
	server_started.emit(port)
	return OK


func _start_editor_auto_connect() -> void:
	MimicEditorAutoConnector.try_start(
		is_inside_tree(),
		is_offline(),
		_has_active_peer(),
		start_server_or_client,
		start_client,
		start_server
	)


func _validate_start(state: NetworkState, port: int) -> Error:
	var transport := _get_transport_type()

	if port < 1 or port > 65_535:
		return _fail_start(state, ERR_PARAMETER_RANGE_ERROR, "Port must be between 1 and 65535.")

	if not _is_known_transport(transport):
		return _fail_unsupported_transport(state)

	if transport == TransportType.ENET and OS.has_feature("web"):
		return _fail_start(
			state,
			ERR_UNAVAILABLE,
			"ENet is not available on web exports. Use WebSocket instead."
		)

	# Invalid start requests do not tear down a currently working peer.
	if transport == TransportType.OFFLINE or transport == TransportType.WEBRTC:
		return _fail_unavailable_transport(state)

	if _has_active_peer():
		_delete_port_mappings()
		_reset_peer_state()

	return OK


func _connect_multiplayer_signals() -> void:
	# Re-arm these before start attempts in case the active MultiplayerAPI changed.
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	if not multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.connect(_on_connected_to_server)
	if not multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.connect(_on_connection_failed)
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)


func _on_peer_connected(peer_id: int) -> void:
	MimicLog.log("Peer connected:", peer_id)
	peer_connected.emit(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	MimicLog.log("Peer disconnected:", peer_id)
	peer_disconnected.emit(peer_id)


func _on_connected_to_server() -> void:
	_change_state(NetworkState.CLIENT_CONNECTED)
	MimicLog.log("Connected to server.")
	client_connected.emit()


func _on_connection_failed() -> void:
	var message := "Unable to connect to %s:%d." % [_last_client_address, _last_client_port]
	_close_peer()
	_change_state(NetworkState.OFFLINE)
	MimicLog.warning(message)
	client_connection_failed.emit(message)


func _on_server_disconnected() -> void:
	_close_peer()
	_change_state(NetworkState.OFFLINE)
	MimicLog.warning("Disconnected from server.")
	server_disconnected.emit()


func _change_state(state: NetworkState) -> void:
	if _state == state:
		return

	var previous_state := _state
	_state = state
	state_changed.emit(_state, previous_state)


func _fail_start(state: NetworkState, error: Error, message: String) -> Error:
	MimicLog.warning(message)
	start_failed.emit(state, error, message)
	return error


func _fail_unavailable_transport(state: NetworkState) -> Error:
	match _get_transport_type():
		TransportType.OFFLINE:
			return _fail_start(
				state,
				ERR_UNAVAILABLE,
				"Offline transport cannot start network connections."
			)
		TransportType.WEBRTC:
			return _fail_start(
				state,
				ERR_UNAVAILABLE,
				"WebRTC transport needs signaling and is not implemented yet."
			)
		_:
			return _fail_unsupported_transport(state)


func _fail_unsupported_transport(state: NetworkState) -> Error:
	return _fail_start(state, ERR_UNAVAILABLE, "Unsupported transport.")


func _is_known_transport(transport: TransportType) -> bool:
	match transport:
		TransportType.OFFLINE, TransportType.ENET, TransportType.WEBSOCKET, TransportType.WEBRTC:
			return true
		_:
			return false


func _has_active_peer() -> bool:
	if _state != NetworkState.OFFLINE:
		return true
	if not multiplayer.has_multiplayer_peer():
		return false

	var current_peer := multiplayer.multiplayer_peer
	if current_peer == null or current_peer is OfflineMultiplayerPeer:
		return false

	return current_peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED


func _close_peer() -> void:
	var current_peer := multiplayer.multiplayer_peer if multiplayer.has_multiplayer_peer() else null
	if current_peer is OfflineMultiplayerPeer:
		return

	# Install the offline peer before closing so close-side effects cannot observe stale state.
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	if current_peer != null:
		current_peer.close()


func _reset_peer_state() -> void:
	# Explicit teardown clears last-attempt data; involuntary disconnects keep it for inspection.
	_close_peer()
	_last_client_address = ""
	_last_client_port = 0
	_change_state(NetworkState.OFFLINE)


func _get_transport_type() -> TransportType:
	var transport: TransportType = MimicProjectSettings.transport
	return transport


func _add_port_mapping(port: int) -> void:
	_port_mapper.add_mapping(
		port,
		_get_port_mapping_protocols(),
		_get_port_mapping_description()
	)


func _finish_port_mapping(error: UPNP.UPNPResult, external_address: String) -> void:
	if error != UPNP.UPNP_RESULT_SUCCESS:
		MimicLog.warning("UPnP port forwarding failed:", error)
	else:
		MimicLog.log("UPnP port forwarding ready.", external_address)
	port_mapping_finished.emit(error, external_address)


func _delete_port_mappings() -> void:
	_port_mapper.delete_mapping()


func _get_port_mapping_protocols() -> PackedStringArray:
	var protocols := PackedStringArray()
	var transport := _get_transport_type()
	var mapping_protocol: PortMappingProtocol = MimicProjectSettings.port_mapping_protocol
	match mapping_protocol:
		PortMappingProtocol.TRANSPORT_DEFAULT:
			protocols.append("TCP" if transport == TransportType.WEBSOCKET else "UDP")
		PortMappingProtocol.TCP:
			protocols.append("TCP")
		PortMappingProtocol.UDP:
			protocols.append("UDP")
		PortMappingProtocol.TCP_AND_UDP:
			protocols.append("TCP")
			protocols.append("UDP")
	return protocols


func _get_port_mapping_description() -> String:
	var project_name := String(ProjectSettings.get_setting("application/config/name", "Mimic"))
	return "Mimic" if project_name.is_empty() else project_name
