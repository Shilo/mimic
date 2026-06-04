@tool
class_name MimicProjectSettings extends Object
## Typed accessors and registration helpers for Mimic Project Settings.
## [br][br]
## Settings are registered by the editor plugin and read by the Mimic runtime.

const _TRANSPORT := "mimic_multiplayer/connection/transport"
const _EDITOR_AUTO_CONNECT := "mimic_multiplayer/connection/editor_auto_connect"
const _ADDRESS := "mimic_multiplayer/connection/address"
const _PORT := "mimic_multiplayer/connection/port"
const _MAX_CLIENTS := "mimic_multiplayer/connection/max_clients"
const _BIND_ADDRESS := "mimic_multiplayer/connection/bind_address"
const _ENET_CHANNEL_COUNT := "mimic_multiplayer/enet/channel_count"
const _ENET_IN_BANDWIDTH := "mimic_multiplayer/enet/in_bandwidth"
const _ENET_OUT_BANDWIDTH := "mimic_multiplayer/enet/out_bandwidth"
const _ENET_CLIENT_LOCAL_PORT := "mimic_multiplayer/enet/client_local_port"
const _WEBSOCKET_CLIENT_USE_TLS := "mimic_multiplayer/websocket/client_use_tls"
const _WEBSOCKET_PATH := "mimic_multiplayer/websocket/path"
const _WEBSOCKET_HANDSHAKE_TIMEOUT := "mimic_multiplayer/websocket/handshake_timeout"
const _PORT_FORWARDING_ENABLED := "mimic_multiplayer/port_forwarding/enabled"
const _PORT_MAPPING_DELETE_ON_STOP := "mimic_multiplayer/port_forwarding/delete_mapping_on_stop"
const _PORT_MAPPING_QUERY_EXTERNAL_ADDRESS := (
	"mimic_multiplayer/port_forwarding/query_external_address"
)
const _PORT_MAPPING_PROTOCOL := "mimic_multiplayer/port_forwarding/protocol"
const _PORT_MAPPING_DURATION := "mimic_multiplayer/port_forwarding/duration"
const _UPNP_DISCOVER_TIMEOUT_MS := "mimic_multiplayer/port_forwarding/discover_timeout_ms"
const _UPNP_DISCOVER_TTL := "mimic_multiplayer/port_forwarding/discover_ttl"
const _LOG_LEVEL := "mimic_multiplayer/debug/log_level"

const _TRANSPORT_HINT := "Offline,ENet,WebSocket,WebRTC (Unsupported)"
const _EDITOR_AUTO_CONNECT_HINT := "Disabled,Server Then Client,Client,Server"
const _PORT_MAPPING_PROTOCOL_HINT := "Transport Default,TCP,UDP,TCP and UDP"
const _LOG_LEVEL_HINT := "All,Warning,Error,None"

const _DEFAULT_TRANSPORT := 1 # Mimic.TransportType.ENET
const _DEFAULT_EDITOR_AUTO_CONNECT := 0 # Mimic.EditorAutoConnectMode.DISABLED
const _DEFAULT_ADDRESS := "127.0.0.1"
const _DEFAULT_PORT := 15_490
const _DEFAULT_MAX_CLIENTS := 32
const _DEFAULT_BIND_ADDRESS := "*"
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
const _DEFAULT_PORT_MAPPING_PROTOCOL := 0 # Mimic.PortMappingProtocol.TRANSPORT_DEFAULT
const _DEFAULT_PORT_MAPPING_DURATION := 7200
const _DEFAULT_UPNP_DISCOVER_TIMEOUT_MS := 2000
const _DEFAULT_UPNP_DISCOVER_TTL := 2
const _DEFAULT_LOG_LEVEL := 1 # MimicLog.Level.WARNING

const _SETTINGS := [
	{
		"name": _TRANSPORT,
		"default": _DEFAULT_TRANSPORT,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": _TRANSPORT_HINT,
	},
	{
		"name": _EDITOR_AUTO_CONNECT,
		"default": _DEFAULT_EDITOR_AUTO_CONNECT,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": _EDITOR_AUTO_CONNECT_HINT,
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
		"name": _MAX_CLIENTS,
		"default": _DEFAULT_MAX_CLIENTS,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "1,4095,1",
	},
	{
		"name": _BIND_ADDRESS,
		"default": _DEFAULT_BIND_ADDRESS,
		"type": TYPE_STRING,
		"advanced": true,
	},
	{
		"name": _ENET_CHANNEL_COUNT,
		"default": _DEFAULT_ENET_CHANNEL_COUNT,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,255,1",
		"advanced": true,
	},
	{
		"name": _ENET_IN_BANDWIDTH,
		"default": _DEFAULT_ENET_IN_BANDWIDTH,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,2147483647,1",
		"advanced": true,
	},
	{
		"name": _ENET_OUT_BANDWIDTH,
		"default": _DEFAULT_ENET_OUT_BANDWIDTH,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,2147483647,1",
		"advanced": true,
	},
	{
		"name": _ENET_CLIENT_LOCAL_PORT,
		"default": _DEFAULT_ENET_CLIENT_LOCAL_PORT,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,65535,1",
		"advanced": true,
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
		"advanced": true,
	},
	{
		"name": _WEBSOCKET_HANDSHAKE_TIMEOUT,
		"default": _DEFAULT_WEBSOCKET_HANDSHAKE_TIMEOUT,
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,60,0.1,or_greater",
		"advanced": true,
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
		"advanced": true,
	},
	{
		"name": _PORT_MAPPING_QUERY_EXTERNAL_ADDRESS,
		"default": _DEFAULT_PORT_MAPPING_QUERY_EXTERNAL_ADDRESS,
		"type": TYPE_BOOL,
		"advanced": true,
	},
	{
		"name": _PORT_MAPPING_PROTOCOL,
		"default": _DEFAULT_PORT_MAPPING_PROTOCOL,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": _PORT_MAPPING_PROTOCOL_HINT,
		"advanced": true,
	},
	{
		"name": _PORT_MAPPING_DURATION,
		"default": _DEFAULT_PORT_MAPPING_DURATION,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,86400,1,or_greater",
		"advanced": true,
	},
	{
		"name": _UPNP_DISCOVER_TIMEOUT_MS,
		"default": _DEFAULT_UPNP_DISCOVER_TIMEOUT_MS,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,60000,1,or_greater",
		"advanced": true,
	},
	{
		"name": _UPNP_DISCOVER_TTL,
		"default": _DEFAULT_UPNP_DISCOVER_TTL,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "1,255,1",
		"advanced": true,
	},
	{
		"name": _LOG_LEVEL,
		"default": _DEFAULT_LOG_LEVEL,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": _LOG_LEVEL_HINT,
	},
]

## Configured Mimic transport. See [enum Mimic.TransportType].
static var transport: int:
	get:
		return _get_int(_TRANSPORT, _DEFAULT_TRANSPORT)

## Editor-only connection startup action run by the Mimic autoload.
## See [enum Mimic.EditorAutoConnectMode].
static var editor_auto_connect: int:
	get:
		return _get_int(_EDITOR_AUTO_CONNECT, _DEFAULT_EDITOR_AUTO_CONNECT)

## Default client address used by [method Mimic.start_client].
static var address: String:
	get:
		return _get_string(_ADDRESS, _DEFAULT_ADDRESS)

## Default server/client port used by Mimic connection helpers.
static var port: int:
	get:
		return _get_int(_PORT, _DEFAULT_PORT)

## Maximum ENet clients accepted by [method Mimic.start_server].
static var max_clients: int:
	get:
		return _get_int(_MAX_CLIENTS, _DEFAULT_MAX_CLIENTS)

## Local bind address for server sockets and ENet client local binding.
static var bind_address: String:
	get:
		return _get_string(_BIND_ADDRESS, _DEFAULT_BIND_ADDRESS)

## ENet channel count passed to ENet server/client creation.
static var enet_channel_count: int:
	get:
		return _get_int(_ENET_CHANNEL_COUNT, _DEFAULT_ENET_CHANNEL_COUNT)

## ENet incoming bandwidth limit in bytes per second, or [code]0[/code] for unlimited.
static var enet_in_bandwidth: int:
	get:
		return _get_int(_ENET_IN_BANDWIDTH, _DEFAULT_ENET_IN_BANDWIDTH)

## ENet outgoing bandwidth limit in bytes per second, or [code]0[/code] for unlimited.
static var enet_out_bandwidth: int:
	get:
		return _get_int(_ENET_OUT_BANDWIDTH, _DEFAULT_ENET_OUT_BANDWIDTH)

## Local port used by ENet clients, or [code]0[/code] for an ephemeral port.
static var enet_client_local_port: int:
	get:
		return _get_int(_ENET_CLIENT_LOCAL_PORT, _DEFAULT_ENET_CLIENT_LOCAL_PORT)

## If [code]true[/code], WebSocket clients use [code]wss://[/code] instead of [code]ws://[/code].
static var websocket_client_use_tls: bool:
	get:
		return _get_bool(_WEBSOCKET_CLIENT_USE_TLS, _DEFAULT_WEBSOCKET_CLIENT_USE_TLS)

## Optional WebSocket URL path appended when Mimic builds a client URL from an address and port.
## Ignored when the address already starts with [code]ws://[/code] or [code]wss://[/code].
static var websocket_path: String:
	get:
		return _get_string(_WEBSOCKET_PATH, _DEFAULT_WEBSOCKET_PATH)

## WebSocket handshake timeout in seconds.
static var websocket_handshake_timeout: float:
	get:
		return _get_float(_WEBSOCKET_HANDSHAKE_TIMEOUT, _DEFAULT_WEBSOCKET_HANDSHAKE_TIMEOUT)

## If [code]true[/code], Mimic tries to create UPnP port mappings when hosting.
static var port_forwarding_enabled: bool:
	get:
		return _get_bool(_PORT_FORWARDING_ENABLED, _DEFAULT_PORT_FORWARDING_ENABLED)

## If [code]true[/code], Mimic deletes owned UPnP mappings when networking stops.
static var port_mapping_delete_on_stop: bool:
	get:
		return _get_bool(_PORT_MAPPING_DELETE_ON_STOP, _DEFAULT_PORT_MAPPING_DELETE_ON_STOP)

## If [code]true[/code], Mimic asks the UPnP gateway for its external address.
static var port_mapping_query_external_address: bool:
	get:
		return _get_bool(
			_PORT_MAPPING_QUERY_EXTERNAL_ADDRESS,
			_DEFAULT_PORT_MAPPING_QUERY_EXTERNAL_ADDRESS
		)

## Protocol selection used when creating UPnP port mappings.
static var port_mapping_protocol: int:
	get:
		return _get_int(_PORT_MAPPING_PROTOCOL, _DEFAULT_PORT_MAPPING_PROTOCOL)

## UPnP port mapping lease duration in seconds. [code]0[/code] requests a permanent mapping.
static var port_mapping_duration: int:
	get:
		return _get_int(_PORT_MAPPING_DURATION, _DEFAULT_PORT_MAPPING_DURATION)

## UPnP discovery timeout in milliseconds.
static var upnp_discover_timeout_ms: int:
	get:
		return _get_int(_UPNP_DISCOVER_TIMEOUT_MS, _DEFAULT_UPNP_DISCOVER_TIMEOUT_MS)

## UPnP discovery time-to-live hop count.
static var upnp_discover_ttl: int:
	get:
		return _get_int(_UPNP_DISCOVER_TTL, _DEFAULT_UPNP_DISCOVER_TTL)

## Mimic log output level. See [enum MimicLog.Level].
static var log_level: int:
	get:
		return _get_int(_LOG_LEVEL, _DEFAULT_LOG_LEVEL)

static var _registered := false


## Registers Mimic Project Settings and their editor hints.
static func register() -> void:
	if _registered:
		return

	for setting in _SETTINGS:
		_register_setting(setting)

	_registered = true


## Resets the internal registration flag so [method register] can run again.
static func unregister() -> void:
	_registered = false


static func _get_setting(name: String, default_value: Variant) -> Variant:
	if ProjectSettings.has_setting(name):
		return ProjectSettings.get_setting(name)
	return default_value


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
	ProjectSettings.set_as_basic(name, not bool(setting.get("advanced", false)))

	var property_info := {
		"name": name,
		"type": int(setting["type"]),
	}
	if setting.has("hint"):
		property_info["hint"] = int(setting["hint"])
	if setting.has("hint_string"):
		property_info["hint_string"] = String(setting["hint_string"])

	ProjectSettings.add_property_info(property_info)
