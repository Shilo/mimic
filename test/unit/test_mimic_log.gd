extends GutTest

const LOG_LEVEL := "mimic_multiplayer/debug/log_level"

var _captured_lines: Array[Dictionary] = []
var _saved_log_level_exists := false
var _saved_log_level: Variant = null


func before_each() -> void:
	_save_log_level()
	_captured_lines.clear()
	MimicLog._output_override = _capture_output


func after_each() -> void:
	MimicLog._output_override = Callable()
	_restore_log_level()


func test_line_includes_stack_caller_tag_when_available() -> void:
	var line := _make_logged_line_from_test()

	assert_string_contains(line, "[test_mimic_log._make_logged_line_from_test]")
	assert_string_contains(line, "hello 42")


func test_log_formats_message_with_caller_tag() -> void:
	ProjectSettings.set_setting(LOG_LEVEL, MimicLog.Level.ALL)

	_call_log()

	_assert_captured_line("log", "[test_mimic_log._call_log]", "info 123")


func test_warning_formats_message_with_caller_tag() -> void:
	ProjectSettings.set_setting(LOG_LEVEL, MimicLog.Level.WARNING)

	_call_warning()

	_assert_captured_line("warning", "[test_mimic_log._call_warning]", "warn 456")


func test_error_formats_message_with_caller_tag() -> void:
	ProjectSettings.set_setting(LOG_LEVEL, MimicLog.Level.ERROR)

	_call_error()

	_assert_captured_line("error", "[test_mimic_log._call_error]", "err 789")


func test_unfiltered_log_formats_message_with_caller_tag_when_logs_disabled() -> void:
	ProjectSettings.set_setting(LOG_LEVEL, MimicLog.Level.NONE)

	_call_unfiltered_log()

	_assert_captured_line("log", "[test_mimic_log._call_unfiltered_log]", "marker ok")


func test_format_caller_tag_uses_source_and_function() -> void:
	assert_eq(MimicLog._format_caller_tag("res://addons/mimic/mimic.gd", "start_server"), "[mimic.start_server]")
	assert_eq(MimicLog._format_caller_tag("res://addons/mimic/mimic.gd", ""), "[mimic]")
	assert_eq(MimicLog._format_caller_tag("", "anonymous"), "[anonymous]")
	assert_eq(MimicLog._format_caller_tag("", ""), "")


func _call_log() -> void:
	MimicLog.log("info", 123)


func _call_warning() -> void:
	MimicLog.warning("warn", 456)


func _call_error() -> void:
	MimicLog.error("err", 789)


func _call_unfiltered_log() -> void:
	MimicLog._log_unfiltered("marker", "ok")


func _capture_output(level_name: String, line: String) -> void:
	_captured_lines.append({
		"level": level_name,
		"line": line,
	})


func _assert_captured_line(level_name: String, caller_tag: String, message: String) -> void:
	assert_eq(_captured_lines.size(), 1)
	if _captured_lines.is_empty():
		return

	var captured_line := _captured_lines[0]
	var line := String(captured_line["line"])
	assert_eq(captured_line["level"], level_name)
	_assert_timestamp_prefix(line)
	assert_string_contains(line, "[Mimic]")
	assert_string_contains(line, caller_tag)
	assert_string_contains(line, message)


func _assert_timestamp_prefix(line: String) -> void:
	assert_gt(line.length(), 15)
	if line.length() <= 15:
		return

	assert_true(line.substr(0, 2).is_valid_int())
	assert_eq(line.substr(2, 1), "-")
	assert_true(line.substr(3, 2).is_valid_int())
	assert_eq(line.substr(5, 1), " ")
	assert_true(line.substr(6, 2).is_valid_int())
	assert_eq(line.substr(8, 1), ":")
	assert_true(line.substr(9, 2).is_valid_int())
	assert_eq(line.substr(11, 1), ":")
	assert_true(line.substr(12, 2).is_valid_int())
	assert_eq(line.substr(14, 1), " ")


func _make_logged_line_from_test() -> String:
	return MimicLog._line(["hello", 42])


func _save_log_level() -> void:
	_saved_log_level_exists = ProjectSettings.has_setting(LOG_LEVEL)
	if _saved_log_level_exists:
		_saved_log_level = ProjectSettings.get_setting(LOG_LEVEL)


func _restore_log_level() -> void:
	if _saved_log_level_exists:
		ProjectSettings.set_setting(LOG_LEVEL, _saved_log_level)
	elif ProjectSettings.has_setting(LOG_LEVEL):
		ProjectSettings.clear(LOG_LEVEL)
