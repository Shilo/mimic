extends Node

const TRANSPORT := "mimic_multiplayer/connection/transport"
const ADDRESS := "mimic_multiplayer/connection/address"
const PORT := "mimic_multiplayer/connection/port"
const PORT_FORWARDING_ENABLED := "mimic_multiplayer/port_forwarding/enabled"
const LOG_LEVEL := "mimic_multiplayer/debug/log_level"

var _role := ""
var _address := "127.0.0.1"
var _port := 18910
var _timeout := 10.0
var _finished := false


func _ready() -> void:
	_parse_user_args()
	_configure_mimic()
	_connect_signals()
	get_tree().create_timer(_timeout).timeout.connect(_on_timeout)

	match _role:
		"server":
			_start_server()
		"client":
			_start_client()
		_:
			_fail("Unknown role '%s'. Use server or client." % _role)


func _parse_user_args() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--mimic-role="):
			_role = argument.trim_prefix("--mimic-role=")
		elif argument.begins_with("--mimic-address="):
			_address = argument.trim_prefix("--mimic-address=")
		elif argument.begins_with("--mimic-port="):
			_port = argument.trim_prefix("--mimic-port=").to_int()
		elif argument.begins_with("--mimic-timeout="):
			_timeout = argument.trim_prefix("--mimic-timeout=").to_float()


func _configure_mimic() -> void:
	ProjectSettings.set_setting(TRANSPORT, Mimic.TransportType.ENET)
	ProjectSettings.set_setting(ADDRESS, _address)
	ProjectSettings.set_setting(PORT, _port)
	ProjectSettings.set_setting(PORT_FORWARDING_ENABLED, false)
	ProjectSettings.set_setting(LOG_LEVEL, MimicLog.Level.NONE)
	Mimic.stop()


func _connect_signals() -> void:
	Mimic.peer_connected.connect(_on_peer_connected)
	Mimic.client_connected.connect(_on_client_connected)
	Mimic.client_connection_failed.connect(_on_client_connection_failed)
	Mimic.start_failed.connect(_on_start_failed)


func _start_server() -> void:
	var error := Mimic.start_server(_port, "127.0.0.1")
	if error != OK:
		_fail("Server start failed: %s." % error_string(error))
		return
	print("MIMIC_TEST_READY server port=%d" % _port)


func _start_client() -> void:
	var error := Mimic.start_client(_address, _port)
	if error != OK:
		_fail("Client start failed: %s." % error_string(error))
		return
	print("MIMIC_TEST_READY client port=%d" % _port)


func _on_peer_connected(peer_id: int) -> void:
	if _role == "server":
		print("MIMIC_TEST_CONNECTED server peer=%d" % peer_id)
		_succeed.call_deferred()


func _on_client_connected() -> void:
	if _role == "client":
		print("MIMIC_TEST_CONNECTED client peer=%d" % Mimic.get_local_peer_id())
		_succeed.call_deferred()


func _on_client_connection_failed(message: String) -> void:
	if _role == "client":
		_fail(message)


func _on_start_failed(_state: int, error: int, message: String) -> void:
	_fail("%s (%s)." % [message, error_string(error)])


func _on_timeout() -> void:
	_fail("Timed out after %.2f seconds waiting for %s connection." % [_timeout, _role])


func _succeed() -> void:
	if _finished:
		return
	_finished = true
	await get_tree().create_timer(0.25).timeout
	Mimic.stop()
	get_tree().quit(0)


func _fail(message: String) -> void:
	if _finished:
		return
	_finished = true
	print("MIMIC_TEST_FAILED %s %s" % [_role, message])
	push_error(message)
	Mimic.stop()
	get_tree().quit(1)
