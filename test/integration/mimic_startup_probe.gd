extends Node

const EDITOR_AUTO_CONNECT := "mimic_multiplayer/connection/editor_auto_connect"

var _saved_editor_auto_connect_exists := false
var _saved_editor_auto_connect: Variant = null


func _ready() -> void:
	_saved_editor_auto_connect_exists = ProjectSettings.has_setting(EDITOR_AUTO_CONNECT)
	if _saved_editor_auto_connect_exists:
		_saved_editor_auto_connect = ProjectSettings.get_setting(EDITOR_AUTO_CONNECT)
	ProjectSettings.set_setting(EDITOR_AUTO_CONNECT, Mimic.EditorAutoConnectMode.DISABLED)
	_restore_editor_auto_connect_and_quit.call_deferred()


func _restore_editor_auto_connect_and_quit() -> void:
	if _saved_editor_auto_connect_exists:
		ProjectSettings.set_setting(EDITOR_AUTO_CONNECT, _saved_editor_auto_connect)
	elif ProjectSettings.has_setting(EDITOR_AUTO_CONNECT):
		ProjectSettings.clear(EDITOR_AUTO_CONNECT)

	get_tree().quit(0)
