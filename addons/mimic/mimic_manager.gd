class_name MimicManager extends CanvasLayer

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
enum AutoStartMode { DISABLED, SERVER, CLIENT }
enum NetworkState { OFFLINE, SERVER_LISTENING, CLIENT_CONNECTING, CLIENT_CONNECTED }
enum PortMappingProtocol { TRANSPORT_DEFAULT, TCP, UDP, TCP_AND_UDP }

@export_group("Connection")
@export var address := "127.0.0.1"
@export_range(1, 65535, 1) var port := 8910
@export var bind_address := "*"
@export_range(1, 4095, 1) var max_clients := 32
@export var transport_type: TransportType = TransportType.ENET
@export var replace_existing_peer := true
@export var stop_on_exit := true
@export var refuse_new_connections := false

@export_group("Auto Start")
@export var auto_start_mode: AutoStartMode = AutoStartMode.DISABLED

@export_group("ENet")
@export_range(0, 255, 1) var enet_channel_count := 0
@export_range(0, 2147483647, 1) var enet_in_bandwidth := 0
@export_range(0, 2147483647, 1) var enet_out_bandwidth := 0
@export_range(0, 65535, 1) var enet_client_local_port := 0

@export_group("WebSocket")
@export var websocket_client_use_tls := false
@export var websocket_path := ""
@export_range(0.1, 60.0, 0.1) var websocket_handshake_timeout := 3.0

@export_group("Port Forwarding")
@export var enable_port_forwarding := false
@export var delete_port_mapping_on_stop := true
@export var query_external_address := true
@export var port_mapping_protocol: PortMappingProtocol = PortMappingProtocol.TRANSPORT_DEFAULT
@export_range(0, 86400, 1) var port_mapping_duration := 7200
@export_range(100, 10000, 100) var upnp_discover_timeout_ms := 2000
@export_range(1, 10, 1) var upnp_discover_ttl := 2
@export var upnp_description := "Mimic"

var _state: NetworkState = NetworkState.OFFLINE
var _peer: MultiplayerPeer = null
var _connected_peers := {}
var _upnp_thread: Thread = null
var _mapped_protocols := PackedStringArray()
var _mapped_port := 0
var _external_address := ""
var _last_client_address := ""
var _last_client_port := 0


func _ready() -> void:
	_connect_multiplayer_signals()
	_run_auto_start.call_deferred()


func _exit_tree() -> void:
	if stop_on_exit:
		stop()
	elif _upnp_thread != null:
		_upnp_thread.wait_to_finish()
		_upnp_thread = null


func host() -> Error:
	return start_server()


func join(address_override: String = "", port_override: int = -1) -> Error:
	return start_client(address_override, port_override)


func start_server() -> Error:
	return _start_server()


func start_client(address_override: String = "", port_override: int = -1) -> Error:
	_connect_multiplayer_signals()
	var connect_address := address_override.strip_edges() if not address_override.is_empty() else address.strip_edges()
	var connect_port := port_override if port_override > 0 else port
	if connect_address.is_empty():
		return _fail_start(NetworkState.CLIENT_CONNECTING, ERR_INVALID_PARAMETER, "Client address is empty.")

	var error := _validate_start(NetworkState.CLIENT_CONNECTING, connect_port)
	if error != OK:
		return error
	var api := _get_multiplayer_api()

	var peer: MultiplayerPeer = null
	match transport_type:
		TransportType.ENET:
			var enet_peer := ENetMultiplayerPeer.new()
			error = enet_peer.create_client(connect_address, connect_port, enet_channel_count, enet_in_bandwidth, enet_out_bandwidth, enet_client_local_port)
			peer = enet_peer
		TransportType.WEBSOCKET:
			var websocket_peer := WebSocketMultiplayerPeer.new()
			websocket_peer.handshake_timeout = websocket_handshake_timeout
			error = websocket_peer.create_client(_get_websocket_url(connect_address, connect_port))
			peer = websocket_peer
		TransportType.OFFLINE, TransportType.WEBRTC:
			return _fail_unavailable_transport(NetworkState.CLIENT_CONNECTING)
		_:
			return _fail_start(NetworkState.CLIENT_CONNECTING, ERR_UNAVAILABLE, "Unsupported transport.")

	if error != OK:
		peer.close()
		return _fail_start(NetworkState.CLIENT_CONNECTING, error, "Unable to start client: %s." % error_string(error))

	_last_client_address = connect_address
	_last_client_port = connect_port
	_peer = peer
	api.multiplayer_peer = peer
	_change_state(NetworkState.CLIENT_CONNECTING)
	client_started.emit(connect_address, connect_port)
	return OK


func stop() -> void:
	_finish_port_forwarding_thread(false)
	_delete_port_mappings()
	_close_peer()
	_connected_peers.clear()
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
	var api := _get_multiplayer_api()
	if _state == NetworkState.OFFLINE or api == null or not api.has_multiplayer_peer():
		return 0
	if api.multiplayer_peer is OfflineMultiplayerPeer:
		return 0
	return api.get_unique_id()


func get_peer_ids() -> PackedInt32Array:
	var api := _get_multiplayer_api()
	if _state == NetworkState.OFFLINE or api == null or not api.has_multiplayer_peer():
		return PackedInt32Array()
	return api.get_peers()


func is_server() -> bool:
	return _state == NetworkState.SERVER_LISTENING


func is_client() -> bool:
	return _state == NetworkState.CLIENT_CONNECTED


func is_connecting() -> bool:
	return _state == NetworkState.CLIENT_CONNECTING


func is_offline() -> bool:
	return _state == NetworkState.OFFLINE


func _start_server() -> Error:
	_connect_multiplayer_signals()
	var error := _validate_start(NetworkState.SERVER_LISTENING, port)
	if error != OK:
		return error
	var api := _get_multiplayer_api()

	var peer: MultiplayerPeer = null
	match transport_type:
		TransportType.ENET:
			var enet_peer := ENetMultiplayerPeer.new()
			if not bind_address.is_empty() and bind_address != "*":
				enet_peer.set_bind_ip(bind_address)
			error = enet_peer.create_server(port, max_clients, enet_channel_count, enet_in_bandwidth, enet_out_bandwidth)
			peer = enet_peer
		TransportType.WEBSOCKET:
			var websocket_peer := WebSocketMultiplayerPeer.new()
			websocket_peer.handshake_timeout = websocket_handshake_timeout
			error = websocket_peer.create_server(port, _get_bind_address())
			peer = websocket_peer
		TransportType.OFFLINE, TransportType.WEBRTC:
			return _fail_unavailable_transport(NetworkState.SERVER_LISTENING)
		_:
			return _fail_start(NetworkState.SERVER_LISTENING, ERR_UNAVAILABLE, "Unsupported transport.")

	if error != OK:
		peer.close()
		return _fail_start(NetworkState.SERVER_LISTENING, error, "Unable to start server: %s." % error_string(error))

	_peer = peer
	_peer.refuse_new_connections = refuse_new_connections
	api.multiplayer_peer = peer
	_connected_peers.clear()
	_change_state(NetworkState.SERVER_LISTENING)
	_start_port_forwarding()
	server_started.emit(port)

	return OK


func _validate_start(state: NetworkState, target_port: int) -> Error:
	if _get_multiplayer_api() == null:
		return _fail_start(state, ERR_UNCONFIGURED, "MimicManager must be inside the scene tree before starting.")

	if target_port < 1 or target_port > 65535:
		return _fail_start(state, ERR_PARAMETER_RANGE_ERROR, "Port must be between 1 and 65535.")

	if transport_type == TransportType.ENET and OS.has_feature("web"):
		return _fail_start(state, ERR_UNAVAILABLE, "ENet is not available on web exports. Use WebSocket instead.")

	if transport_type == TransportType.OFFLINE or transport_type == TransportType.WEBRTC:
		return _fail_unavailable_transport(state)

	if _has_active_peer():
		if not replace_existing_peer:
			return _fail_start(state, ERR_ALREADY_IN_USE, "A multiplayer peer is already active.")
		stop()

	return OK


func _connect_multiplayer_signals() -> void:
	var api := _get_multiplayer_api()
	if api == null:
		return

	if not api.peer_connected.is_connected(_on_peer_connected):
		api.peer_connected.connect(_on_peer_connected)
	if not api.peer_disconnected.is_connected(_on_peer_disconnected):
		api.peer_disconnected.connect(_on_peer_disconnected)
	if not api.connected_to_server.is_connected(_on_connected_to_server):
		api.connected_to_server.connect(_on_connected_to_server)
	if not api.connection_failed.is_connected(_on_connection_failed):
		api.connection_failed.connect(_on_connection_failed)
	if not api.server_disconnected.is_connected(_on_server_disconnected):
		api.server_disconnected.connect(_on_server_disconnected)


func _run_auto_start() -> void:
	if not is_inside_tree():
		return

	match auto_start_mode:
		AutoStartMode.SERVER:
			start_server()
		AutoStartMode.CLIENT:
			start_client()


func _on_peer_connected(peer_id: int) -> void:
	_connected_peers[peer_id] = true
	peer_connected.emit(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	_connected_peers.erase(peer_id)
	peer_disconnected.emit(peer_id)


func _on_connected_to_server() -> void:
	_change_state(NetworkState.CLIENT_CONNECTED)
	client_connected.emit()


func _on_connection_failed() -> void:
	var message := "Unable to connect to %s:%d." % [_last_client_address, _last_client_port]
	_close_peer()
	_connected_peers.clear()
	_change_state(NetworkState.OFFLINE)
	client_connection_failed.emit(message)


func _on_server_disconnected() -> void:
	_close_peer()
	_connected_peers.clear()
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
	match transport_type:
		TransportType.OFFLINE:
			return _fail_start(state, ERR_UNAVAILABLE, "Offline transport cannot start network connections.")
		TransportType.WEBRTC:
			return _fail_start(state, ERR_UNAVAILABLE, "WebRTC transport needs signaling and is not implemented in MimicManager yet.")
		_:
			return _fail_start(state, ERR_UNAVAILABLE, "Unsupported transport.")


func _has_active_peer() -> bool:
	if _state != NetworkState.OFFLINE:
		return true

	var api := _get_multiplayer_api()
	if api == null or not api.has_multiplayer_peer():
		return false

	var current_peer := api.multiplayer_peer
	if current_peer == null or current_peer is OfflineMultiplayerPeer:
		return false

	return current_peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED


func _close_peer() -> void:
	var api := _get_multiplayer_api()
	var old_peer := api.multiplayer_peer if api != null and api.has_multiplayer_peer() else _peer
	if api != null:
		api.multiplayer_peer = OfflineMultiplayerPeer.new()
	if old_peer != null:
		old_peer.close()
	_peer = null


func _get_multiplayer_api() -> MultiplayerAPI:
	if not is_inside_tree():
		return null

	return multiplayer


func _get_websocket_url(connect_address: String, connect_port: int) -> String:
	if connect_address.begins_with("ws://") or connect_address.begins_with("wss://"):
		return connect_address

	if connect_address.split(":").size() > 2 and not connect_address.begins_with("["):
		connect_address = "[%s]" % connect_address

	var path := websocket_path.strip_edges()
	if not path.is_empty() and not path.begins_with("/"):
		path = "/" + path

	var scheme := "wss" if websocket_client_use_tls else "ws"
	return "%s://%s:%d%s" % [scheme, connect_address, connect_port, path]


func _get_bind_address() -> String:
	return "*" if bind_address.is_empty() else bind_address


func _start_port_forwarding() -> void:
	if not enable_port_forwarding:
		return

	if _upnp_thread != null:
		return

	var protocols := _get_port_mapping_protocols()
	_upnp_thread = Thread.new()
	var config := {
		"port": port,
		"protocols": protocols,
		"description": upnp_description,
		"duration": port_mapping_duration,
		"timeout": upnp_discover_timeout_ms,
		"ttl": upnp_discover_ttl,
		"query_external_address": query_external_address,
	}
	var error := _upnp_thread.start(_run_port_forwarding.bind(config))
	if error != OK:
		_upnp_thread = null
		push_warning("Unable to start UPnP thread: %s." % error_string(error))
		port_mapping_finished.emit(UPNP.UPNP_RESULT_UNKNOWN_ERROR, "")


func _run_port_forwarding(config: Dictionary) -> Dictionary:
	var result := {
		"error": UPNP.UPNP_RESULT_UNKNOWN_ERROR,
		"external_address": "",
		"port": 0,
		"protocols": PackedStringArray(),
	}
	var target_port := int(config.get("port", 0))
	var protocols: PackedStringArray = config.get("protocols", PackedStringArray())
	var upnp := UPNP.new()
	var discover_error := upnp.discover(int(config.get("timeout", 2000)), int(config.get("ttl", 2)))
	if discover_error != UPNP.UPNP_RESULT_SUCCESS:
		result["error"] = discover_error
		call_deferred("_finish_port_forwarding")
		return result

	var gateway := upnp.get_gateway()
	if gateway == null or not gateway.is_valid_gateway():
		result["error"] = UPNP.UPNP_RESULT_NO_GATEWAY
		call_deferred("_finish_port_forwarding")
		return result

	var mapped_protocols := PackedStringArray()
	for protocol in protocols:
		var mapping_error := upnp.add_port_mapping(target_port, target_port, String(config.get("description", "")), protocol, int(config.get("duration", 0)))
		if mapping_error != UPNP.UPNP_RESULT_SUCCESS:
			for mapped_protocol in mapped_protocols:
				upnp.delete_port_mapping(target_port, mapped_protocol)
			result["error"] = mapping_error
			call_deferred("_finish_port_forwarding")
			return result
		mapped_protocols.append(protocol)

	result["error"] = UPNP.UPNP_RESULT_SUCCESS
	result["port"] = target_port
	result["protocols"] = mapped_protocols
	if bool(config.get("query_external_address", true)):
		result["external_address"] = upnp.query_external_address()

	call_deferred("_finish_port_forwarding")
	return result


func _finish_port_forwarding() -> void:
	_finish_port_forwarding_thread(true)


func _finish_port_forwarding_thread(should_emit: bool) -> void:
	if _upnp_thread == null:
		return

	var result: Dictionary = _upnp_thread.wait_to_finish()
	_upnp_thread = null
	var error := int(result.get("error", UPNP.UPNP_RESULT_UNKNOWN_ERROR))
	_external_address = String(result.get("external_address", ""))
	_mapped_protocols = result.get("protocols", PackedStringArray())
	_mapped_port = int(result.get("port", 0)) if not _mapped_protocols.is_empty() else 0

	if should_emit:
		port_mapping_finished.emit(error, _external_address)

	if should_emit and error != UPNP.UPNP_RESULT_SUCCESS:
		var message := "UPnP port forwarding failed: %s." % str(error)
		push_warning(message)


func _delete_port_mappings() -> void:
	if not delete_port_mapping_on_stop or _mapped_protocols.is_empty():
		return

	var upnp := UPNP.new()
	var discover_error := upnp.discover(upnp_discover_timeout_ms, upnp_discover_ttl)
	if discover_error != UPNP.UPNP_RESULT_SUCCESS:
		push_warning("UPnP discovery failed while deleting port mapping: %s." % str(discover_error))
		return

	for protocol in _mapped_protocols:
		upnp.delete_port_mapping(_mapped_port, protocol)

	_mapped_protocols.clear()
	_mapped_port = 0


func _get_port_mapping_protocols() -> PackedStringArray:
	var protocols := PackedStringArray()
	match port_mapping_protocol:
		PortMappingProtocol.TRANSPORT_DEFAULT:
			protocols.append("TCP" if transport_type == TransportType.WEBSOCKET else "UDP")
		PortMappingProtocol.TCP:
			protocols.append("TCP")
		PortMappingProtocol.UDP:
			protocols.append("UDP")
		PortMappingProtocol.TCP_AND_UDP:
			protocols.append("TCP")
			protocols.append("UDP")
		_:
			push_warning("Unsupported port mapping protocol.")
	return protocols
