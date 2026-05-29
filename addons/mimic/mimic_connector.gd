class_name MimicConnector extends CanvasLayer

enum AutoConnectMode { DISABLED, SERVER, CLIENT, SERVER_IF_FIRST_ELSE_CLIENT }

@export var auto_connect_mode: AutoConnectMode = AutoConnectMode.DISABLED


func _ready() -> void:
	_auto_connect.call_deferred()


func host(port: int = -1, bind_address: String = "") -> Error:
	return Mimic.start_server(port, bind_address)


func join(address: String = "", port: int = -1) -> Error:
	return Mimic.start_client(address, port)


func stop() -> void:
	Mimic.stop()


func _auto_connect() -> void:
	if not is_inside_tree():
		return

	match auto_connect_mode:
		AutoConnectMode.SERVER:
			host()
		AutoConnectMode.CLIENT:
			join()
		AutoConnectMode.SERVER_IF_FIRST_ELSE_CLIENT:
			Mimic.start_server_if_first_else_client()
