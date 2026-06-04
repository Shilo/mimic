extends Node

const TRANSPORT := "mimic_multiplayer/connection/transport"
const EDITOR_AUTO_CONNECT := "mimic_multiplayer/connection/editor_auto_connect"
const ADDRESS := "mimic_multiplayer/connection/address"
const PORT := "mimic_multiplayer/connection/port"
const PORT_FORWARDING_ENABLED := "mimic_multiplayer/port_forwarding/enabled"
const LOG_LEVEL := "mimic_multiplayer/debug/log_level"

var _role := ""
var _transport := "enet"
var _address := "127.0.0.1"
var _port := 18_910
var _timeout := 10.0
var _finished := false
var _saved_editor_auto_connect_exists := false
var _saved_editor_auto_connect: Variant = null


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
		"auto":
			_finish_project_editor_auto_connect.call_deferred()
		_:
			_fail("Unknown role '%s'. Use server, client, or auto." % _role)


func _parse_user_args() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--mimic-role="):
			_role = argument.trim_prefix("--mimic-role=")
		elif argument.begins_with("--mimic-transport="):
			_transport = argument.trim_prefix("--mimic-transport=").to_lower()
		elif argument.begins_with("--mimic-address="):
			_address = argument.trim_prefix("--mimic-address=")
		elif argument.begins_with("--mimic-port="):
			_port = argument.trim_prefix("--mimic-port=").to_int()
		elif argument.begins_with("--mimic-timeout="):
			_timeout = argument.trim_prefix("--mimic-timeout=").to_float()


func _configure_mimic() -> void:
	_saved_editor_auto_connect_exists = ProjectSettings.has_setting(EDITOR_AUTO_CONNECT)
	if _saved_editor_auto_connect_exists:
		_saved_editor_auto_connect = ProjectSettings.get_setting(EDITOR_AUTO_CONNECT)

	ProjectSettings.set_setting(TRANSPORT, _get_transport_type())
	var editor_auto_connect := (
		Mimic.EditorAutoConnectMode.SERVER_THEN_CLIENT
		if _role == "auto"
		else Mimic.EditorAutoConnectMode.DISABLED
	)
	ProjectSettings.set_setting(EDITOR_AUTO_CONNECT, editor_auto_connect)
	ProjectSettings.set_setting(ADDRESS, _address)
	ProjectSettings.set_setting(PORT, _port)
	ProjectSettings.set_setting(PORT_FORWARDING_ENABLED, false)
	ProjectSettings.set_setting(LOG_LEVEL, MimicLog.Level.NONE)
	Mimic.stop()


func _get_transport_type() -> int:
	match _transport:
		"enet":
			return Mimic.TransportType.ENET
		"websocket":
			return Mimic.TransportType.WEBSOCKET
		_:
			_fail("Unknown transport '%s'. Use enet or websocket." % _transport)
	return Mimic.TransportType.OFFLINE


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
	MimicLog.log_forced("MIMIC_TEST_READY server transport=%s port=%d" % [_transport, _port])


func _start_client() -> void:
	var error := Mimic.start_client(_address, _port)
	if error != OK:
		_fail("Client start failed: %s." % error_string(error))
		return
	MimicLog.log_forced("MIMIC_TEST_READY client transport=%s port=%d" % [_transport, _port])


func _finish_project_editor_auto_connect() -> void:
	await get_tree().process_frame

	if Mimic.is_server():
		_role = "server"
		MimicLog.log_forced("MIMIC_TEST_READY server transport=%s port=%d" % [_transport, _port])
	elif Mimic.is_connecting() or Mimic.is_client():
		_role = "client"
		MimicLog.log_forced("MIMIC_TEST_READY client transport=%s port=%d" % [_transport, _port])
		if Mimic.is_client():
			_on_client_connected.call_deferred()
	else:
		_fail("Auto-connect entered unexpected state %d." % Mimic.get_state())


func _on_peer_connected(peer_id: int) -> void:
	if _role == "server":
		MimicLog.log_forced(
			"MIMIC_TEST_CONNECTED server transport=%s peer=%d" % [_transport, peer_id]
		)
		_succeed.call_deferred()


func _on_client_connected() -> void:
	if _role == "client":
		MimicLog.log_forced(
			"MIMIC_TEST_CONNECTED client transport=%s peer=%d"
			% [_transport, Mimic.get_local_peer_id()]
		)
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
	_restore_editor_auto_connect()
	get_tree().quit(0)


func _fail(message: String) -> void:
	if _finished:
		return
	_finished = true
	MimicLog.log_forced("MIMIC_TEST_FAILED %s %s" % [_role, message])
	MimicLog.error_forced(message)
	Mimic.stop()
	_restore_editor_auto_connect()
	get_tree().quit(1)


func _restore_editor_auto_connect() -> void:
	if _saved_editor_auto_connect_exists:
		ProjectSettings.set_setting(EDITOR_AUTO_CONNECT, _saved_editor_auto_connect)
	elif ProjectSettings.has_setting(EDITOR_AUTO_CONNECT):
		ProjectSettings.clear(EDITOR_AUTO_CONNECT)
