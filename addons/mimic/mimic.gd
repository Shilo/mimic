extends Node

signal state_changed(state: int, previous_state: int)
signal start_failed(attempted_state: int, error: int, message: String)
signal server_started(port: int)
signal client_started(address: String, port: int)
signal client_connected()
signal client_connection_failed(message: String)
signal server_disconnected()
signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)
signal stopped()
signal port_mapping_finished(result: int, external_address: String)

enum TransportType { OFFLINE, ENET, WEBSOCKET, WEBRTC }
enum NetworkState { OFFLINE, SERVER_LISTENING, CLIENT_CONNECTING, CLIENT_CONNECTED }
enum PortMappingProtocol { TRANSPORT_DEFAULT, TCP, UDP, TCP_AND_UDP }

const Settings := preload("res://addons/mimic/internal/mimic_project_settings.gd")

var _state: NetworkState = NetworkState.OFFLINE
var _mapped_port := 0
var _mapped_protocols := PackedStringArray()
var _external_address := ""
var _last_client_address := ""
var _last_client_port := 0


func _ready() -> void:
	_connect_multiplayer_signals()


func start_server(port_override: int = -1, bind_address_override: String = "") -> Error:
	return _start_server(port_override, bind_address_override)


func start_client(address_override: String = "", port_override: int = -1) -> Error:
	_connect_multiplayer_signals()

	var address := address_override.strip_edges() if not address_override.is_empty() else Settings.get_string(Settings.SETTING_ADDRESS, Settings.DEFAULT_ADDRESS).strip_edges()
	var port := port_override if port_override > 0 else Settings.get_int(Settings.SETTING_PORT, Settings.DEFAULT_PORT)
	if address.is_empty():
		return _fail_start(NetworkState.CLIENT_CONNECTING, ERR_INVALID_PARAMETER, "Client address is empty.")

	var error := _validate_start(NetworkState.CLIENT_CONNECTING, port)
	if error != OK:
		return error

	var peer: MultiplayerPeer = null
	match _get_transport_type():
		TransportType.ENET:
			var enet_peer := ENetMultiplayerPeer.new()
			var bind_address := Settings.get_string(Settings.SETTING_BIND_ADDRESS, Settings.DEFAULT_BIND_ADDRESS)
			if not bind_address.is_empty() and bind_address != "*":
				enet_peer.set_bind_ip(bind_address)
			error = enet_peer.create_client(
				address,
				port,
				Settings.get_int(Settings.SETTING_ENET_CHANNEL_COUNT, Settings.DEFAULT_ENET_CHANNEL_COUNT),
				Settings.get_int(Settings.SETTING_ENET_IN_BANDWIDTH, Settings.DEFAULT_ENET_IN_BANDWIDTH),
				Settings.get_int(Settings.SETTING_ENET_OUT_BANDWIDTH, Settings.DEFAULT_ENET_OUT_BANDWIDTH),
				Settings.get_int(Settings.SETTING_ENET_CLIENT_LOCAL_PORT, Settings.DEFAULT_ENET_CLIENT_LOCAL_PORT)
			)
			peer = enet_peer
		TransportType.WEBSOCKET:
			var websocket_peer := WebSocketMultiplayerPeer.new()
			websocket_peer.handshake_timeout = Settings.get_float(Settings.SETTING_WEBSOCKET_HANDSHAKE_TIMEOUT, Settings.DEFAULT_WEBSOCKET_HANDSHAKE_TIMEOUT)
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
	client_started.emit(address, port)
	return OK


func start_server_if_first_else_client() -> Error:
	var server_error := _start_server(-1, "", true)
	if server_error == OK:
		return OK
	if not _can_fallback_to_client_after_server_failure(server_error):
		return server_error

	return start_client()


func stop() -> void:
	_delete_port_mappings()
	_close_peer()
	_last_client_address = ""
	_last_client_port = 0
	_change_state(NetworkState.OFFLINE)
	stopped.emit()


func cancel_connection() -> void:
	if _state == NetworkState.CLIENT_CONNECTING:
		stop()


func get_state() -> int:
	return _state


func get_external_address() -> String:
	return _external_address


func get_local_peer_id() -> int:
	if _state == NetworkState.OFFLINE or _state == NetworkState.CLIENT_CONNECTING:
		return 0
	if not multiplayer.has_multiplayer_peer():
		return 0
	return multiplayer.get_unique_id()


func get_peer_ids() -> PackedInt32Array:
	if _state == NetworkState.OFFLINE or not multiplayer.has_multiplayer_peer():
		return PackedInt32Array()
	return multiplayer.get_peers()


func is_server() -> bool:
	return _state == NetworkState.SERVER_LISTENING


func is_client() -> bool:
	return _state == NetworkState.CLIENT_CONNECTED


func is_connecting() -> bool:
	return _state == NetworkState.CLIENT_CONNECTING


func is_offline() -> bool:
	return _state == NetworkState.OFFLINE


func _start_server(port_override: int = -1, bind_address_override: String = "", quiet_expected_failure: bool = false) -> Error:
	_connect_multiplayer_signals()

	var port := port_override if port_override > 0 else Settings.get_int(Settings.SETTING_PORT, Settings.DEFAULT_PORT)
	var error := _validate_start(NetworkState.SERVER_LISTENING, port)
	if error != OK:
		return error

	var peer: MultiplayerPeer = null
	match _get_transport_type():
		TransportType.ENET:
			var enet_peer := ENetMultiplayerPeer.new()
			var bind_address := _get_bind_address(bind_address_override)
			if not bind_address.is_empty() and bind_address != "*":
				enet_peer.set_bind_ip(bind_address)
			error = enet_peer.create_server(
				port,
				Settings.get_int(Settings.SETTING_MAX_CLIENTS, Settings.DEFAULT_MAX_CLIENTS),
				Settings.get_int(Settings.SETTING_ENET_CHANNEL_COUNT, Settings.DEFAULT_ENET_CHANNEL_COUNT),
				Settings.get_int(Settings.SETTING_ENET_IN_BANDWIDTH, Settings.DEFAULT_ENET_IN_BANDWIDTH),
				Settings.get_int(Settings.SETTING_ENET_OUT_BANDWIDTH, Settings.DEFAULT_ENET_OUT_BANDWIDTH)
			)
			peer = enet_peer
		TransportType.WEBSOCKET:
			var websocket_peer := WebSocketMultiplayerPeer.new()
			websocket_peer.handshake_timeout = Settings.get_float(Settings.SETTING_WEBSOCKET_HANDSHAKE_TIMEOUT, Settings.DEFAULT_WEBSOCKET_HANDSHAKE_TIMEOUT)
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

	peer.refuse_new_connections = Settings.get_bool(Settings.SETTING_REFUSE_NEW_CONNECTIONS, Settings.DEFAULT_REFUSE_NEW_CONNECTIONS)
	multiplayer.multiplayer_peer = peer
	_change_state(NetworkState.SERVER_LISTENING)
	_add_port_mapping(port)
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
		if not Settings.get_bool(Settings.SETTING_REPLACE_EXISTING_PEER, Settings.DEFAULT_REPLACE_EXISTING_PEER):
			return _fail_start(state, ERR_ALREADY_IN_USE, "A multiplayer peer is already active.")
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
	peer_connected.emit(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	peer_disconnected.emit(peer_id)


func _on_connected_to_server() -> void:
	_change_state(NetworkState.CLIENT_CONNECTED)
	client_connected.emit()


func _on_connection_failed() -> void:
	var message := "Unable to connect to %s:%d." % [_last_client_address, _last_client_port]
	_close_peer()
	_change_state(NetworkState.OFFLINE)
	client_connection_failed.emit(message)


func _on_server_disconnected() -> void:
	_close_peer()
	_change_state(NetworkState.OFFLINE)
	server_disconnected.emit()


func _change_state(state: NetworkState) -> void:
	if _state == state:
		return

	var previous_state := _state
	_state = state
	state_changed.emit(_state, previous_state)


func _fail_start(state: NetworkState, error: int, message: String) -> Error:
	push_warning(message)
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
	return Settings.get_int(Settings.SETTING_TRANSPORT_TYPE, Settings.DEFAULT_TRANSPORT_TYPE)


func _get_bind_address(bind_address_override: String = "") -> String:
	if not bind_address_override.is_empty():
		return bind_address_override
	var bind_address := Settings.get_string(Settings.SETTING_BIND_ADDRESS, Settings.DEFAULT_BIND_ADDRESS)
	return "*" if bind_address.is_empty() else bind_address


func _get_websocket_url(address: String, port: int) -> String:
	if address.begins_with("ws://") or address.begins_with("wss://"):
		return address

	if address.split(":").size() > 2 and not address.begins_with("["):
		address = "[%s]" % address

	var path := Settings.get_string(Settings.SETTING_WEBSOCKET_PATH, Settings.DEFAULT_WEBSOCKET_PATH).strip_edges()
	if not path.is_empty() and not path.begins_with("/"):
		path = "/" + path

	var scheme := "wss" if Settings.get_bool(Settings.SETTING_WEBSOCKET_CLIENT_USE_TLS, Settings.DEFAULT_WEBSOCKET_CLIENT_USE_TLS) else "ws"
	return "%s://%s:%d%s" % [scheme, address, port, path]


func _add_port_mapping(port: int) -> void:
	_external_address = ""
	_mapped_port = 0
	_mapped_protocols.clear()

	if not Settings.get_bool(Settings.SETTING_PORT_FORWARDING_ENABLED, Settings.DEFAULT_PORT_FORWARDING_ENABLED):
		return

	var upnp := UPNP.new()
	var discover_error := upnp.discover(
		Settings.get_int(Settings.SETTING_UPNP_DISCOVER_TIMEOUT_MS, Settings.DEFAULT_UPNP_DISCOVER_TIMEOUT_MS),
		Settings.get_int(Settings.SETTING_UPNP_DISCOVER_TTL, Settings.DEFAULT_UPNP_DISCOVER_TTL)
	)
	if discover_error != UPNP.UPNP_RESULT_SUCCESS:
		_finish_port_mapping(discover_error, "")
		return

	var gateway := upnp.get_gateway()
	if gateway == null or not gateway.is_valid_gateway():
		_finish_port_mapping(UPNP.UPNP_RESULT_NO_GATEWAY, "")
		return

	for protocol in _get_port_mapping_protocols():
		var mapping_error := upnp.add_port_mapping(
			port,
			port,
			Settings.get_string(Settings.SETTING_UPNP_DESCRIPTION, Settings.DEFAULT_UPNP_DESCRIPTION),
			protocol,
			Settings.get_int(Settings.SETTING_PORT_MAPPING_DURATION, Settings.DEFAULT_PORT_MAPPING_DURATION)
		)
		if mapping_error != UPNP.UPNP_RESULT_SUCCESS:
			for mapped_protocol in _mapped_protocols:
				upnp.delete_port_mapping(port, mapped_protocol)
			_mapped_protocols.clear()
			_finish_port_mapping(mapping_error, "")
			return

		_mapped_protocols.append(protocol)

	_mapped_port = port
	if Settings.get_bool(Settings.SETTING_PORT_MAPPING_QUERY_EXTERNAL_ADDRESS, Settings.DEFAULT_PORT_MAPPING_QUERY_EXTERNAL_ADDRESS):
		_external_address = upnp.query_external_address()

	_finish_port_mapping(UPNP.UPNP_RESULT_SUCCESS, _external_address)


func _finish_port_mapping(error: int, external_address: String) -> void:
	if error != UPNP.UPNP_RESULT_SUCCESS:
		push_warning("UPnP port forwarding failed: %s." % str(error))
	port_mapping_finished.emit(error, external_address)


func _delete_port_mappings() -> void:
	if not Settings.get_bool(Settings.SETTING_PORT_MAPPING_DELETE_ON_STOP, Settings.DEFAULT_PORT_MAPPING_DELETE_ON_STOP):
		return
	if _mapped_port <= 0 or _mapped_protocols.is_empty():
		return

	var upnp := UPNP.new()
	var discover_error := upnp.discover(
		Settings.get_int(Settings.SETTING_UPNP_DISCOVER_TIMEOUT_MS, Settings.DEFAULT_UPNP_DISCOVER_TIMEOUT_MS),
		Settings.get_int(Settings.SETTING_UPNP_DISCOVER_TTL, Settings.DEFAULT_UPNP_DISCOVER_TTL)
	)
	if discover_error == UPNP.UPNP_RESULT_SUCCESS:
		for protocol in _mapped_protocols:
			upnp.delete_port_mapping(_mapped_port, protocol)

	_mapped_port = 0
	_mapped_protocols.clear()
	_external_address = ""


func _get_port_mapping_protocols() -> PackedStringArray:
	var protocols := PackedStringArray()
	match Settings.get_int(Settings.SETTING_PORT_MAPPING_PROTOCOL, Settings.DEFAULT_PORT_MAPPING_PROTOCOL):
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
