class_name MimicConnector extends CanvasLayer

enum AutoConnectMode { DISABLED, SERVER, CLIENT, SERVER_IF_FIRST_ELSE_CLIENT }

@export var auto_connect_mode: AutoConnectMode = AutoConnectMode.DISABLED


func _ready() -> void:
	_auto_connect.call_deferred()


func host(port: int = -1, bind_address: String = "") -> Error:
	var mimic = _get_mimic()
	if mimic == null:
		return ERR_UNCONFIGURED
	return mimic.call("start_server", port, bind_address)


func join(address: String = "", port: int = -1) -> Error:
	var mimic = _get_mimic()
	if mimic == null:
		return ERR_UNCONFIGURED
	return mimic.call("start_client", address, port)


func stop() -> void:
	var mimic = _get_mimic()
	if mimic:
		mimic.call("stop")


func _auto_connect() -> void:
	if not is_inside_tree():
		return

	match auto_connect_mode:
		AutoConnectMode.SERVER:
			host()
		AutoConnectMode.CLIENT:
			join()
		AutoConnectMode.SERVER_IF_FIRST_ELSE_CLIENT:
			var mimic = _get_mimic()
			if mimic:
				mimic.call("start_server_if_first_else_client")


func _get_mimic():
	var mimic := get_node_or_null("/root/Mimic")
	if mimic == null:
		push_warning("Mimic autoload is missing.")
	return mimic
