extends GutTest

const MIMIC_SCRIPT := preload("res://addons/mimic/mimic.gd")

const TRANSPORT := "mimic_multiplayer/connection/transport"
const EDITOR_AUTO_CONNECT := "mimic_multiplayer/connection/editor_auto_connect"
const ADDRESS := "mimic_multiplayer/connection/address"
const PORT := "mimic_multiplayer/connection/port"
const MAX_CLIENTS := "mimic_multiplayer/connection/max_clients"
const BIND_ADDRESS := "mimic_multiplayer/connection/bind_address"
const ENET_CHANNEL_COUNT := "mimic_multiplayer/enet/channel_count"
const ENET_IN_BANDWIDTH := "mimic_multiplayer/enet/in_bandwidth"
const ENET_OUT_BANDWIDTH := "mimic_multiplayer/enet/out_bandwidth"
const ENET_CLIENT_LOCAL_PORT := "mimic_multiplayer/enet/client_local_port"
const WEBSOCKET_CLIENT_USE_TLS := "mimic_multiplayer/websocket/client_use_tls"
const WEBSOCKET_PATH := "mimic_multiplayer/websocket/path"
const WEBSOCKET_HANDSHAKE_TIMEOUT := "mimic_multiplayer/websocket/handshake_timeout"
const PORT_FORWARDING_ENABLED := "mimic_multiplayer/port_forwarding/enabled"
const PORT_MAPPING_DELETE_ON_STOP := "mimic_multiplayer/port_forwarding/delete_mapping_on_stop"
const PORT_MAPPING_QUERY_EXTERNAL_ADDRESS := (
	"mimic_multiplayer/port_forwarding/query_external_address"
)
const PORT_MAPPING_PROTOCOL := "mimic_multiplayer/port_forwarding/protocol"
const PORT_MAPPING_DURATION := "mimic_multiplayer/port_forwarding/duration"
const UPNP_DISCOVER_TIMEOUT_MS := "mimic_multiplayer/port_forwarding/discover_timeout_ms"
const UPNP_DISCOVER_TTL := "mimic_multiplayer/port_forwarding/discover_ttl"
const LOG_LEVEL := "mimic_multiplayer/debug/log_level"
const SETTING_NAMES := [
	TRANSPORT,
	EDITOR_AUTO_CONNECT,
	ADDRESS,
	PORT,
	MAX_CLIENTS,
	BIND_ADDRESS,
	ENET_CHANNEL_COUNT,
	ENET_IN_BANDWIDTH,
	ENET_OUT_BANDWIDTH,
	ENET_CLIENT_LOCAL_PORT,
	WEBSOCKET_CLIENT_USE_TLS,
	WEBSOCKET_PATH,
	WEBSOCKET_HANDSHAKE_TIMEOUT,
	PORT_FORWARDING_ENABLED,
	PORT_MAPPING_DELETE_ON_STOP,
	PORT_MAPPING_QUERY_EXTERNAL_ADDRESS,
	PORT_MAPPING_PROTOCOL,
	PORT_MAPPING_DURATION,
	UPNP_DISCOVER_TIMEOUT_MS,
	UPNP_DISCOVER_TTL,
	LOG_LEVEL,
]

var _saved_settings := {}
var _saved_multiplayer_poll := true
var _custom_multiplayer_roots: Array[Node] = []
var _next_port := 19_200


func before_each() -> void:
	Mimic.stop()
	_save_settings()
	_saved_multiplayer_poll = get_tree().is_multiplayer_poll_enabled()
	get_tree().set_multiplayer_poll_enabled(true)
	_custom_multiplayer_roots.clear()
	_configure_transport(Mimic.TransportType.ENET, _next_test_port())
	_replace_mimic_port_mapper(MimicPortMapper.new())


func after_each() -> void:
	for root in _custom_multiplayer_roots:
		if is_instance_valid(root):
			get_tree().set_multiplayer(null, root.get_path())
			root.free()
	_custom_multiplayer_roots.clear()

	Mimic.stop()
	_replace_mimic_port_mapper(MimicPortMapper.new())
	_restore_settings()
	get_tree().set_multiplayer_poll_enabled(_saved_multiplayer_poll)


func test_enet_host_and_client_connect_between_mimic_instances() -> void:
	await _assert_transport_connects(Mimic.TransportType.ENET)


func test_websocket_host_and_client_connect_between_mimic_instances() -> void:
	await _assert_transport_connects(Mimic.TransportType.WEBSOCKET)


func test_enet_client_connection_can_be_canceled_before_handshake_finishes() -> void:
	await _assert_client_connection_can_be_canceled(Mimic.TransportType.ENET)


func test_websocket_client_connection_can_be_canceled_before_handshake_finishes() -> void:
	await _assert_client_connection_can_be_canceled(Mimic.TransportType.WEBSOCKET)


func test_enet_server_then_client_preflight_allows_available_port() -> void:
	var port := _next_test_port()
	_configure_transport(Mimic.TransportType.ENET, port)
	ProjectSettings.set_setting(BIND_ADDRESS, "127.0.0.1")

	assert_eq(Mimic._get_server_or_client_preflight_error(), OK)


func test_enet_server_then_client_preflights_occupied_server_port() -> void:
	var port := _next_test_port()
	_configure_transport(Mimic.TransportType.ENET, port)
	ProjectSettings.set_setting(BIND_ADDRESS, "127.0.0.1")
	var occupying_peer := PacketPeerUDP.new()
	assert_eq(occupying_peer.bind(port, "127.0.0.1"), OK)
	watch_signals(Mimic)

	assert_eq(Mimic._get_server_or_client_preflight_error(), ERR_CANT_CREATE)
	var start_error := Mimic.start_server_or_client()
	occupying_peer.close()

	assert_eq(start_error, OK)
	assert_true(Mimic.is_connecting())
	assert_signal_not_emitted(Mimic, "server_started")
	assert_signal_not_emitted(Mimic, "start_failed")
	assert_signal_emitted_with_parameters(Mimic, "client_started", ["127.0.0.1", port])
	Mimic.cancel_connection()
	await wait_process_frames(2)


func test_server_then_client_preflight_skips_websocket_transport() -> void:
	_configure_transport(Mimic.TransportType.WEBSOCKET, _next_test_port())

	assert_eq(Mimic._get_server_or_client_preflight_error(), OK)


func test_cancel_connection_is_noop_unless_client_is_connecting() -> void:
	watch_signals(Mimic)
	var port := _next_test_port()

	assert_eq(Mimic.start_server(port, "127.0.0.1"), OK)
	Mimic.cancel_connection()

	assert_true(Mimic.is_server())
	assert_signal_not_emitted(Mimic, "stopped")


func test_enet_server_requests_udp_port_mapping_when_enabled() -> void:
	var fake := _install_fake_port_mapper()
	ProjectSettings.set_setting(PORT_FORWARDING_ENABLED, true)
	ProjectSettings.set_setting(PORT_MAPPING_PROTOCOL, Mimic.PortMappingProtocol.TRANSPORT_DEFAULT)
	ProjectSettings.set_setting(TRANSPORT, Mimic.TransportType.ENET)
	var port := _next_test_port()

	assert_eq(Mimic.start_server(port, "127.0.0.1"), OK)

	assert_eq(fake.add_requests.size(), 1)
	assert_eq(fake.add_requests[0]["port"], port)
	assert_eq(_protocols_to_array(fake.add_requests[0]["protocols"]), ["UDP"])


func test_websocket_server_requests_tcp_port_mapping_when_enabled() -> void:
	var fake := _install_fake_port_mapper()
	ProjectSettings.set_setting(PORT_FORWARDING_ENABLED, true)
	ProjectSettings.set_setting(PORT_MAPPING_PROTOCOL, Mimic.PortMappingProtocol.TRANSPORT_DEFAULT)
	ProjectSettings.set_setting(TRANSPORT, Mimic.TransportType.WEBSOCKET)
	var port := _next_test_port()

	assert_eq(Mimic.start_server(port, "127.0.0.1"), OK)

	assert_eq(fake.add_requests.size(), 1)
	assert_eq(fake.add_requests[0]["port"], port)
	assert_eq(_protocols_to_array(fake.add_requests[0]["protocols"]), ["TCP"])


func test_port_mapping_protocol_override_can_map_tcp_and_udp() -> void:
	var fake := _install_fake_port_mapper()
	ProjectSettings.set_setting(PORT_FORWARDING_ENABLED, true)
	ProjectSettings.set_setting(PORT_MAPPING_PROTOCOL, Mimic.PortMappingProtocol.TCP_AND_UDP)
	var port := _next_test_port()

	assert_eq(Mimic.start_server(port, "127.0.0.1"), OK)

	assert_eq(fake.add_requests.size(), 1)
	assert_eq(_protocols_to_array(fake.add_requests[0]["protocols"]), ["TCP", "UDP"])


func test_stopping_server_requests_port_mapping_delete() -> void:
	var fake := _install_fake_port_mapper()
	ProjectSettings.set_setting(PORT_FORWARDING_ENABLED, true)
	ProjectSettings.set_setting(PORT_MAPPING_DELETE_ON_STOP, true)

	assert_eq(Mimic.start_server(_next_test_port(), "127.0.0.1"), OK)
	Mimic.stop()

	assert_eq(fake.delete_count, 1)
	assert_true(Mimic.is_offline())


func test_restart_server_deletes_previous_port_mapping_before_new_mapping() -> void:
	var fake := _install_fake_port_mapper()
	ProjectSettings.set_setting(PORT_FORWARDING_ENABLED, true)
	ProjectSettings.set_setting(PORT_MAPPING_DELETE_ON_STOP, true)
	var first_port := _next_test_port()
	var second_port := _next_test_port()

	assert_eq(Mimic.start_server(first_port, "127.0.0.1"), OK)
	assert_eq(Mimic.start_server(second_port, "127.0.0.1"), OK)

	assert_eq(fake.delete_count, 1)
	assert_eq(fake.add_requests.size(), 2)
	assert_eq(fake.add_requests[0]["port"], first_port)
	assert_eq(fake.add_requests[1]["port"], second_port)


func test_stop_does_not_delete_port_mapping_when_delete_on_stop_is_disabled() -> void:
	var fake := _install_fake_port_mapper()
	ProjectSettings.set_setting(PORT_FORWARDING_ENABLED, true)
	ProjectSettings.set_setting(PORT_MAPPING_DELETE_ON_STOP, false)

	assert_eq(Mimic.start_server(_next_test_port(), "127.0.0.1"), OK)
	Mimic.stop()

	assert_eq(fake.delete_count, 0)
	assert_true(Mimic.is_offline())


func test_port_mapping_finished_reemits_result_for_ui_and_status() -> void:
	var fake := _install_fake_port_mapper()
	fake.emit_on_add = true
	fake.next_external_address = "203.0.113.8"
	ProjectSettings.set_setting(PORT_FORWARDING_ENABLED, true)
	watch_signals(Mimic)

	assert_eq(Mimic.start_server(_next_test_port(), "127.0.0.1"), OK)

	assert_eq(Mimic.get_external_address(), "203.0.113.8")
	assert_signal_emitted_with_parameters(
		Mimic,
		"port_mapping_finished",
		[UPNP.UPNP_RESULT_SUCCESS, "203.0.113.8"]
	)


func test_websocket_url_builder_adds_scheme_port_path_and_ipv6_brackets() -> void:
	ProjectSettings.set_setting(WEBSOCKET_CLIENT_USE_TLS, true)
	ProjectSettings.set_setting(WEBSOCKET_PATH, "mimic")

	assert_eq(Mimic._get_websocket_url("example.test", 443), "wss://example.test:443/mimic")
	assert_eq(Mimic._get_websocket_url("2001:db8::1", 443), "wss://[2001:db8::1]:443/mimic")


func test_websocket_url_builder_preserves_explicit_websocket_url() -> void:
	ProjectSettings.set_setting(WEBSOCKET_CLIENT_USE_TLS, true)
	ProjectSettings.set_setting(WEBSOCKET_PATH, "ignored")

	assert_eq(
		Mimic._get_websocket_url("ws://example.test:19000/custom", 19_000),
		"ws://example.test:19000/custom"
	)


func _assert_transport_connects(transport: int) -> void:
	var port := _next_test_port()
	_configure_transport(transport, port)
	var host := _create_mimic_instance("Host")
	var client := _create_mimic_instance("Client")
	watch_signals(host)
	watch_signals(client)

	assert_eq(host.start_server(port, "127.0.0.1"), OK)
	assert_eq(client.start_client("127.0.0.1", port), OK)
	var connected: bool = await wait_until(
		func() -> bool:
			return host.get_peer_ids().size() == 1 and client.is_client(),
		5.0
	)

	assert_true(connected)
	assert_eq(host.get_state(), Mimic.NetworkState.SERVER_LISTENING)
	assert_eq(client.get_state(), Mimic.NetworkState.CLIENT_CONNECTED)
	assert_eq(host.get_local_peer_id(), 1)
	assert_gt(client.get_local_peer_id(), 1)
	assert_signal_emitted_with_parameters(host, "server_started", [port])
	assert_signal_emitted_with_parameters(client, "client_started", ["127.0.0.1", port])
	assert_signal_emitted(client, "client_connected")
	assert_signal_emitted(host, "peer_connected")


func _assert_client_connection_can_be_canceled(transport: int) -> void:
	var port := _next_test_port()
	_configure_transport(transport, port)
	watch_signals(Mimic)

	assert_eq(Mimic.start_client("127.0.0.1", port), OK)
	assert_true(Mimic.is_connecting())
	assert_eq(Mimic.get_local_peer_id(), 0)

	Mimic.cancel_connection()
	await wait_process_frames(2)

	assert_true(Mimic.is_offline())
	assert_eq(Mimic.get_local_peer_id(), 0)
	assert_signal_emitted(Mimic, "stopped")
	assert_signal_not_emitted(Mimic, "client_connection_failed")


func _create_mimic_instance(root_label: String) -> Node:
	var root := Node.new()
	root.name = "%s%d" % [root_label, _custom_multiplayer_roots.size()]
	add_child(root)

	var custom_multiplayer := SceneMultiplayer.new()
	get_tree().set_multiplayer(custom_multiplayer, root.get_path())

	var mimic: Node = MIMIC_SCRIPT.new()
	root.add_child(mimic)
	_custom_multiplayer_roots.append(root)
	return mimic


func _install_fake_port_mapper() -> FakePortMapper:
	var fake := FakePortMapper.new()
	_replace_mimic_port_mapper(fake)
	return fake


func _replace_mimic_port_mapper(port_mapper: MimicPortMapper) -> void:
	if Mimic._port_mapper != null:
		Mimic._port_mapper.wait_to_finish()

	Mimic._port_mapper = port_mapper
	if not Mimic._port_mapper.finished.is_connected(Mimic._finish_port_mapping):
		Mimic._port_mapper.finished.connect(Mimic._finish_port_mapping)


func _configure_transport(transport: int, port: int) -> void:
	ProjectSettings.set_setting(TRANSPORT, transport)
	ProjectSettings.set_setting(EDITOR_AUTO_CONNECT, Mimic.EditorAutoConnectMode.DISABLED)
	ProjectSettings.set_setting(ADDRESS, "127.0.0.1")
	ProjectSettings.set_setting(PORT, port)
	ProjectSettings.set_setting(MAX_CLIENTS, 8)
	ProjectSettings.set_setting(BIND_ADDRESS, "*")
	ProjectSettings.set_setting(ENET_CHANNEL_COUNT, 0)
	ProjectSettings.set_setting(ENET_IN_BANDWIDTH, 0)
	ProjectSettings.set_setting(ENET_OUT_BANDWIDTH, 0)
	ProjectSettings.set_setting(ENET_CLIENT_LOCAL_PORT, 0)
	ProjectSettings.set_setting(WEBSOCKET_CLIENT_USE_TLS, false)
	ProjectSettings.set_setting(WEBSOCKET_PATH, "")
	ProjectSettings.set_setting(WEBSOCKET_HANDSHAKE_TIMEOUT, 1.0)
	ProjectSettings.set_setting(PORT_FORWARDING_ENABLED, false)
	ProjectSettings.set_setting(PORT_MAPPING_DELETE_ON_STOP, true)
	ProjectSettings.set_setting(PORT_MAPPING_QUERY_EXTERNAL_ADDRESS, true)
	ProjectSettings.set_setting(PORT_MAPPING_PROTOCOL, Mimic.PortMappingProtocol.TRANSPORT_DEFAULT)
	ProjectSettings.set_setting(PORT_MAPPING_DURATION, 7200)
	ProjectSettings.set_setting(UPNP_DISCOVER_TIMEOUT_MS, 1)
	ProjectSettings.set_setting(UPNP_DISCOVER_TTL, 1)
	ProjectSettings.set_setting(LOG_LEVEL, MimicLog.Level.NONE)


func _protocols_to_array(protocols: PackedStringArray) -> Array:
	var result := []
	for protocol in protocols:
		result.append(protocol)
	return result


func _next_test_port() -> int:
	_next_port += 1
	return _next_port


func _save_settings() -> void:
	_saved_settings.clear()
	for setting_name in SETTING_NAMES:
		_saved_settings[setting_name] = {
			"exists": ProjectSettings.has_setting(setting_name),
			"value": ProjectSettings.get_setting(setting_name),
		}


func _restore_settings() -> void:
	for setting_name in _saved_settings:
		var saved_setting: Dictionary = _saved_settings[setting_name]
		if bool(saved_setting["exists"]):
			ProjectSettings.set_setting(setting_name, saved_setting["value"])
		elif ProjectSettings.has_setting(setting_name):
			ProjectSettings.clear(setting_name)


class FakePortMapper extends MimicPortMapper:
	var add_requests: Array[Dictionary] = []
	var delete_count := 0
	var wait_count := 0
	var next_error := UPNP.UPNP_RESULT_SUCCESS
	var next_external_address := ""
	var emit_on_add := false


	func add_mapping(port: int, protocols: PackedStringArray, description: String) -> void:
		if not MimicProjectSettings.port_forwarding_enabled:
			return

		add_requests.append({
			"port": port,
			"protocols": protocols.duplicate(),
			"description": description,
		})
		if emit_on_add:
			finished.emit(next_error, next_external_address)


	func delete_mapping() -> void:
		if not MimicProjectSettings.port_mapping_delete_on_stop:
			return

		delete_count += 1


	func wait_to_finish() -> void:
		wait_count += 1


	func get_external_address() -> String:
		return next_external_address
