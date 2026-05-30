@icon("res://addons/mimic/icon.svg")
class_name MimicConnector extends CanvasLayer
## Scene component that starts and stops Mimic connections.
## [br][br]
## Add this to a startup scene when you want inspector-driven auto-connect or a
## simple script target for host/join/stop UI buttons.

## Controls what the connector does automatically on ready.
enum AutoConnectMode {
	## Do nothing automatically.
	DISABLED,
	## Start a server automatically.
	SERVER,
	## Start a client automatically.
	CLIENT,
	## Try server mode first, then join as a client on expected local hosting failures.
	SERVER_IF_FIRST_ELSE_CLIENT,
}

## Connection action to run automatically when this node enters the scene tree.
@export var auto_connect_mode: AutoConnectMode = AutoConnectMode.DISABLED


func _ready() -> void:
	_auto_connect.call_deferred()


## Starts a server through the Mimic singleton.
## [br][br]
## Pass [code]-1[/code] and an empty bind address to use Project Settings.
func host(port: int = -1, bind_address: String = "") -> Error:
	return Mimic.start_server(port, bind_address)


## Starts a client connection through the Mimic singleton.
## [br][br]
## Pass an empty address and [code]-1[/code] to use Project Settings.
func join(address: String = "", port: int = -1) -> Error:
	return Mimic.start_client(address, port)


## Stops networking through the Mimic singleton.
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
