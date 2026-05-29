extends MultiplayerSynchronizer
class_name MimicSync

var _network_root: Node


func _enter_tree() -> void:
	_network_root = _resolve_network_root()
	var mimic := get_node_or_null("/root/Mimic")
	if mimic:
		mimic.register_sync(self)


func _exit_tree() -> void:
	var mimic := get_node_or_null("/root/Mimic")
	if mimic:
		mimic.unregister_sync(self, _network_root)
	_network_root = null


func get_network_root() -> Node:
	if is_instance_valid(_network_root):
		return _network_root
	return null


static func find_in(node: Node):
	var script := node.get_script()
	while script is Script:
		if script.resource_path == "res://addons/mimic/mimic_sync.gd":
			return node
		script = script.get_base_script()

	for child in node.get_children():
		var found = find_in(child)
		if found:
			return found

	return null


func _resolve_network_root() -> Node:
	if root_path.is_empty():
		return null
	return get_node_or_null(root_path)
