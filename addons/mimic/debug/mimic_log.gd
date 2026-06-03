class_name MimicLog extends Object
## Small logging wrapper used by Mimic connection helpers.
## [br][br]
## Messages are filtered by [member MimicProjectSettings.log_level] and are prefixed
## with a bracketed timestamp and a source tag. When GDScript call stacks are available,
## the source tag names the method that called MimicLog. Editor-launched runs also
## include the local multiplayer ID when available so multi-instance logs are
## easier to distinguish.
## [br][br]
## On the default print path the prefix is dimmed with a [code][color][/code] tag via
## [method @GlobalScope.print_rich] so the timestamp and tag read as secondary to the
## message. Godot renders this markup in the editor Output panel and strips it from saved
## log files, so log files stay plain text. Informational log lines with message text
## that could be parsed as BBCode use plain output instead so the message remains
## literal. Warnings, errors, and any custom [member output_handler] receive the plain
## prefix without color markup.

## Output levels available for Mimic logs.
enum Level {
	## Print all Mimic log, warning, and error messages.
	ALL,
	## Print warnings and errors.
	WARNING,
	## Print only errors.
	ERROR,
	## Disable Mimic log output.
	NONE,
}

static var _is_editor_feature := OS.has_feature("editor")

# BBCode color applied to the timestamp and source tag prefix on the editor print path.
const _PREFIX_COLOR := "#808080"

## Optional handler for formatted Mimic output.
## [br][br]
## When set to a valid [Callable], MimicLog sends output to this handler instead of
## calling Godot's default print methods,
## [method @GlobalScope.push_warning], or [method @GlobalScope.push_error].
## The callable receives [code](level: MimicLog.Level, message: String)[/code],
## where [code]message[/code] is the fully formatted log line without editor color markup.
static var output_handler: Callable = Callable()


## Prints an informational Mimic log message when the current log level allows it.
static func log(...objects: Array) -> void:
	if not _should_log(Level.ALL):
		return

	_print_line(_prefix(), _join(objects))


## Pushes a Mimic warning when the current log level allows it.
static func warning(...objects: Array) -> void:
	if not _should_log(Level.WARNING):
		return

	_push_warning_line(_prefix(), _join(objects))


## Pushes a Mimic error when the current log level allows it.
static func error(...objects: Array) -> void:
	if not _should_log(Level.ERROR):
		return

	_push_error_line(_prefix(), _join(objects))


## Prints an informational Mimic log message without checking the configured log level.
static func log_forced(...objects: Array) -> void:
	_print_line(_prefix(), _join(objects))


## Pushes a Mimic warning without checking the configured log level.
static func warning_forced(...objects: Array) -> void:
	_push_warning_line(_prefix(), _join(objects))


## Pushes a Mimic error without checking the configured log level.
static func error_forced(...objects: Array) -> void:
	_push_error_line(_prefix(), _join(objects))


static func _should_log(message_level: Level) -> bool:
	return MimicProjectSettings.log_level <= message_level


static func _line(objects: Array) -> String:
	return _compose(_prefix(), _join(objects))


static func _prefix() -> String:
	return "%s %s" % [_timestamp(), _get_source_tag()]


static func _compose(prefix: String, message: String) -> String:
	if message.is_empty():
		return prefix
	return "%s %s" % [prefix, message]


static func _dim(text: String) -> String:
	return "[color=%s]%s[/color]" % [_PREFIX_COLOR, text]


static func _message_is_safe_for_print_rich(message: String) -> bool:
	return not message.contains("[")


static func _editor_line(prefix: String, message: String) -> String:
	if _message_is_safe_for_print_rich(message):
		return _compose(_dim(prefix), message)
	return _compose(prefix, message)


static func _get_source_tag() -> String:
	var caller_name := _get_caller_name()
	if _is_editor_feature:
		return _format_source_tag(caller_name, _get_local_peer_id())

	return _format_source_tag(caller_name, 0)


static func _format_source_tag(caller_name: String, peer_id: int) -> String:
	if caller_name.is_empty():
		caller_name = "Mimic"
	if peer_id > 0:
		return "[%d %s]" % [peer_id, caller_name]
	return "[%s]" % caller_name


static func _get_caller_name() -> String:
	for frame in get_stack():
		var source := String(frame.get("source", ""))
		if source.get_file() == "mimic_log.gd":
			continue

		return _format_caller_name(source, String(frame.get("function", "")))

	return ""


static func _format_caller_name(source: String, function_name: String) -> String:
	var source_name := source.get_file().get_basename()
	if source_name.is_empty():
		return function_name
	if function_name.is_empty():
		return source_name
	return "%s.%s" % [source_name, function_name]


static func _timestamp() -> String:
	var datetime := Time.get_datetime_dict_from_system()
	return "[%02d-%02d %02d:%02d:%02d]" % [
		datetime["month"],
		datetime["day"],
		datetime["hour"],
		datetime["minute"],
		datetime["second"],
	]


static func _get_local_peer_id() -> int:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return 0

	var multiplayer_api := tree.get_multiplayer()
	if multiplayer_api == null or not multiplayer_api.has_multiplayer_peer():
		return 0

	var peer := multiplayer_api.multiplayer_peer
	if peer == null or peer is OfflineMultiplayerPeer:
		return 0
	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return 0

	return multiplayer_api.get_unique_id()


static func _join(objects: Array) -> String:
	if objects.is_empty():
		return ""
	if objects.size() == 1:
		return str(objects[0])

	var parts := PackedStringArray()
	parts.resize(objects.size())
	for index in range(objects.size()):
		parts[index] = str(objects[index])
	return " ".join(parts)


static func _print_line(prefix: String, message: String) -> void:
	var line := _compose(prefix, message)
	if output_handler.is_valid():
		output_handler.call(Level.ALL, line)
		return

	if _is_editor_feature:
		var editor_line := _editor_line(prefix, message)
		if _message_is_safe_for_print_rich(message):
			print_rich(editor_line)
		else:
			prints(editor_line)
		return

	prints(line)


static func _push_warning_line(prefix: String, message: String) -> void:
	var line := _compose(prefix, message)
	if output_handler.is_valid():
		output_handler.call(Level.WARNING, line)
		return

	push_warning(line)


static func _push_error_line(prefix: String, message: String) -> void:
	var line := _compose(prefix, message)
	if output_handler.is_valid():
		output_handler.call(Level.ERROR, line)
		return

	push_error(line)
