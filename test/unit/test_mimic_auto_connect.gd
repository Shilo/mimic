extends GutTest


func test_is_tooling_run_detects_tooling_arguments() -> void:
	assert_true(MimicAutoConnect.is_tooling_run(PackedStringArray(["--script"])))
	assert_true(MimicAutoConnect.is_tooling_run(PackedStringArray(["--import"])))
	assert_true(MimicAutoConnect.is_tooling_run(PackedStringArray(["--doctool"])))
	assert_true(MimicAutoConnect.is_tooling_run(PackedStringArray(["-s"])))
	assert_true(MimicAutoConnect.is_tooling_run(PackedStringArray(["--game", "--script"])))


func test_is_tooling_run_ignores_gameplay_arguments() -> void:
	assert_false(MimicAutoConnect.is_tooling_run(PackedStringArray(["--game"])))
	assert_false(MimicAutoConnect.is_tooling_run(PackedStringArray(["--position", "0,0"])))


func test_is_expected_host_failure_classifies_bind_errors() -> void:
	assert_true(MimicAutoConnect.is_expected_host_failure(ERR_ALREADY_IN_USE))
	assert_true(MimicAutoConnect.is_expected_host_failure(ERR_CANT_CREATE))
	assert_true(MimicAutoConnect.is_expected_host_failure(ERR_CANT_OPEN))
	assert_false(MimicAutoConnect.is_expected_host_failure(OK))
	assert_false(MimicAutoConnect.is_expected_host_failure(ERR_INVALID_PARAMETER))


func test_can_fallback_to_client_requires_expected_error_and_no_active_peer() -> void:
	assert_true(MimicAutoConnect.can_fallback_to_client(ERR_ALREADY_IN_USE, false))
	assert_false(MimicAutoConnect.can_fallback_to_client(ERR_ALREADY_IN_USE, true))
	assert_false(MimicAutoConnect.can_fallback_to_client(OK, false))
	assert_false(MimicAutoConnect.can_fallback_to_client(ERR_INVALID_PARAMETER, false))
