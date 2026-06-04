extends GutTest

const MIMIC_SETTINGS := preload("res://test/unit/support/mimic_project_settings_test_support.gd")

var _saved_settings := {}


func before_each() -> void:
	_saved_settings = MIMIC_SETTINGS.save_settings()
	MIMIC_SETTINGS.clear_settings()
	MimicProjectSettings.unregister()


func after_each() -> void:
	MIMIC_SETTINGS.restore_settings(_saved_settings)
	MimicProjectSettings.unregister()
	MimicProjectSettings.register()


func test_accessors_return_defaults_when_settings_are_missing() -> void:
	assert_eq(MimicProjectSettings.transport, Mimic.TransportType.ENET)
	assert_eq(MimicProjectSettings.editor_auto_connect, Mimic.EditorAutoConnectMode.DISABLED)
	assert_eq(MimicProjectSettings.address, "127.0.0.1")
	assert_eq(MimicProjectSettings.port, 15_490)
	assert_eq(MimicProjectSettings.max_clients, 32)
	assert_eq(MimicProjectSettings.bind_address, "*")
	assert_eq(MimicProjectSettings.enet_channel_count, 0)
	assert_eq(MimicProjectSettings.enet_in_bandwidth, 0)
	assert_eq(MimicProjectSettings.enet_out_bandwidth, 0)
	assert_eq(MimicProjectSettings.enet_client_local_port, 0)
	assert_false(MimicProjectSettings.websocket_client_use_tls)
	assert_eq(MimicProjectSettings.websocket_path, "")
	assert_eq(MimicProjectSettings.websocket_handshake_timeout, 3.0)
	assert_false(MimicProjectSettings.port_forwarding_enabled)
	assert_true(MimicProjectSettings.port_mapping_delete_on_stop)
	assert_true(MimicProjectSettings.port_mapping_query_external_address)
	assert_eq(
		MimicProjectSettings.port_mapping_protocol,
		Mimic.PortMappingProtocol.TRANSPORT_DEFAULT
	)
	assert_eq(MimicProjectSettings.port_mapping_duration, 7200)
	assert_eq(MimicProjectSettings.upnp_discover_timeout_ms, 2000)
	assert_eq(MimicProjectSettings.upnp_discover_ttl, 2)
	assert_eq(MimicProjectSettings.log_level, MimicLog.Level.WARNING)
	assert_eq(Mimic.EditorAutoConnectMode.DISABLED, 0)
	assert_eq(Mimic.EditorAutoConnectMode.SERVER_THEN_CLIENT, 1)
	assert_eq(Mimic.EditorAutoConnectMode.CLIENT, 2)
	assert_eq(Mimic.EditorAutoConnectMode.SERVER, 3)


func test_register_adds_missing_settings_without_overwriting_existing_values() -> void:
	ProjectSettings.set_setting(MIMIC_SETTINGS.ADDRESS, "10.0.0.55")
	ProjectSettings.set_setting(MIMIC_SETTINGS.PORT, 19_001)

	MimicProjectSettings.register()

	assert_eq(MimicProjectSettings.address, "10.0.0.55")
	assert_eq(MimicProjectSettings.port, 19_001)
	assert_eq(MimicProjectSettings.transport, Mimic.TransportType.ENET)
	assert_true(ProjectSettings.has_setting(MIMIC_SETTINGS.EDITOR_AUTO_CONNECT))
	assert_true(ProjectSettings.has_setting(MIMIC_SETTINGS.MAX_CLIENTS))
	assert_true(ProjectSettings.has_setting(MIMIC_SETTINGS.LOG_LEVEL))


func test_accessors_read_typed_project_settings_values() -> void:
	ProjectSettings.set_setting(MIMIC_SETTINGS.TRANSPORT, Mimic.TransportType.WEBSOCKET)
	ProjectSettings.set_setting(
		MIMIC_SETTINGS.EDITOR_AUTO_CONNECT,
		Mimic.EditorAutoConnectMode.SERVER_THEN_CLIENT
	)
	ProjectSettings.set_setting(MIMIC_SETTINGS.ADDRESS, "example.test")
	ProjectSettings.set_setting(MIMIC_SETTINGS.PORT, 19_002)
	ProjectSettings.set_setting(MIMIC_SETTINGS.MAX_CLIENTS, 12)
	ProjectSettings.set_setting(MIMIC_SETTINGS.BIND_ADDRESS, "127.0.0.1")
	ProjectSettings.set_setting(MIMIC_SETTINGS.ENET_CHANNEL_COUNT, 3)
	ProjectSettings.set_setting(MIMIC_SETTINGS.ENET_IN_BANDWIDTH, 1000)
	ProjectSettings.set_setting(MIMIC_SETTINGS.ENET_OUT_BANDWIDTH, 2000)
	ProjectSettings.set_setting(MIMIC_SETTINGS.ENET_CLIENT_LOCAL_PORT, 19_003)
	ProjectSettings.set_setting(MIMIC_SETTINGS.WEBSOCKET_CLIENT_USE_TLS, true)
	ProjectSettings.set_setting(MIMIC_SETTINGS.WEBSOCKET_PATH, "game")
	ProjectSettings.set_setting(MIMIC_SETTINGS.WEBSOCKET_HANDSHAKE_TIMEOUT, 5.5)
	ProjectSettings.set_setting(MIMIC_SETTINGS.PORT_FORWARDING_ENABLED, true)
	ProjectSettings.set_setting(MIMIC_SETTINGS.PORT_MAPPING_DELETE_ON_STOP, false)
	ProjectSettings.set_setting(MIMIC_SETTINGS.PORT_MAPPING_QUERY_EXTERNAL_ADDRESS, false)
	ProjectSettings.set_setting(
		MIMIC_SETTINGS.PORT_MAPPING_PROTOCOL,
		Mimic.PortMappingProtocol.TCP_AND_UDP
	)
	ProjectSettings.set_setting(MIMIC_SETTINGS.PORT_MAPPING_DURATION, 60)
	ProjectSettings.set_setting(MIMIC_SETTINGS.UPNP_DISCOVER_TIMEOUT_MS, 500)
	ProjectSettings.set_setting(MIMIC_SETTINGS.UPNP_DISCOVER_TTL, 4)
	ProjectSettings.set_setting(MIMIC_SETTINGS.LOG_LEVEL, MimicLog.Level.ERROR)

	assert_eq(MimicProjectSettings.transport, Mimic.TransportType.WEBSOCKET)
	assert_eq(
		MimicProjectSettings.editor_auto_connect,
		Mimic.EditorAutoConnectMode.SERVER_THEN_CLIENT
	)
	assert_eq(MimicProjectSettings.address, "example.test")
	assert_eq(MimicProjectSettings.port, 19_002)
	assert_eq(MimicProjectSettings.max_clients, 12)
	assert_eq(MimicProjectSettings.bind_address, "127.0.0.1")
	assert_eq(MimicProjectSettings.enet_channel_count, 3)
	assert_eq(MimicProjectSettings.enet_in_bandwidth, 1000)
	assert_eq(MimicProjectSettings.enet_out_bandwidth, 2000)
	assert_eq(MimicProjectSettings.enet_client_local_port, 19_003)
	assert_true(MimicProjectSettings.websocket_client_use_tls)
	assert_eq(MimicProjectSettings.websocket_path, "game")
	assert_eq(MimicProjectSettings.websocket_handshake_timeout, 5.5)
	assert_true(MimicProjectSettings.port_forwarding_enabled)
	assert_false(MimicProjectSettings.port_mapping_delete_on_stop)
	assert_false(MimicProjectSettings.port_mapping_query_external_address)
	assert_eq(MimicProjectSettings.port_mapping_protocol, Mimic.PortMappingProtocol.TCP_AND_UDP)
	assert_eq(MimicProjectSettings.port_mapping_duration, 60)
	assert_eq(MimicProjectSettings.upnp_discover_timeout_ms, 500)
	assert_eq(MimicProjectSettings.upnp_discover_ttl, 4)
	assert_eq(MimicProjectSettings.log_level, MimicLog.Level.ERROR)
