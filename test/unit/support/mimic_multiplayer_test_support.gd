extends RefCounted


static func create_multiplayer_root(
	owner: Node,
	root_label: String,
	roots: Array[Node],
	multiplayer_apis: Array[SceneMultiplayer]
) -> Dictionary:
	var root := Node.new()
	root.name = "%s%d" % [root_label, roots.size()]
	owner.add_child(root)

	var multiplayer_api := SceneMultiplayer.new()
	owner.get_tree().set_multiplayer(multiplayer_api, root.get_path())
	roots.append(root)
	multiplayer_apis.append(multiplayer_api)

	return {
		"root": root,
		"multiplayer_api": multiplayer_api,
	}


static func cleanup_multiplayer_roots(
	owner: Node,
	roots: Array[Node],
	multiplayer_apis: Array[SceneMultiplayer]
) -> void:
	for multiplayer_api in multiplayer_apis:
		if multiplayer_api.multiplayer_peer != null:
			multiplayer_api.multiplayer_peer.close()
	multiplayer_apis.clear()

	for root in roots:
		if is_instance_valid(root):
			owner.get_tree().set_multiplayer(null, root.get_path())
			root.free()
	roots.clear()
