class_name MimicSync extends MultiplayerSynchronizer
## Visible per-entity synchronization component for Mimic networked scenes.
## [br][br]
## MimicSync intentionally subclasses [MultiplayerSynchronizer] so developers
## can keep using Godot's native [SceneReplicationConfig] workflow.


## Returns the node resolved by this synchronizer's inherited [member root_path],
## or [code]null[/code] when [member root_path] is empty or fails to resolve.
func get_network_root() -> Node:
	return _resolve_network_root()


## Finds the first MimicSync in [param node] or any of its descendants.
static func find_in(node: Node) -> MimicSync:
	if node is MimicSync:
		return node

	for child in node.get_children():
		var found := find_in(child)
		if found:
			return found

	return null


func _resolve_network_root() -> Node:
	if root_path.is_empty():
		return null
	return get_node_or_null(root_path)
