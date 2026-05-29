@tool
extends EditorPlugin

const _AUTOLOAD_NAME := "Mimic"
const _PROJECT_SETTINGS := [
	{
		"name": "mimic/connection/transport_type",
		"default": 1,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Offline,ENet,WebSocket,WebRTC (Unsupported)",
	},
	{
		"name": "mimic/connection/address",
		"default": "127.0.0.1",
		"type": TYPE_STRING,
	},
	{
		"name": "mimic/connection/port",
		"default": 8910,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "1,65535,1",
	},
	{
		"name": "mimic/connection/bind_address",
		"default": "*",
		"type": TYPE_STRING,
	},
	{
		"name": "mimic/connection/max_clients",
		"default": 32,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "1,4095,1",
	},
	{
		"name": "mimic/connection/replace_existing_peer",
		"default": true,
		"type": TYPE_BOOL,
	},
	{
		"name": "mimic/connection/refuse_new_connections",
		"default": false,
		"type": TYPE_BOOL,
	},
	{
		"name": "mimic/enet/channel_count",
		"default": 0,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,255,1",
	},
	{
		"name": "mimic/enet/in_bandwidth",
		"default": 0,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,2147483647,1",
	},
	{
		"name": "mimic/enet/out_bandwidth",
		"default": 0,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,2147483647,1",
	},
	{
		"name": "mimic/enet/client_local_port",
		"default": 0,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,65535,1",
	},
	{
		"name": "mimic/websocket/client_use_tls",
		"default": false,
		"type": TYPE_BOOL,
	},
	{
		"name": "mimic/websocket/path",
		"default": "",
		"type": TYPE_STRING,
	},
	{
		"name": "mimic/websocket/handshake_timeout",
		"default": 3.0,
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,60,0.1,or_greater",
	},
	{
		"name": "mimic/port_forwarding/enabled",
		"default": false,
		"type": TYPE_BOOL,
	},
	{
		"name": "mimic/port_forwarding/delete_mapping_on_stop",
		"default": true,
		"type": TYPE_BOOL,
	},
	{
		"name": "mimic/port_forwarding/query_external_address",
		"default": true,
		"type": TYPE_BOOL,
	},
	{
		"name": "mimic/port_forwarding/protocol",
		"default": 0,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Transport Default,TCP,UDP,TCP and UDP",
	},
	{
		"name": "mimic/port_forwarding/duration",
		"default": 7200,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,86400,1,or_greater",
	},
	{
		"name": "mimic/port_forwarding/upnp_discover_timeout_ms",
		"default": 2000,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,60000,1,or_greater",
	},
	{
		"name": "mimic/port_forwarding/upnp_discover_ttl",
		"default": 2,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "1,255,1",
	},
	{
		"name": "mimic/port_forwarding/description",
		"default": "Mimic",
		"type": TYPE_STRING,
	},
]

var _project_settings_registered := false


func _enter_tree() -> void:
	_ensure_project_settings()


func _enable_plugin() -> void:
	_ensure_project_settings()

	var autoload_status := _has_autoload()
	if autoload_status == OK:
		return

	if autoload_status == ERR_ALREADY_EXISTS:
		push_warning("Autoload '%s' already exists and does not point to this addon." % _AUTOLOAD_NAME)
		return

	add_autoload_singleton(_AUTOLOAD_NAME, _get_autoload_path())


func _disable_plugin() -> void:
	if _has_autoload() == OK:
		remove_autoload_singleton(_AUTOLOAD_NAME)


func _has_autoload() -> Error:
	if not ProjectSettings.has_setting("autoload/" + _AUTOLOAD_NAME):
		return ERR_DOES_NOT_EXIST

	var autoload_path := String(ProjectSettings.get_setting("autoload/" + _AUTOLOAD_NAME))
	if autoload_path.begins_with("*"):
		autoload_path = autoload_path.substr(1)
	autoload_path = ResourceUID.ensure_path(autoload_path)
	if autoload_path != _get_autoload_path():
		return ERR_ALREADY_EXISTS

	return OK


func _ensure_project_settings() -> void:
	if _project_settings_registered:
		return

	for setting in _PROJECT_SETTINGS:
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

	_project_settings_registered = true


func _get_autoload_path() -> String:
	return get_script().resource_path.get_base_dir().path_join(_AUTOLOAD_NAME.to_lower() + ".gd")
