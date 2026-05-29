@tool
class_name MimicProjectSettings extends Object

const _LOG_LEVEL := "mimic/logging/log_level"
const _TRANSPORT_TYPE := "mimic/connection/transport_type"
const _ADDRESS := "mimic/connection/address"
const _PORT := "mimic/connection/port"
const _BIND_ADDRESS := "mimic/connection/bind_address"
const _MAX_CLIENTS := "mimic/connection/max_clients"
const _REPLACE_EXISTING_PEER := "mimic/connection/replace_existing_peer"
const _REFUSE_NEW_CONNECTIONS := "mimic/connection/refuse_new_connections"
const _ENET_CHANNEL_COUNT := "mimic/enet/channel_count"
const _ENET_IN_BANDWIDTH := "mimic/enet/in_bandwidth"
const _ENET_OUT_BANDWIDTH := "mimic/enet/out_bandwidth"
const _ENET_CLIENT_LOCAL_PORT := "mimic/enet/client_local_port"
const _WEBSOCKET_CLIENT_USE_TLS := "mimic/websocket/client_use_tls"
const _WEBSOCKET_PATH := "mimic/websocket/path"
const _WEBSOCKET_HANDSHAKE_TIMEOUT := "mimic/websocket/handshake_timeout"
const _PORT_FORWARDING_ENABLED := "mimic/port_forwarding/enabled"
const _PORT_MAPPING_DELETE_ON_STOP := "mimic/port_forwarding/delete_mapping_on_stop"
const _PORT_MAPPING_QUERY_EXTERNAL_ADDRESS := "mimic/port_forwarding/query_external_address"
const _PORT_MAPPING_PROTOCOL := "mimic/port_forwarding/protocol"
const _PORT_MAPPING_DURATION := "mimic/port_forwarding/duration"
const _UPNP_DISCOVER_TIMEOUT_MS := "mimic/port_forwarding/upnp_discover_timeout_ms"
const _UPNP_DISCOVER_TTL := "mimic/port_forwarding/upnp_discover_ttl"
const _UPNP_DESCRIPTION := "mimic/port_forwarding/description"

const _DEFAULT_LOG_LEVEL := 1
const _DEFAULT_TRANSPORT_TYPE := 1
const _DEFAULT_ADDRESS := "127.0.0.1"
const _DEFAULT_PORT := 8910
const _DEFAULT_BIND_ADDRESS := "*"
const _DEFAULT_MAX_CLIENTS := 32
const _DEFAULT_REPLACE_EXISTING_PEER := true
const _DEFAULT_REFUSE_NEW_CONNECTIONS := false
const _DEFAULT_ENET_CHANNEL_COUNT := 0
const _DEFAULT_ENET_IN_BANDWIDTH := 0
const _DEFAULT_ENET_OUT_BANDWIDTH := 0
const _DEFAULT_ENET_CLIENT_LOCAL_PORT := 0
const _DEFAULT_WEBSOCKET_CLIENT_USE_TLS := false
const _DEFAULT_WEBSOCKET_PATH := ""
const _DEFAULT_WEBSOCKET_HANDSHAKE_TIMEOUT := 3.0
const _DEFAULT_PORT_FORWARDING_ENABLED := false
const _DEFAULT_PORT_MAPPING_DELETE_ON_STOP := true
const _DEFAULT_PORT_MAPPING_QUERY_EXTERNAL_ADDRESS := true
const _DEFAULT_PORT_MAPPING_PROTOCOL := 0
const _DEFAULT_PORT_MAPPING_DURATION := 7200
const _DEFAULT_UPNP_DISCOVER_TIMEOUT_MS := 2000
const _DEFAULT_UPNP_DISCOVER_TTL := 2
const _DEFAULT_UPNP_DESCRIPTION := "Mimic"

const _SETTINGS := [
	{
		"name": _LOG_LEVEL,
		"default": _DEFAULT_LOG_LEVEL,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "All,Warning,Error,None",
	},
	{
		"name": _TRANSPORT_TYPE,
		"default": _DEFAULT_TRANSPORT_TYPE,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Offline,ENet,WebSocket,WebRTC (Unsupported)",
	},
	{
		"name": _ADDRESS,
		"default": _DEFAULT_ADDRESS,
		"type": TYPE_STRING,
	},
	{
		"name": _PORT,
		"default": _DEFAULT_PORT,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "1,65535,1",
	},
	{
		"name": _BIND_ADDRESS,
		"default": _DEFAULT_BIND_ADDRESS,
		"type": TYPE_STRING,
	},
	{
		"name": _MAX_CLIENTS,
		"default": _DEFAULT_MAX_CLIENTS,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "1,4095,1",
	},
	{
		"name": _REPLACE_EXISTING_PEER,
		"default": _DEFAULT_REPLACE_EXISTING_PEER,
		"type": TYPE_BOOL,
	},
	{
		"name": _REFUSE_NEW_CONNECTIONS,
		"default": _DEFAULT_REFUSE_NEW_CONNECTIONS,
		"type": TYPE_BOOL,
	},
	{
		"name": _ENET_CHANNEL_COUNT,
		"default": _DEFAULT_ENET_CHANNEL_COUNT,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,255,1",
	},
	{
		"name": _ENET_IN_BANDWIDTH,
		"default": _DEFAULT_ENET_IN_BANDWIDTH,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,2147483647,1",
	},
	{
		"name": _ENET_OUT_BANDWIDTH,
		"default": _DEFAULT_ENET_OUT_BANDWIDTH,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,2147483647,1",
	},
	{
		"name": _ENET_CLIENT_LOCAL_PORT,
		"default": _DEFAULT_ENET_CLIENT_LOCAL_PORT,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,65535,1",
	},
	{
		"name": _WEBSOCKET_CLIENT_USE_TLS,
		"default": _DEFAULT_WEBSOCKET_CLIENT_USE_TLS,
		"type": TYPE_BOOL,
	},
	{
		"name": _WEBSOCKET_PATH,
		"default": _DEFAULT_WEBSOCKET_PATH,
		"type": TYPE_STRING,
	},
	{
		"name": _WEBSOCKET_HANDSHAKE_TIMEOUT,
		"default": _DEFAULT_WEBSOCKET_HANDSHAKE_TIMEOUT,
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,60,0.1,or_greater",
	},
	{
		"name": _PORT_FORWARDING_ENABLED,
		"default": _DEFAULT_PORT_FORWARDING_ENABLED,
		"type": TYPE_BOOL,
	},
	{
		"name": _PORT_MAPPING_DELETE_ON_STOP,
		"default": _DEFAULT_PORT_MAPPING_DELETE_ON_STOP,
		"type": TYPE_BOOL,
	},
	{
		"name": _PORT_MAPPING_QUERY_EXTERNAL_ADDRESS,
		"default": _DEFAULT_PORT_MAPPING_QUERY_EXTERNAL_ADDRESS,
		"type": TYPE_BOOL,
	},
	{
		"name": _PORT_MAPPING_PROTOCOL,
		"default": _DEFAULT_PORT_MAPPING_PROTOCOL,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Transport Default,TCP,UDP,TCP and UDP",
	},
	{
		"name": _PORT_MAPPING_DURATION,
		"default": _DEFAULT_PORT_MAPPING_DURATION,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,86400,1,or_greater",
	},
	{
		"name": _UPNP_DISCOVER_TIMEOUT_MS,
		"default": _DEFAULT_UPNP_DISCOVER_TIMEOUT_MS,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,60000,1,or_greater",
	},
	{
		"name": _UPNP_DISCOVER_TTL,
		"default": _DEFAULT_UPNP_DISCOVER_TTL,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "1,255,1",
	},
	{
		"name": _UPNP_DESCRIPTION,
		"default": _DEFAULT_UPNP_DESCRIPTION,
		"type": TYPE_STRING,
	},
]

static var log_level: int:
	get:
		return _get_int(_LOG_LEVEL, _DEFAULT_LOG_LEVEL)
	set(value):
		_set_setting(_LOG_LEVEL, value)

static var transport_type: int:
	get:
		return _get_int(_TRANSPORT_TYPE, _DEFAULT_TRANSPORT_TYPE)
	set(value):
		_set_setting(_TRANSPORT_TYPE, value)

static var address: String:
	get:
		return _get_string(_ADDRESS, _DEFAULT_ADDRESS)
	set(value):
		_set_setting(_ADDRESS, value)

static var port: int:
	get:
		return _get_int(_PORT, _DEFAULT_PORT)
	set(value):
		_set_setting(_PORT, value)

static var bind_address: String:
	get:
		return _get_string(_BIND_ADDRESS, _DEFAULT_BIND_ADDRESS)
	set(value):
		_set_setting(_BIND_ADDRESS, value)

static var max_clients: int:
	get:
		return _get_int(_MAX_CLIENTS, _DEFAULT_MAX_CLIENTS)
	set(value):
		_set_setting(_MAX_CLIENTS, value)

static var replace_existing_peer: bool:
	get:
		return _get_bool(_REPLACE_EXISTING_PEER, _DEFAULT_REPLACE_EXISTING_PEER)
	set(value):
		_set_setting(_REPLACE_EXISTING_PEER, value)

static var refuse_new_connections: bool:
	get:
		return _get_bool(_REFUSE_NEW_CONNECTIONS, _DEFAULT_REFUSE_NEW_CONNECTIONS)
	set(value):
		_set_setting(_REFUSE_NEW_CONNECTIONS, value)

static var enet_channel_count: int:
	get:
		return _get_int(_ENET_CHANNEL_COUNT, _DEFAULT_ENET_CHANNEL_COUNT)
	set(value):
		_set_setting(_ENET_CHANNEL_COUNT, value)

static var enet_in_bandwidth: int:
	get:
		return _get_int(_ENET_IN_BANDWIDTH, _DEFAULT_ENET_IN_BANDWIDTH)
	set(value):
		_set_setting(_ENET_IN_BANDWIDTH, value)

static var enet_out_bandwidth: int:
	get:
		return _get_int(_ENET_OUT_BANDWIDTH, _DEFAULT_ENET_OUT_BANDWIDTH)
	set(value):
		_set_setting(_ENET_OUT_BANDWIDTH, value)

static var enet_client_local_port: int:
	get:
		return _get_int(_ENET_CLIENT_LOCAL_PORT, _DEFAULT_ENET_CLIENT_LOCAL_PORT)
	set(value):
		_set_setting(_ENET_CLIENT_LOCAL_PORT, value)

static var websocket_client_use_tls: bool:
	get:
		return _get_bool(_WEBSOCKET_CLIENT_USE_TLS, _DEFAULT_WEBSOCKET_CLIENT_USE_TLS)
	set(value):
		_set_setting(_WEBSOCKET_CLIENT_USE_TLS, value)

static var websocket_path: String:
	get:
		return _get_string(_WEBSOCKET_PATH, _DEFAULT_WEBSOCKET_PATH)
	set(value):
		_set_setting(_WEBSOCKET_PATH, value)

static var websocket_handshake_timeout: float:
	get:
		return _get_float(_WEBSOCKET_HANDSHAKE_TIMEOUT, _DEFAULT_WEBSOCKET_HANDSHAKE_TIMEOUT)
	set(value):
		_set_setting(_WEBSOCKET_HANDSHAKE_TIMEOUT, value)

static var port_forwarding_enabled: bool:
	get:
		return _get_bool(_PORT_FORWARDING_ENABLED, _DEFAULT_PORT_FORWARDING_ENABLED)
	set(value):
		_set_setting(_PORT_FORWARDING_ENABLED, value)

static var port_mapping_delete_on_stop: bool:
	get:
		return _get_bool(_PORT_MAPPING_DELETE_ON_STOP, _DEFAULT_PORT_MAPPING_DELETE_ON_STOP)
	set(value):
		_set_setting(_PORT_MAPPING_DELETE_ON_STOP, value)

static var port_mapping_query_external_address: bool:
	get:
		return _get_bool(_PORT_MAPPING_QUERY_EXTERNAL_ADDRESS, _DEFAULT_PORT_MAPPING_QUERY_EXTERNAL_ADDRESS)
	set(value):
		_set_setting(_PORT_MAPPING_QUERY_EXTERNAL_ADDRESS, value)

static var port_mapping_protocol: int:
	get:
		return _get_int(_PORT_MAPPING_PROTOCOL, _DEFAULT_PORT_MAPPING_PROTOCOL)
	set(value):
		_set_setting(_PORT_MAPPING_PROTOCOL, value)

static var port_mapping_duration: int:
	get:
		return _get_int(_PORT_MAPPING_DURATION, _DEFAULT_PORT_MAPPING_DURATION)
	set(value):
		_set_setting(_PORT_MAPPING_DURATION, value)

static var upnp_discover_timeout_ms: int:
	get:
		return _get_int(_UPNP_DISCOVER_TIMEOUT_MS, _DEFAULT_UPNP_DISCOVER_TIMEOUT_MS)
	set(value):
		_set_setting(_UPNP_DISCOVER_TIMEOUT_MS, value)

static var upnp_discover_ttl: int:
	get:
		return _get_int(_UPNP_DISCOVER_TTL, _DEFAULT_UPNP_DISCOVER_TTL)
	set(value):
		_set_setting(_UPNP_DISCOVER_TTL, value)

static var upnp_description: String:
	get:
		return _get_string(_UPNP_DESCRIPTION, _DEFAULT_UPNP_DESCRIPTION)
	set(value):
		_set_setting(_UPNP_DESCRIPTION, value)

static var _registered := false


static func register() -> void:
	if _registered:
		return

	for setting in _SETTINGS:
		_register_setting(setting)

	_registered = true


static func unregister(clear_values: bool = false) -> void:
	_registered = false
	if not clear_values:
		return

	for setting in _SETTINGS:
		var name := String(setting["name"])
		if ProjectSettings.has_setting(name):
			ProjectSettings.clear(name)


static func _get_setting(name: String, default_value: Variant) -> Variant:
	if ProjectSettings.has_setting(name):
		return ProjectSettings.get_setting(name)
	return default_value


static func _set_setting(name: String, value: Variant) -> void:
	ProjectSettings.set_setting(name, value)


static func _get_string(name: String, default_value: String) -> String:
	return String(_get_setting(name, default_value))


static func _get_int(name: String, default_value: int) -> int:
	return int(_get_setting(name, default_value))


static func _get_float(name: String, default_value: float) -> float:
	return float(_get_setting(name, default_value))


static func _get_bool(name: String, default_value: bool) -> bool:
	return bool(_get_setting(name, default_value))


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
