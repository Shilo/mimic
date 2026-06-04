class_name MimicEditorAutoConnector extends Object
## Internal editor-only auto-connect dispatcher used by the Mimic autoload.
## [br][br]
## This class reads the editor auto-connect Project Setting and invokes the
## matching Mimic startup callable. Gameplay code should start networking through
## the [code]Mimic[/code] singleton instead.

const _TOOLING_ARGS := ["--doctool", "--import", "-s", "--script"]


## Attempts the configured editor auto-connect mode when the current run allows it.
static func try_start(
	is_inside_tree: bool,
	is_offline: bool,
	has_active_peer: bool,
	start_server_or_client: Callable,
	start_client: Callable,
	start_server: Callable,
	cmdline_args: PackedStringArray = PackedStringArray()
) -> void:
	if _is_tooling_run(cmdline_args):
		return
	if not is_inside_tree:
		return
	if not is_offline:
		return
	if has_active_peer:
		return

	var mode: Mimic.EditorAutoConnectMode = MimicProjectSettings.editor_auto_connect
	match mode:
		Mimic.EditorAutoConnectMode.SERVER_THEN_CLIENT:
			start_server_or_client.call()
		Mimic.EditorAutoConnectMode.CLIENT:
			start_client.call()
		Mimic.EditorAutoConnectMode.SERVER:
			start_server.call()


static func _is_tooling_run(cmdline_args: PackedStringArray = PackedStringArray()) -> bool:
	if cmdline_args.is_empty():
		cmdline_args = OS.get_cmdline_args()

	for argument in cmdline_args:
		if argument in _TOOLING_ARGS:
			return true

	return false
