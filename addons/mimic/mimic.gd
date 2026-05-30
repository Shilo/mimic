extends Node
## Runtime singleton for Mimic connection setup and network state.
## [br][br]
## The Mimic autoload owns the active [MultiplayerPeer], starts and stops
## server/client connections, and emits connection lifecycle signals for game
## code and UI.

## Emitted when Mimic changes connection state.
## [param state] and [param previous_state] are [enum NetworkState] values.
signal state_changed(state: int, previous_state: int)
## Emitted when a server or client start attempt fails before reaching its target state.
## [param attempted_state] is a [enum NetworkState] value.
signal start_failed(attempted_state: int, error: int, message: String)
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
signal port_mapping_finished(result: int, external_address: String)

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
var _port_mapper := _MimicPortMapper.new()


func _ready() -> void:
	_connect_multiplayer_signals()
	if not _port_mapper._finished.is_connected(_finish_port_mapping):
		_port_mapper._finished.connect(_finish_port_mapping)


func _exit_tree() -> void:
	_port_mapper._wait_to_finish()


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

	var address := address_override.strip_edges() if not address_override.is_empty() else MimicProjectSettings.address.strip_edges()
	var port := port_override if port_override > 0 else MimicProjectSettings.port
	if address.is_empty():
		return _fail_start(NetworkState.CLIENT_CONNECTING, ERR_INVALID_PARAMETER, "Client address is empty.")

	var error := _validate_start(NetworkState.CLIENT_CONNECTING, port)
	if error != OK:
		return error

	var peer: MultiplayerPeer = null
	MimicLog.log("Connecting to", address, "port", port, "using", _get_transport_name(_get_transport_type()))
	match _get_transport_type():
		TransportType.ENET:
			var enet_peer := ENetMultiplayerPeer.new()
			var bind_address := MimicProjectSettings.bind_address
			if not bind_address.is_empty() and bind_address != "*":
				enet_peer.set_bind_ip(bind_address)
			error = enet_peer.create_client(
				address,
				port,
				MimicProjectSettings.enet_channel_count,
				MimicProjectSettings.enet_in_bandwidth,
				MimicProjectSettings.enet_out_bandwidth,
				MimicProjectSettings.enet_client_local_port
			)
			peer = enet_peer
		TransportType.WEBSOCKET:
			var websocket_peer := WebSocketMultiplayerPeer.new()
			websocket_peer.handshake_timeout = MimicProjectSettings.websocket_handshake_timeout
			error = websocket_peer.create_client(_get_websocket_url(address, port))
			peer = websocket_peer
		TransportType.OFFLINE, TransportType.WEBRTC:
			return _fail_unavailable_transport(NetworkState.CLIENT_CONNECTING)
		_:
			return _fail_start(NetworkState.CLIENT_CONNECTING, ERR_UNAVAILABLE, "Unsupported transport.")

	if error != OK:
		peer.close()
		return _fail_start(NetworkState.CLIENT_CONNECTING, error, "Unable to start client: %s." % error_string(error))

	_last_client_address = address
	_last_client_port = port
	multiplayer.multiplayer_peer = peer
	_change_state(NetworkState.CLIENT_CONNECTING)
	MimicLog.log("Client connection started.")
	client_started.emit(address, port)
	return OK


## Tries to start a server, then falls back to [method start_client] on expected local hosting failures.
## Fallback is skipped on dedicated/server exports.
func start_server_if_first_else_client() -> Error:
	var server_error := _start_server(-1, "", true)
	if server_error == OK:
		return OK
	if not _can_fallback_to_client_after_server_failure(server_error):
		return server_error

	return start_client()


## Stops the active peer, requests owned UPnP mapping deletion when enabled, and returns to offline state.
func stop() -> void:
	_delete_port_mappings()
	_close_peer()
	_last_client_address = ""
	_last_client_port = 0
	_change_state(NetworkState.OFFLINE)
	MimicLog.log("Network stopped.")
	stopped.emit()


## Cancels an in-progress client connection.
func cancel_connection() -> void:
	if _state == NetworkState.CLIENT_CONNECTING:
		stop()


## Returns the current [enum NetworkState].
func get_state() -> int:
	return _state


## Returns the last external address reported by UPnP port forwarding.
func get_external_address() -> String:
	return _port_mapper._get_external_address()


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


## Returns [code]true[/code] when Mimic has no active network peer.
func is_offline() -> bool:
	return _state == NetworkState.OFFLINE


func _start_server(port_override: int = -1, bind_address_override: String = "", quiet_expected_failure: bool = false) -> Error:
	_connect_multiplayer_signals()

	var port := port_override if port_override > 0 else MimicProjectSettings.port
	var error := _validate_start(NetworkState.SERVER_LISTENING, port)
	if error != OK:
		return error

	var peer: MultiplayerPeer = null
	MimicLog.log("Starting server on port", port, "using", _get_transport_name(_get_transport_type()))
	match _get_transport_type():
		TransportType.ENET:
			var enet_peer := ENetMultiplayerPeer.new()
			var bind_address := _get_bind_address(bind_address_override)
			if not bind_address.is_empty() and bind_address != "*":
				enet_peer.set_bind_ip(bind_address)
			error = enet_peer.create_server(
				port,
				MimicProjectSettings.max_clients,
				MimicProjectSettings.enet_channel_count,
				MimicProjectSettings.enet_in_bandwidth,
				MimicProjectSettings.enet_out_bandwidth
			)
			peer = enet_peer
		TransportType.WEBSOCKET:
			var websocket_peer := WebSocketMultiplayerPeer.new()
			websocket_peer.handshake_timeout = MimicProjectSettings.websocket_handshake_timeout
			error = websocket_peer.create_server(port, _get_bind_address(bind_address_override))
			peer = websocket_peer
		TransportType.OFFLINE, TransportType.WEBRTC:
			return _fail_unavailable_transport(NetworkState.SERVER_LISTENING)
		_:
			return _fail_start(NetworkState.SERVER_LISTENING, ERR_UNAVAILABLE, "Unsupported transport.")

	if error != OK:
		peer.close()
		if quiet_expected_failure and _should_fallback_to_client(error):
			return error
		return _fail_start(NetworkState.SERVER_LISTENING, error, "Unable to start server: %s." % error_string(error))

	multiplayer.multiplayer_peer = peer
	_change_state(NetworkState.SERVER_LISTENING)
	_add_port_mapping(port)
	MimicLog.log("Server listening on port", port)
	server_started.emit(port)
	return OK


func _validate_start(state: NetworkState, port: int) -> Error:
	if port < 1 or port > 65535:
		return _fail_start(state, ERR_PARAMETER_RANGE_ERROR, "Port must be between 1 and 65535.")

	if _get_transport_type() == TransportType.ENET and OS.has_feature("web"):
		return _fail_start(state, ERR_UNAVAILABLE, "ENet is not available on web exports. Use WebSocket instead.")

	if _get_transport_type() == TransportType.OFFLINE or _get_transport_type() == TransportType.WEBRTC:
		return _fail_unavailable_transport(state)

	if _has_active_peer():
		stop()

	return OK


func _connect_multiplayer_signals() -> void:
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


func _fail_start(state: NetworkState, error: int, message: String) -> Error:
	MimicLog.warning(message)
	start_failed.emit(state, error, message)
	return error


func _fail_unavailable_transport(state: NetworkState) -> Error:
	match _get_transport_type():
		TransportType.OFFLINE:
			return _fail_start(state, ERR_UNAVAILABLE, "Offline transport cannot start network connections.")
		TransportType.WEBRTC:
			return _fail_start(state, ERR_UNAVAILABLE, "WebRTC transport needs signaling and is not implemented yet.")
		_:
			return _fail_start(state, ERR_UNAVAILABLE, "Unsupported transport.")


func _should_fallback_to_client(error: Error) -> bool:
	return error == ERR_ALREADY_IN_USE or error == ERR_CANT_CREATE or error == ERR_CANT_OPEN


func _can_fallback_to_client_after_server_failure(error: Error) -> bool:
	if not _should_fallback_to_client(error):
		return false
	if _has_active_peer():
		return false
	if OS.has_feature("dedicated_server") or OS.has_feature("server"):
		return false
	return true


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
	var old_peer := multiplayer.multiplayer_peer if multiplayer.has_multiplayer_peer() else null
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	if old_peer != null:
		old_peer.close()


func _get_transport_type() -> int:
	return MimicProjectSettings.transport


func _get_transport_name(type: int) -> String:
	match type:
		TransportType.OFFLINE:
			return "Offline"
		TransportType.ENET:
			return "ENet"
		TransportType.WEBSOCKET:
			return "WebSocket"
		TransportType.WEBRTC:
			return "WebRTC"
	return "Unknown"


func _get_bind_address(bind_address_override: String = "") -> String:
	if not bind_address_override.is_empty():
		return bind_address_override
	var bind_address := MimicProjectSettings.bind_address
	return "*" if bind_address.is_empty() else bind_address


func _get_websocket_url(address: String, port: int) -> String:
	if address.begins_with("ws://") or address.begins_with("wss://"):
		return address

	if address.split(":").size() > 2 and not address.begins_with("["):
		address = "[%s]" % address

	var path := MimicProjectSettings.websocket_path.strip_edges()
	if not path.is_empty() and not path.begins_with("/"):
		path = "/" + path

	var scheme := "wss" if MimicProjectSettings.websocket_client_use_tls else "ws"
	return "%s://%s:%d%s" % [scheme, address, port, path]


func _add_port_mapping(port: int) -> void:
	_port_mapper._add_mapping(
		port,
		_get_port_mapping_protocols(),
		_get_port_mapping_description()
	)


func _finish_port_mapping(error: int, external_address: String) -> void:
	if error != UPNP.UPNP_RESULT_SUCCESS:
		MimicLog.warning("UPnP port forwarding failed:", error)
	else:
		MimicLog.log("UPnP port forwarding ready.", external_address)
	port_mapping_finished.emit(error, external_address)


func _delete_port_mappings() -> void:
	_port_mapper._delete_mapping()


func _get_port_mapping_protocols() -> PackedStringArray:
	var protocols := PackedStringArray()
	match MimicProjectSettings.port_mapping_protocol:
		PortMappingProtocol.TRANSPORT_DEFAULT:
			protocols.append("TCP" if _get_transport_type() == TransportType.WEBSOCKET else "UDP")
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
