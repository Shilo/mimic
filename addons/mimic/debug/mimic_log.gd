class_name MimicLog extends Object
## Small logging wrapper used by Mimic connection helpers.
## [br][br]
## Messages are filtered by [member MimicProjectSettings.log_level] and include
## a compact timestamp. Editor-launched runs also include the local multiplayer
## ID when available so multi-instance logs are easier to distinguish. When
## GDScript call stacks are available, each line also includes the source method
## that called MimicLog.

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

## Optional handler for formatted Mimic output.
## [br][br]
## When set to a valid [Callable], MimicLog sends output to this handler instead of
## calling Godot's default [method @GlobalScope.prints],
## [method @GlobalScope.push_warning], or [method @GlobalScope.push_error].
## The callable receives [code](level: MimicLog.Level, message: String)[/code],
## where [code]message[/code] is the fully formatted log line.
static var output_handler: Callable = Callable()


## Prints an informational Mimic log message when the current log level allows it.
static func log(...objects: Array) -> void:
	if not _should_log(Level.ALL):
		return

	_print_line(_line(objects))


## Pushes a Mimic warning when the current log level allows it.
static func warning(...objects: Array) -> void:
	if not _should_log(Level.WARNING):
		return

	_push_warning_line(_line(objects))


## Pushes a Mimic error when the current log level allows it.
static func error(...objects: Array) -> void:
	if not _should_log(Level.ERROR):
		return

	_push_error_line(_line(objects))


## Prints an informational Mimic log message without checking the configured log level.
static func log_forced(...objects: Array) -> void:
	_print_line(_line(objects))


## Pushes a Mimic warning without checking the configured log level.
static func warning_forced(...objects: Array) -> void:
	_push_warning_line(_line(objects))


## Pushes a Mimic error without checking the configured log level.
static func error_forced(...objects: Array) -> void:
	_push_error_line(_line(objects))


static func _should_log(message_level: Level) -> bool:
	return MimicProjectSettings.log_level <= message_level


static func _line(objects: Array) -> String:
	var parts := PackedStringArray([_timestamp(), _get_name_tag()])
	var caller_tag := _get_caller_tag()
	if not caller_tag.is_empty():
		parts.append(caller_tag)

	var message := _join(objects)
	if not message.is_empty():
		parts.append(message)

	return " ".join(parts)


static func _get_name_tag() -> String:
	const NAME := "Mimic"

	if not _is_editor_feature:
		return "[%s]" % NAME

	var peer_id := _get_local_peer_id()
	if peer_id <= 0:
		return "[%s]" % NAME
	return "[%s %d]" % [NAME, peer_id]


static func _get_caller_tag() -> String:
	for frame in get_stack():
		var source := String(frame.get("source", ""))
		if source.get_file() == "mimic_log.gd":
			continue

		return _format_caller_tag(source, String(frame.get("function", "")))

	return ""


static func _format_caller_tag(source: String, function_name: String) -> String:
	var source_name := source.get_file().get_basename()
	if source_name.is_empty():
		return "[%s]" % function_name if not function_name.is_empty() else ""
	if function_name.is_empty():
		return "[%s]" % source_name
	return "[%s.%s]" % [source_name, function_name]


static func _timestamp() -> String:
	var datetime := Time.get_datetime_dict_from_system()
	return "%02d-%02d %02d:%02d:%02d" % [
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


static func _print_line(line: String) -> void:
	if output_handler.is_valid():
		output_handler.call(Level.ALL, line)
		return

	prints(line)


static func _push_warning_line(line: String) -> void:
	if output_handler.is_valid():
		output_handler.call(Level.WARNING, line)
		return

	push_warning(line)


static func _push_error_line(line: String) -> void:
	if output_handler.is_valid():
		output_handler.call(Level.ERROR, line)
		return

	push_error(line)
