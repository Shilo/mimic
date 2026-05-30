extends GutTest

const TRANSPORT := "mimic_multiplayer/connection/transport"
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


func before_each() -> void:
	_save_settings()
	_clear_mimic_settings()
	MimicProjectSettings.unregister()


func after_each() -> void:
	_restore_settings()
	MimicProjectSettings.unregister()
	MimicProjectSettings.register()


func test_accessors_return_defaults_when_settings_are_missing() -> void:
	assert_eq(MimicProjectSettings.transport, Mimic.TransportType.ENET)
	assert_eq(MimicProjectSettings.address, "127.0.0.1")
	assert_eq(MimicProjectSettings.port, 15490)
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
	assert_eq(MimicProjectSettings.port_mapping_protocol, Mimic.PortMappingProtocol.TRANSPORT_DEFAULT)
	assert_eq(MimicProjectSettings.port_mapping_duration, 7200)
	assert_eq(MimicProjectSettings.upnp_discover_timeout_ms, 2000)
	assert_eq(MimicProjectSettings.upnp_discover_ttl, 2)
	assert_eq(MimicProjectSettings.log_level, MimicLog.Level.WARNING)


func test_register_adds_missing_settings_without_overwriting_existing_values() -> void:
	ProjectSettings.set_setting(ADDRESS, "10.0.0.55")
	ProjectSettings.set_setting(PORT, 19001)

	MimicProjectSettings.register()

	assert_eq(MimicProjectSettings.address, "10.0.0.55")
	assert_eq(MimicProjectSettings.port, 19001)
	assert_eq(MimicProjectSettings.transport, Mimic.TransportType.ENET)
	assert_true(ProjectSettings.has_setting(MAX_CLIENTS))
	assert_true(ProjectSettings.has_setting(LOG_LEVEL))


func test_accessors_read_typed_project_settings_values() -> void:
	ProjectSettings.set_setting(TRANSPORT, Mimic.TransportType.WEBSOCKET)
	ProjectSettings.set_setting(ADDRESS, "example.test")
	ProjectSettings.set_setting(PORT, 19002)
	ProjectSettings.set_setting(MAX_CLIENTS, 12)
	ProjectSettings.set_setting(BIND_ADDRESS, "127.0.0.1")
	ProjectSettings.set_setting(ENET_CHANNEL_COUNT, 3)
	ProjectSettings.set_setting(ENET_IN_BANDWIDTH, 1000)
	ProjectSettings.set_setting(ENET_OUT_BANDWIDTH, 2000)
	ProjectSettings.set_setting(ENET_CLIENT_LOCAL_PORT, 19003)
	ProjectSettings.set_setting(WEBSOCKET_CLIENT_USE_TLS, true)
	ProjectSettings.set_setting(WEBSOCKET_PATH, "game")
	ProjectSettings.set_setting(WEBSOCKET_HANDSHAKE_TIMEOUT, 5.5)
	ProjectSettings.set_setting(PORT_FORWARDING_ENABLED, true)
	ProjectSettings.set_setting(PORT_MAPPING_DELETE_ON_STOP, false)
	ProjectSettings.set_setting(PORT_MAPPING_QUERY_EXTERNAL_ADDRESS, false)
	ProjectSettings.set_setting(PORT_MAPPING_PROTOCOL, Mimic.PortMappingProtocol.TCP_AND_UDP)
	ProjectSettings.set_setting(PORT_MAPPING_DURATION, 60)
	ProjectSettings.set_setting(UPNP_DISCOVER_TIMEOUT_MS, 500)
	ProjectSettings.set_setting(UPNP_DISCOVER_TTL, 4)
	ProjectSettings.set_setting(LOG_LEVEL, MimicLog.Level.ERROR)

	assert_eq(MimicProjectSettings.transport, Mimic.TransportType.WEBSOCKET)
	assert_eq(MimicProjectSettings.address, "example.test")
	assert_eq(MimicProjectSettings.port, 19002)
	assert_eq(MimicProjectSettings.max_clients, 12)
	assert_eq(MimicProjectSettings.bind_address, "127.0.0.1")
	assert_eq(MimicProjectSettings.enet_channel_count, 3)
	assert_eq(MimicProjectSettings.enet_in_bandwidth, 1000)
	assert_eq(MimicProjectSettings.enet_out_bandwidth, 2000)
	assert_eq(MimicProjectSettings.enet_client_local_port, 19003)
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


func _save_settings() -> void:
	_saved_settings.clear()
	for setting_name in SETTING_NAMES:
		_saved_settings[setting_name] = {
			"exists": ProjectSettings.has_setting(setting_name),
			"value": ProjectSettings.get_setting(setting_name),
		}


func _clear_mimic_settings() -> void:
	for setting_name in SETTING_NAMES:
		if ProjectSettings.has_setting(setting_name):
			ProjectSettings.clear(setting_name)


func _restore_settings() -> void:
	for setting_name in SETTING_NAMES:
		var saved_setting: Dictionary = _saved_settings[setting_name]
		if bool(saved_setting["exists"]):
			ProjectSettings.set_setting(setting_name, saved_setting["value"])
		elif ProjectSettings.has_setting(setting_name):
			ProjectSettings.clear(setting_name)
