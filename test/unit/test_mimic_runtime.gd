extends GutTest

const TRANSPORT := "mimic_multiplayer/connection/transport"
const ADDRESS := "mimic_multiplayer/connection/address"
const PORT := "mimic_multiplayer/connection/port"
const PORT_FORWARDING_ENABLED := "mimic_multiplayer/port_forwarding/enabled"
const LOG_LEVEL := "mimic_multiplayer/debug/log_level"

var _saved_settings := {}
var _next_port := 19100


func before_each() -> void:
	Mimic.stop()
	_save_settings()
	_configure_enet(_next_test_port())


func after_each() -> void:
	Mimic.stop()
	_restore_settings()


func test_start_server_sets_public_state_and_peer_helpers() -> void:
	var port := _next_test_port()

	var error := Mimic.start_server(port, "127.0.0.1")

	assert_eq(error, OK)
	assert_true(Mimic.is_server())
	assert_false(Mimic.is_client())
	assert_false(Mimic.is_connecting())
	assert_false(Mimic.is_offline())
	assert_eq(Mimic.get_state(), Mimic.NetworkState.SERVER_LISTENING)
	assert_eq(Mimic.get_local_peer_id(), 1)
	assert_eq(Mimic.get_peer_ids().size(), 0)


func test_invalid_server_start_does_not_stop_existing_server() -> void:
	var port := _next_test_port()
	assert_eq(Mimic.start_server(port, "127.0.0.1"), OK)
	ProjectSettings.set_setting(PORT, 0)

	var error := Mimic.start_server()

	assert_eq(error, ERR_PARAMETER_RANGE_ERROR)
	assert_true(Mimic.is_server())
	assert_eq(Mimic.get_state(), Mimic.NetworkState.SERVER_LISTENING)


func test_empty_client_address_fails_cleanly_and_emits_start_failed() -> void:
	watch_signals(Mimic)
	ProjectSettings.set_setting(ADDRESS, "")

	var error := Mimic.start_client()

	assert_eq(error, ERR_INVALID_PARAMETER)
	assert_true(Mimic.is_offline())
	assert_signal_emitted_with_parameters(
		Mimic,
		"start_failed",
		[Mimic.NetworkState.CLIENT_CONNECTING, ERR_INVALID_PARAMETER, "Client address is empty."]
	)


func test_connector_host_and_stop_forward_to_mimic() -> void:
	var connector: MimicConnector = add_child_autoqfree(MimicConnector.new())
	var port := _next_test_port()

	var error: Error = connector.host(port, "127.0.0.1")

	assert_eq(error, OK)
	assert_true(Mimic.is_server())

	connector.stop()

	assert_true(Mimic.is_offline())


func test_stop_is_noop_when_already_offline() -> void:
	var stopped_count := 0
	Mimic.stopped.connect(
		func() -> void:
			stopped_count += 1
	)

	Mimic.stop()

	assert_eq(stopped_count, 0)
	assert_true(Mimic.is_offline())


func test_mimic_sync_remains_a_multiplayer_synchronizer() -> void:
	var sync: MimicSync = autofree(MimicSync.new())

	assert_true(sync is MultiplayerSynchronizer)


func _configure_enet(port: int) -> void:
	ProjectSettings.set_setting(TRANSPORT, Mimic.TransportType.ENET)
	ProjectSettings.set_setting(ADDRESS, "127.0.0.1")
	ProjectSettings.set_setting(PORT, port)
	ProjectSettings.set_setting(PORT_FORWARDING_ENABLED, false)
	ProjectSettings.set_setting(LOG_LEVEL, MimicLog.Level.NONE)


func _next_test_port() -> int:
	_next_port += 1
	return _next_port


func _save_settings() -> void:
	for setting_name in [TRANSPORT, ADDRESS, PORT, PORT_FORWARDING_ENABLED, LOG_LEVEL]:
		_saved_settings[setting_name] = {
			"exists": ProjectSettings.has_setting(setting_name),
			"value": ProjectSettings.get_setting(setting_name),
		}


func _restore_settings() -> void:
	for setting_name in _saved_settings:
		var saved_setting: Dictionary = _saved_settings[setting_name]
		if bool(saved_setting["exists"]):
			ProjectSettings.set_setting(setting_name, saved_setting["value"])
		elif ProjectSettings.has_setting(setting_name):
			ProjectSettings.clear(setting_name)
