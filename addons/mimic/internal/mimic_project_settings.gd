@tool
extends RefCounted
class_name MimicProjectSettings

const SETTING_TRANSPORT_TYPE := "mimic/connection/transport_type"
const SETTING_ADDRESS := "mimic/connection/address"
const SETTING_PORT := "mimic/connection/port"
const SETTING_BIND_ADDRESS := "mimic/connection/bind_address"
const SETTING_MAX_CLIENTS := "mimic/connection/max_clients"
const SETTING_REPLACE_EXISTING_PEER := "mimic/connection/replace_existing_peer"
const SETTING_REFUSE_NEW_CONNECTIONS := "mimic/connection/refuse_new_connections"
const SETTING_ENET_CHANNEL_COUNT := "mimic/enet/channel_count"
const SETTING_ENET_IN_BANDWIDTH := "mimic/enet/in_bandwidth"
const SETTING_ENET_OUT_BANDWIDTH := "mimic/enet/out_bandwidth"
const SETTING_ENET_CLIENT_LOCAL_PORT := "mimic/enet/client_local_port"
const SETTING_WEBSOCKET_CLIENT_USE_TLS := "mimic/websocket/client_use_tls"
const SETTING_WEBSOCKET_PATH := "mimic/websocket/path"
const SETTING_WEBSOCKET_HANDSHAKE_TIMEOUT := "mimic/websocket/handshake_timeout"
const SETTING_PORT_FORWARDING_ENABLED := "mimic/port_forwarding/enabled"
const SETTING_PORT_MAPPING_DELETE_ON_STOP := "mimic/port_forwarding/delete_mapping_on_stop"
const SETTING_PORT_MAPPING_QUERY_EXTERNAL_ADDRESS := "mimic/port_forwarding/query_external_address"
const SETTING_PORT_MAPPING_PROTOCOL := "mimic/port_forwarding/protocol"
const SETTING_PORT_MAPPING_DURATION := "mimic/port_forwarding/duration"
const SETTING_UPNP_DISCOVER_TIMEOUT_MS := "mimic/port_forwarding/upnp_discover_timeout_ms"
const SETTING_UPNP_DISCOVER_TTL := "mimic/port_forwarding/upnp_discover_ttl"
const SETTING_UPNP_DESCRIPTION := "mimic/port_forwarding/description"

const DEFAULT_TRANSPORT_TYPE := 1
const DEFAULT_ADDRESS := "127.0.0.1"
const DEFAULT_PORT := 8910
const DEFAULT_BIND_ADDRESS := "*"
const DEFAULT_MAX_CLIENTS := 32
const DEFAULT_REPLACE_EXISTING_PEER := true
const DEFAULT_REFUSE_NEW_CONNECTIONS := false
const DEFAULT_ENET_CHANNEL_COUNT := 0
const DEFAULT_ENET_IN_BANDWIDTH := 0
const DEFAULT_ENET_OUT_BANDWIDTH := 0
const DEFAULT_ENET_CLIENT_LOCAL_PORT := 0
const DEFAULT_WEBSOCKET_CLIENT_USE_TLS := false
const DEFAULT_WEBSOCKET_PATH := ""
const DEFAULT_WEBSOCKET_HANDSHAKE_TIMEOUT := 3.0
const DEFAULT_PORT_FORWARDING_ENABLED := false
const DEFAULT_PORT_MAPPING_DELETE_ON_STOP := true
const DEFAULT_PORT_MAPPING_QUERY_EXTERNAL_ADDRESS := true
const DEFAULT_PORT_MAPPING_PROTOCOL := 0
const DEFAULT_PORT_MAPPING_DURATION := 7200
const DEFAULT_UPNP_DISCOVER_TIMEOUT_MS := 2000
const DEFAULT_UPNP_DISCOVER_TTL := 2
const DEFAULT_UPNP_DESCRIPTION := "Mimic"

const SETTINGS := [
	{
		"name": SETTING_TRANSPORT_TYPE,
		"default": DEFAULT_TRANSPORT_TYPE,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Offline,ENet,WebSocket,WebRTC (Unsupported)",
	},
	{
		"name": SETTING_ADDRESS,
		"default": DEFAULT_ADDRESS,
		"type": TYPE_STRING,
	},
	{
		"name": SETTING_PORT,
		"default": DEFAULT_PORT,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "1,65535,1",
	},
	{
		"name": SETTING_BIND_ADDRESS,
		"default": DEFAULT_BIND_ADDRESS,
		"type": TYPE_STRING,
	},
	{
		"name": SETTING_MAX_CLIENTS,
		"default": DEFAULT_MAX_CLIENTS,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "1,4095,1",
	},
	{
		"name": SETTING_REPLACE_EXISTING_PEER,
		"default": DEFAULT_REPLACE_EXISTING_PEER,
		"type": TYPE_BOOL,
	},
	{
		"name": SETTING_REFUSE_NEW_CONNECTIONS,
		"default": DEFAULT_REFUSE_NEW_CONNECTIONS,
		"type": TYPE_BOOL,
	},
	{
		"name": SETTING_ENET_CHANNEL_COUNT,
		"default": DEFAULT_ENET_CHANNEL_COUNT,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,255,1",
	},
	{
		"name": SETTING_ENET_IN_BANDWIDTH,
		"default": DEFAULT_ENET_IN_BANDWIDTH,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,2147483647,1",
	},
	{
		"name": SETTING_ENET_OUT_BANDWIDTH,
		"default": DEFAULT_ENET_OUT_BANDWIDTH,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,2147483647,1",
	},
	{
		"name": SETTING_ENET_CLIENT_LOCAL_PORT,
		"default": DEFAULT_ENET_CLIENT_LOCAL_PORT,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,65535,1",
	},
	{
		"name": SETTING_WEBSOCKET_CLIENT_USE_TLS,
		"default": DEFAULT_WEBSOCKET_CLIENT_USE_TLS,
		"type": TYPE_BOOL,
	},
	{
		"name": SETTING_WEBSOCKET_PATH,
		"default": DEFAULT_WEBSOCKET_PATH,
		"type": TYPE_STRING,
	},
	{
		"name": SETTING_WEBSOCKET_HANDSHAKE_TIMEOUT,
		"default": DEFAULT_WEBSOCKET_HANDSHAKE_TIMEOUT,
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,60,0.1,or_greater",
	},
	{
		"name": SETTING_PORT_FORWARDING_ENABLED,
		"default": DEFAULT_PORT_FORWARDING_ENABLED,
		"type": TYPE_BOOL,
	},
	{
		"name": SETTING_PORT_MAPPING_DELETE_ON_STOP,
		"default": DEFAULT_PORT_MAPPING_DELETE_ON_STOP,
		"type": TYPE_BOOL,
	},
	{
		"name": SETTING_PORT_MAPPING_QUERY_EXTERNAL_ADDRESS,
		"default": DEFAULT_PORT_MAPPING_QUERY_EXTERNAL_ADDRESS,
		"type": TYPE_BOOL,
	},
	{
		"name": SETTING_PORT_MAPPING_PROTOCOL,
		"default": DEFAULT_PORT_MAPPING_PROTOCOL,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Transport Default,TCP,UDP,TCP and UDP",
	},
	{
		"name": SETTING_PORT_MAPPING_DURATION,
		"default": DEFAULT_PORT_MAPPING_DURATION,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,86400,1,or_greater",
	},
	{
		"name": SETTING_UPNP_DISCOVER_TIMEOUT_MS,
		"default": DEFAULT_UPNP_DISCOVER_TIMEOUT_MS,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,60000,1,or_greater",
	},
	{
		"name": SETTING_UPNP_DISCOVER_TTL,
		"default": DEFAULT_UPNP_DISCOVER_TTL,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "1,255,1",
	},
	{
		"name": SETTING_UPNP_DESCRIPTION,
		"default": DEFAULT_UPNP_DESCRIPTION,
		"type": TYPE_STRING,
	},
]

static var _registered := false


static func register_settings() -> void:
	if _registered:
		return

	for setting in SETTINGS:
		_register_setting(setting)

	_registered = true


static func unregister_settings(clear_values: bool = false) -> void:
	_registered = false
	if not clear_values:
		return

	for setting in SETTINGS:
		var name := String(setting["name"])
		if ProjectSettings.has_setting(name):
			ProjectSettings.clear(name)


static func get_setting(name: String, default_value: Variant) -> Variant:
	if ProjectSettings.has_setting(name):
		return ProjectSettings.get_setting(name)
	return default_value


static func get_string(name: String, default_value: String) -> String:
	return String(get_setting(name, default_value))


static func get_int(name: String, default_value: int) -> int:
	return int(get_setting(name, default_value))


static func get_float(name: String, default_value: float) -> float:
	return float(get_setting(name, default_value))


static func get_bool(name: String, default_value: bool) -> bool:
	return bool(get_setting(name, default_value))


static func _register_setting(setting: Dictionary) -> void:
	var name := String(setting["name"])
	var default_value: Variant = setting["default"]

	if not ProjectSettings.has_setting(name):
		ProjectSettings.set_setting(name, default_value)

	ProjectSettings.set_initial_value(name, default_value)
	ProjectSettings.set_as_basic(name, true)

	var property_info := {
		"name": name,
		"type": int(setting["type"]),
	}
	if setting.has("hint"):
		property_info["hint"] = int(setting["hint"])
	if setting.has("hint_string"):
		property_info["hint_string"] = String(setting["hint_string"])

	ProjectSettings.add_property_info(property_info)
