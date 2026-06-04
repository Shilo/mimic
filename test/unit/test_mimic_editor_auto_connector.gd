extends GutTest

const MIMIC_SETTINGS := preload("res://test/unit/support/mimic_project_settings_test_support.gd")

var _calls: Array[String] = []
var _saved_settings := {}


func before_each() -> void:
	_saved_settings = MIMIC_SETTINGS.save_settings()
	_calls.clear()
	ProjectSettings.set_setting(
		MIMIC_SETTINGS.EDITOR_AUTO_CONNECT,
		Mimic.EditorAutoConnectMode.DISABLED
	)


func after_each() -> void:
	MIMIC_SETTINGS.restore_settings(_saved_settings)


func test_try_start_dispatches_server_then_client_mode() -> void:
	ProjectSettings.set_setting(
		MIMIC_SETTINGS.EDITOR_AUTO_CONNECT,
		Mimic.EditorAutoConnectMode.SERVER_THEN_CLIENT
	)

	_try_start()

	assert_eq(_calls, ["server_or_client"])


func test_try_start_dispatches_client_mode() -> void:
	ProjectSettings.set_setting(
		MIMIC_SETTINGS.EDITOR_AUTO_CONNECT,
		Mimic.EditorAutoConnectMode.CLIENT
	)

	_try_start()

	assert_eq(_calls, ["client"])


func test_try_start_dispatches_server_mode() -> void:
	ProjectSettings.set_setting(
		MIMIC_SETTINGS.EDITOR_AUTO_CONNECT,
		Mimic.EditorAutoConnectMode.SERVER
	)

	_try_start()

	assert_eq(_calls, ["server"])


func test_try_start_skips_disabled_mode() -> void:
	_try_start()

	assert_true(_calls.is_empty())


func test_try_start_skips_tooling_runs() -> void:
	ProjectSettings.set_setting(
		MIMIC_SETTINGS.EDITOR_AUTO_CONNECT,
		Mimic.EditorAutoConnectMode.SERVER
	)

	_try_start(PackedStringArray(["--script"]))

	assert_true(_calls.is_empty())


func test_try_start_skips_when_context_is_not_startable() -> void:
	ProjectSettings.set_setting(
		MIMIC_SETTINGS.EDITOR_AUTO_CONNECT,
		Mimic.EditorAutoConnectMode.SERVER
	)

	_try_start(PackedStringArray(["--game"]), false, true, false)
	_try_start(PackedStringArray(["--game"]), true, false, false)
	_try_start(PackedStringArray(["--game"]), true, true, true)

	assert_true(_calls.is_empty())


func _try_start(
	cmdline_args: PackedStringArray = PackedStringArray(["--game"]),
	is_inside_tree: bool = true,
	is_offline: bool = true,
	has_active_peer: bool = false
) -> void:
	MimicEditorAutoConnector.try_start(
		is_inside_tree,
		is_offline,
		has_active_peer,
		_record_call.bind("server_or_client"),
		_record_call.bind("client"),
		_record_call.bind("server"),
		cmdline_args
	)


func _record_call(label: String) -> void:
	_calls.append(label)
