extends MultiplayerSynchronizer
class_name MimicSync


func get_network_root() -> Node:
	return _resolve_network_root()


static func find_in(node: Node):
	if node is MimicSync:
		return node

	for child in node.get_children():
		var found = find_in(child)
		if found:
			return found

	return null


func _resolve_network_root() -> Node:
	if root_path.is_empty():
		return null
	return get_node_or_null(root_path)
