@tool
extends EditorPlugin
## Editor plugin that registers Mimic Project Settings and manages the Mimic autoload.

const _AUTOLOAD_NAME := "Mimic"


func _enter_tree() -> void:
	MimicProjectSettings.register()


func _exit_tree() -> void:
	MimicProjectSettings.unregister()


func _enable_plugin() -> void:
	# MimicRunInstanceGrid is optional for local testing and is not registered here.
	var autoload_status := _has_autoload()
	if autoload_status == OK:
		return

	if autoload_status == ERR_ALREADY_EXISTS:
		push_warning("Autoload '%s' already exists and does not point to this addon." % _AUTOLOAD_NAME)
		return

	add_autoload_singleton(_AUTOLOAD_NAME, _get_autoload_path())


func _disable_plugin() -> void:
	if _has_autoload() == OK:
		remove_autoload_singleton(_AUTOLOAD_NAME)


func _has_autoload() -> Error:
	if not ProjectSettings.has_setting("autoload/" + _AUTOLOAD_NAME):
		return ERR_DOES_NOT_EXIST

	var autoload_path := String(ProjectSettings.get_setting("autoload/" + _AUTOLOAD_NAME))
	if autoload_path.begins_with("*"):
		autoload_path = autoload_path.substr(1)
	autoload_path = ResourceUID.ensure_path(autoload_path)
	if autoload_path != _get_autoload_path():
		return ERR_ALREADY_EXISTS

	return OK


func _get_autoload_path() -> String:
	return get_script().resource_path.get_base_dir().path_join(_AUTOLOAD_NAME.to_lower() + ".gd")
