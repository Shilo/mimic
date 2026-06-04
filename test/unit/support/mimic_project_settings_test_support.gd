extends RefCounted

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


static func save_settings(setting_names: Array = SETTING_NAMES) -> Dictionary:
	var saved_settings: Dictionary = {}
	for setting_name in setting_names:
		saved_settings[setting_name] = {
			"exists": ProjectSettings.has_setting(setting_name),
			"value": ProjectSettings.get_setting(setting_name),
		}
	return saved_settings


static func clear_settings(setting_names: Array = SETTING_NAMES) -> void:
	for setting_name in setting_names:
		if ProjectSettings.has_setting(setting_name):
			ProjectSettings.clear(setting_name)


static func restore_settings(saved_settings: Dictionary) -> void:
	for setting_name in saved_settings:
		var saved_setting: Dictionary = saved_settings[setting_name]
		if bool(saved_setting["exists"]):
			ProjectSettings.set_setting(setting_name, saved_setting["value"])
		elif ProjectSettings.has_setting(setting_name):
			ProjectSettings.clear(setting_name)
