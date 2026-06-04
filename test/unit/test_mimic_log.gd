extends GutTest

const MIMIC_SETTINGS := preload("res://test/unit/support/mimic_project_settings_test_support.gd")

var _captured_lines: Array[Dictionary] = []
var _saved_log_settings := {}


func before_each() -> void:
	_saved_log_settings = MIMIC_SETTINGS.save_settings([MIMIC_SETTINGS.LOG_LEVEL])
	_captured_lines.clear()
	MimicLog.output_handler = _capture_output


func after_each() -> void:
	MimicLog.output_handler = Callable()
	MIMIC_SETTINGS.restore_settings(_saved_log_settings)


func test_line_includes_stack_source_tag_when_available() -> void:
	var line := _make_logged_line_from_test()

	assert_string_contains(line, "[test_mimic_log._make_logged_line_from_test]")
	assert_false(line.contains("[Mimic]"))
	assert_string_contains(line, "hello 42")


func test_log_formats_message_with_source_tag() -> void:
	ProjectSettings.set_setting(MIMIC_SETTINGS.LOG_LEVEL, MimicLog.Level.ALL)

	_call_log()

	_assert_captured_line(MimicLog.Level.ALL, "[test_mimic_log._call_log]", "info 123")


func test_warning_formats_message_with_source_tag() -> void:
	ProjectSettings.set_setting(MIMIC_SETTINGS.LOG_LEVEL, MimicLog.Level.WARNING)

	_call_warning()

	_assert_captured_line(MimicLog.Level.WARNING, "[test_mimic_log._call_warning]", "warn 456")


func test_error_formats_message_with_source_tag() -> void:
	ProjectSettings.set_setting(MIMIC_SETTINGS.LOG_LEVEL, MimicLog.Level.ERROR)

	_call_error()

	_assert_captured_line(MimicLog.Level.ERROR, "[test_mimic_log._call_error]", "err 789")


func test_forced_log_formats_message_with_source_tag_when_logs_disabled() -> void:
	ProjectSettings.set_setting(MIMIC_SETTINGS.LOG_LEVEL, MimicLog.Level.NONE)

	_call_forced_log()

	_assert_captured_line(MimicLog.Level.ALL, "[test_mimic_log._call_forced_log]", "marker ok")


func test_forced_warning_formats_message_with_source_tag_when_logs_disabled() -> void:
	ProjectSettings.set_setting(MIMIC_SETTINGS.LOG_LEVEL, MimicLog.Level.NONE)

	_call_forced_warning()

	_assert_captured_line(
		MimicLog.Level.WARNING,
		"[test_mimic_log._call_forced_warning]",
		"setup warning"
	)


func test_forced_error_formats_message_with_source_tag_when_logs_disabled() -> void:
	ProjectSettings.set_setting(MIMIC_SETTINGS.LOG_LEVEL, MimicLog.Level.NONE)

	_call_forced_error()

	_assert_captured_line(
		MimicLog.Level.ERROR,
		"[test_mimic_log._call_forced_error]",
		"probe failure"
	)


func test_format_caller_name_uses_source_and_function() -> void:
	assert_eq(
		MimicLog._format_caller_name("res://addons/mimic/mimic.gd", "start_server"),
		"mimic.start_server"
	)
	assert_eq(MimicLog._format_caller_name("res://addons/mimic/mimic.gd", ""), "mimic")
	assert_eq(MimicLog._format_caller_name("", "anonymous"), "anonymous")
	assert_eq(MimicLog._format_caller_name("", ""), "")


func test_timestamp_is_wrapped_in_brackets() -> void:
	var timestamp := MimicLog._timestamp()

	assert_true(timestamp.begins_with("["))
	assert_true(timestamp.ends_with("]"))


func test_dim_wraps_text_in_color_tag_for_editor_output() -> void:
	assert_eq(
		MimicLog._dim("[01-02 03:04:05] [tag]"),
		"[color=#808080][01-02 03:04:05] [tag][/color]"
	)


func test_message_is_not_safe_for_print_rich_when_it_contains_opening_bracket() -> void:
	assert_true(MimicLog._message_is_safe_for_print_rich("plain message"))
	assert_true(MimicLog._message_is_safe_for_print_rich("plain message ]"))
	assert_false(MimicLog._message_is_safe_for_print_rich("[b]literal[/b]"))
	assert_false(MimicLog._message_is_safe_for_print_rich("value [1]"))


func test_editor_line_dims_prefix_for_plain_message() -> void:
	assert_eq(
		MimicLog._editor_line("[01-02 03:04:05] [tag]", "plain message"),
		"[color=#808080][01-02 03:04:05] [tag][/color] plain message"
	)


func test_editor_line_stays_plain_when_message_contains_opening_bracket() -> void:
	assert_eq(
		MimicLog._editor_line("[01-02 03:04:05] [tag]", "[b]literal[/b]"),
		"[01-02 03:04:05] [tag] [b]literal[/b]"
	)


func test_format_source_tag_uses_peer_id_prefix_when_available() -> void:
	assert_eq(
		MimicLog._format_source_tag("mimic._on_connected_to_server", 2),
		"[2 mimic._on_connected_to_server]"
	)
	assert_eq(MimicLog._format_source_tag("mimic._start_server", 0), "[mimic._start_server]")
	assert_eq(MimicLog._format_source_tag("", 2), "[2 Mimic]")


func _call_log() -> void:
	MimicLog.log("info", 123)


func _call_warning() -> void:
	MimicLog.warning("warn", 456)


func _call_error() -> void:
	MimicLog.error("err", 789)


func _call_forced_log() -> void:
	MimicLog.log_forced("marker", "ok")


func _call_forced_warning() -> void:
	MimicLog.warning_forced("setup", "warning")


func _call_forced_error() -> void:
	MimicLog.error_forced("probe", "failure")


func _capture_output(level: MimicLog.Level, message: String) -> void:
	_captured_lines.append({
		"level": level,
		"message": message,
	})


func _assert_captured_line(
	level: MimicLog.Level,
	source_tag: String,
	expected_message: String
) -> void:
	assert_eq(_captured_lines.size(), 1)
	if _captured_lines.is_empty():
		return

	var captured_line := _captured_lines[0]
	var message := String(captured_line["message"])
	assert_eq(captured_line["level"], level)
	_assert_timestamp_prefix(message)
	assert_string_contains(message, source_tag)
	assert_false(message.contains("[Mimic]"))
	assert_string_contains(message, expected_message)


func _assert_timestamp_prefix(line: String) -> void:
	assert_gt(line.length(), 17)
	if line.length() <= 17:
		return

	assert_eq(line.substr(0, 1), "[")
	assert_true(line.substr(1, 2).is_valid_int())
	assert_eq(line.substr(3, 1), "-")
	assert_true(line.substr(4, 2).is_valid_int())
	assert_eq(line.substr(6, 1), " ")
	assert_true(line.substr(7, 2).is_valid_int())
	assert_eq(line.substr(9, 1), ":")
	assert_true(line.substr(10, 2).is_valid_int())
	assert_eq(line.substr(12, 1), ":")
	assert_true(line.substr(13, 2).is_valid_int())
	assert_eq(line.substr(15, 1), "]")
	assert_eq(line.substr(16, 1), " ")


func _make_logged_line_from_test() -> String:
	return MimicLog._line(["hello", 42])
