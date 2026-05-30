class_name MimicLog extends Object
## Small logging wrapper used by Mimic connection helpers.
## [br][br]
## Messages are filtered by [member MimicProjectSettings.log_level] and include
## a compact timestamp. Editor-launched runs also include the local multiplayer
## ID when available so multi-instance logs are easier to distinguish.

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


## Prints an informational Mimic log message when the current log level allows it.
static func log(...objects: Array) -> void:
	if not _should_log(Level.ALL):
		return

	prints(_line(objects))


## Pushes a Mimic warning when the current log level allows it.
static func warning(...objects: Array) -> void:
	if not _should_log(Level.WARNING):
		return

	push_warning(_line(objects))


## Pushes a Mimic error when the current log level allows it.
static func error(...objects: Array) -> void:
	if not _should_log(Level.ERROR):
		return

	push_error(_line(objects))


static func _should_log(message_level: Level) -> bool:
	return MimicProjectSettings.log_level <= message_level


static func _line(objects: Array) -> String:
	var parts := PackedStringArray([_timestamp(), _get_name_tag()])

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
