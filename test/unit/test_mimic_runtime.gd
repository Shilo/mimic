extends GutTest

const MIMIC_SETTINGS := preload("res://test/unit/support/mimic_project_settings_test_support.gd")
const MIMIC_TEST_PORTS := preload("res://test/unit/support/mimic_test_ports.gd")

var _saved_settings := {}


func before_each() -> void:
	Mimic.stop()
	_saved_settings = MIMIC_SETTINGS.save_settings()
	_configure_enet(_next_test_port())


func after_each() -> void:
	Mimic.stop()
	MIMIC_SETTINGS.restore_settings(_saved_settings)


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
	ProjectSettings.set_setting(MIMIC_SETTINGS.PORT, 0)

	var error := Mimic.start_server()

	assert_eq(error, ERR_PARAMETER_RANGE_ERROR)
	assert_true(Mimic.is_server())
	assert_eq(Mimic.get_state(), Mimic.NetworkState.SERVER_LISTENING)


func test_empty_client_address_fails_cleanly_and_emits_start_failed() -> void:
	watch_signals(Mimic)
	ProjectSettings.set_setting(MIMIC_SETTINGS.ADDRESS, "")

	var error := Mimic.start_client()

	assert_eq(error, ERR_INVALID_PARAMETER)
	assert_true(Mimic.is_offline())
	assert_signal_emitted_with_parameters(
		Mimic,
		"start_failed",
		[Mimic.NetworkState.CLIENT_CONNECTING, ERR_INVALID_PARAMETER, "Client address is empty."]
	)


func test_connector_does_not_start_networking_when_added() -> void:
	ProjectSettings.set_setting(
		MIMIC_SETTINGS.EDITOR_AUTO_CONNECT,
		Mimic.EditorAutoConnectMode.SERVER
	)
	add_child_autoqfree(MimicConnector.new())
	await wait_process_frames(2)

	assert_true(Mimic.is_offline())


func test_stop_is_noop_when_already_offline() -> void:
	watch_signals(Mimic)

	Mimic.stop()

	assert_signal_not_emitted(Mimic, "stopped")
	assert_true(Mimic.is_offline())


func test_mimic_sync_remains_a_multiplayer_synchronizer() -> void:
	var sync: MimicSync = autofree(MimicSync.new())

	assert_true(sync is MultiplayerSynchronizer)


func _configure_enet(port: int) -> void:
	ProjectSettings.set_setting(MIMIC_SETTINGS.TRANSPORT, Mimic.TransportType.ENET)
	ProjectSettings.set_setting(
		MIMIC_SETTINGS.EDITOR_AUTO_CONNECT,
		Mimic.EditorAutoConnectMode.DISABLED
	)
	ProjectSettings.set_setting(MIMIC_SETTINGS.ADDRESS, "127.0.0.1")
	ProjectSettings.set_setting(MIMIC_SETTINGS.PORT, port)
	ProjectSettings.set_setting(MIMIC_SETTINGS.PORT_FORWARDING_ENABLED, false)
	ProjectSettings.set_setting(MIMIC_SETTINGS.LOG_LEVEL, MimicLog.Level.NONE)


func _next_test_port() -> int:
	return MIMIC_TEST_PORTS.next_port()
