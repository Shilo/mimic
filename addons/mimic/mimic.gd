extends Node

const MIMIC_SYNC_SCRIPT := preload("res://addons/mimic/mimic_sync.gd")

var _next_dynamic_id := 1
var _nodes_by_id := {}
var _ids_by_instance := {}
var _active_spawn_payloads := {}
var _pending_spawn_payloads := []
var _remote_spawning := false
var _remote_spawn_id := ""
var _remote_spawn_root_instance_id := 0


func _ready() -> void:
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
	set_process(false)


func register_sync(sync) -> void:
	var root: Node = sync.get_network_root()
	if root == null:
		return

	if _remote_spawning:
		if not _remote_spawn_id.is_empty() and root.get_instance_id() == _remote_spawn_root_instance_id:
			_track(root, _remote_spawn_id)
		return

	if _ids_by_instance.has(root.get_instance_id()):
		return
	if _has_tracked_ancestor(root):
		return
	if not _is_server():
		return

	if not root.is_node_ready():
		root.ready.connect(_register_when_ready.bind(sync, root), CONNECT_ONE_SHOT)
		return

	_register_later(sync, root)


func unregister_sync(_sync, root: Node) -> void:
	if root == null or (root.is_inside_tree() and not root.is_queued_for_deletion()):
		return

	_unregister_tracked_instance(root.get_instance_id())


func _register_when_ready(sync, root: Node) -> void:
	if not is_instance_valid(sync) or not is_instance_valid(root):
		return
	if not sync.is_inside_tree() or not root.is_inside_tree():
		return
	if sync.get_network_root() != root:
		return
	_register_later(sync, root)


func _register_later(sync, root: Node) -> void:
	call_deferred("_register_if_valid", sync, root)


func _register_if_valid(sync, root: Node) -> void:
	if not is_instance_valid(sync) or not is_instance_valid(root):
		return
	if not sync.is_inside_tree() or not root.is_inside_tree():
		return
	if sync.get_network_root() != root:
		return
	if _ids_by_instance.has(root.get_instance_id()):
		return
	if _has_tracked_ancestor(root):
		return
	if _is_server():
		_register_dynamic(sync, root)


func _register_dynamic(sync, root: Node) -> void:
	var payload := _make_spawn_payload(str(_next_dynamic_id), sync, root)
	if payload.is_empty():
		return

	var mimic_id := String(payload["id"])
	_next_dynamic_id += 1
	_track(root, mimic_id)
	_active_spawn_payloads[mimic_id] = payload

	if multiplayer.has_multiplayer_peer():
		rpc("_spawn_remote", payload)


func _make_spawn_payload(mimic_id: String, sync, root: Node) -> Dictionary:
	var scene_path := root.scene_file_path
	if scene_path.is_empty() or not scene_path.ends_with(".tscn"):
		push_warning("MimicSync root must be an instanced .tscn scene root.")
		return {}

	var parent := root.get_parent()
	if parent == null:
		push_warning("MimicSync root needs a parent that also exists on remote peers.")
		return {}

	return {
		"id": mimic_id,
		"scene_path": scene_path,
		"parent_path": String(parent.get_path()),
		"name": String(root.name),
		"spawn_state": _collect_spawn_state(sync, root),
	}


func _collect_spawn_state(sync, root: Node) -> Array:
	var state := []
	var config: SceneReplicationConfig = sync.replication_config
	if config == null:
		return state

	for raw_path in config.get_properties():
		var path := NodePath(raw_path)
		if not config.property_get_spawn(path):
			continue

		var resolved := _resolve_property(root, path)
		if resolved.is_empty():
			continue

		var target: Object = resolved["target"]
		state.append({
			"path": String(path),
			"value": target.get_indexed(resolved["property_path"]),
		})

	return state


func _apply_spawn_state(root: Node, state: Array) -> void:
	for item in state:
		if typeof(item) != TYPE_DICTIONARY or not item.has("path") or not item.has("value"):
			continue

		var path := NodePath(String(item["path"]))
		var resolved := _resolve_property(root, path)
		if resolved.is_empty():
			continue

		var target: Object = resolved["target"]
		target.set_indexed(resolved["property_path"], item["value"])


func _resolve_property(root: Node, path: NodePath) -> Dictionary:
	if path.is_empty():
		return {}

	if path.get_subname_count() == 0:
		return {
			"target": root,
			"property_path": path.get_as_property_path(),
		}

	if path.get_name_count() == 0:
		return {
			"target": root,
			"property_path": _subnames_as_property_path(path),
		}

	if path.get_name_count() == 1 and String(path.get_name(0)) == ".":
		return {
			"target": root,
			"property_path": _subnames_as_property_path(path),
		}

	var target := root.get_node_or_null(path)
	if target:
		return {
			"target": target,
			"property_path": _subnames_as_property_path(path),
		}

	return {}


func _subnames_as_property_path(path: NodePath) -> NodePath:
	var parts := PackedStringArray()
	for i in path.get_subname_count():
		parts.append(String(path.get_subname(i)))
	return NodePath(":" + ":".join(parts))


func _process(_delta: float) -> void:
	var waiting := []
	for payload in _pending_spawn_payloads:
		var mimic_id := String(payload.get("id", ""))
		if mimic_id.is_empty() or _nodes_by_id.has(mimic_id):
			continue

		var parent := _get_spawn_parent(payload)
		if parent == null:
			waiting.append(payload)
			continue

		_spawn_remote_under_parent(payload, parent)

	_pending_spawn_payloads = waiting
	set_process(not _pending_spawn_payloads.is_empty())


func _on_peer_connected(peer_id: int) -> void:
	if not _is_server():
		return

	for mimic_id in _active_spawn_payloads.keys():
		var payload := _get_current_spawn_payload(mimic_id)
		if payload.is_empty():
			continue

		_active_spawn_payloads[mimic_id] = payload
		rpc_id(peer_id, "_spawn_remote", payload)


func _get_current_spawn_payload(mimic_id: String) -> Dictionary:
	if not _nodes_by_id.has(mimic_id):
		return {}

	var root: Node = _nodes_by_id[mimic_id]
	if not is_instance_valid(root):
		return {}

	var sync = _find_sync_in(root)
	if sync == null:
		return _active_spawn_payloads.get(mimic_id, {})

	return _make_spawn_payload(mimic_id, sync, root)


func _find_sync_in(root: Node):
	if _uses_sync_script(root) and root.get_network_root() == root:
		return root

	for child in root.get_children():
		var found = _find_sync_in(child)
		if found:
			return found

	return null


func _uses_sync_script(node: Node) -> bool:
	var script = node.get_script()
	while script is Script:
		if script == MIMIC_SYNC_SCRIPT:
			return true
		script = script.get_base_script()
	return false


@rpc("authority", "call_remote", "reliable")
func _spawn_remote(payload: Dictionary) -> void:
	var mimic_id := String(payload.get("id", ""))
	if mimic_id.is_empty() or _nodes_by_id.has(mimic_id):
		return

	var parent := _get_spawn_parent(payload)
	if parent == null:
		_queue_spawn_payload(payload)
		return

	_spawn_remote_under_parent(payload, parent)


func _get_spawn_parent(payload: Dictionary) -> Node:
	return get_node_or_null(NodePath(String(payload.get("parent_path", ""))))


func _queue_spawn_payload(payload: Dictionary) -> void:
	var mimic_id := String(payload.get("id", ""))
	for i in _pending_spawn_payloads.size():
		if String(_pending_spawn_payloads[i].get("id", "")) == mimic_id:
			_pending_spawn_payloads[i] = payload
			return

	_pending_spawn_payloads.append(payload)
	set_process(true)
	push_warning("Mimic is waiting for spawn parent: %s" % payload.get("parent_path", ""))


func _spawn_remote_under_parent(payload: Dictionary, parent: Node) -> void:
	var mimic_id := String(payload.get("id", ""))
	if mimic_id.is_empty() or _nodes_by_id.has(mimic_id):
		return

	var node_name := String(payload.get("name", ""))
	if node_name.is_empty():
		return
	if parent.has_node(node_name):
		push_warning("Mimic spawn skipped because parent already has child: %s" % node_name)
		return

	var packed := load(String(payload.get("scene_path", ""))) as PackedScene
	if packed == null:
		push_warning("Mimic could not load spawn scene: %s" % payload.get("scene_path", ""))
		return

	var root := packed.instantiate() as Node
	if root == null:
		return

	root.name = node_name
	_apply_spawn_state(root, payload.get("spawn_state", []))

	_remote_spawning = true
	_remote_spawn_id = mimic_id
	_remote_spawn_root_instance_id = root.get_instance_id()
	parent.add_child(root)
	_remote_spawning = false
	_remote_spawn_id = ""
	_remote_spawn_root_instance_id = 0

	_track(root, mimic_id)


@rpc("authority", "call_remote", "reliable")
func _despawn_remote(mimic_id: String) -> void:
	_remove_pending_spawn_payload(mimic_id)
	if not _nodes_by_id.has(mimic_id):
		return

	var root: Node = _nodes_by_id[mimic_id]
	_untrack_id(mimic_id)

	if is_instance_valid(root):
		root.queue_free()


func _track(root: Node, mimic_id: String) -> void:
	if root == null or mimic_id.is_empty():
		return
	if _nodes_by_id.has(mimic_id) or _ids_by_instance.has(root.get_instance_id()):
		return

	_nodes_by_id[mimic_id] = root
	_ids_by_instance[root.get_instance_id()] = mimic_id
	root.tree_exiting.connect(_root_tree_exiting.bind(root.get_instance_id()), CONNECT_ONE_SHOT)


func _has_tracked_ancestor(root: Node) -> bool:
	var node := root.get_parent()
	while node:
		if _ids_by_instance.has(node.get_instance_id()):
			return true
		node = node.get_parent()
	return false


func _remove_pending_spawn_payload(mimic_id: String) -> void:
	if mimic_id.is_empty():
		return

	var waiting := []
	for payload in _pending_spawn_payloads:
		if String(payload.get("id", "")) != mimic_id:
			waiting.append(payload)

	_pending_spawn_payloads = waiting
	set_process(not _pending_spawn_payloads.is_empty())


func _untrack_id(mimic_id: String) -> void:
	if not _nodes_by_id.has(mimic_id):
		return

	var root: Node = _nodes_by_id[mimic_id]
	_nodes_by_id.erase(mimic_id)

	if is_instance_valid(root):
		_ids_by_instance.erase(root.get_instance_id())


func _root_tree_exiting(instance_id: int) -> void:
	_unregister_tracked_instance(instance_id)


func _unregister_tracked_instance(instance_id: int) -> void:
	if not _ids_by_instance.has(instance_id):
		return

	var mimic_id: String = _ids_by_instance[instance_id]
	_untrack_id(mimic_id)

	if _is_server():
		_active_spawn_payloads.erase(mimic_id)
		if multiplayer.has_multiplayer_peer():
			rpc("_despawn_remote", mimic_id)


func _is_server() -> bool:
	return multiplayer.has_multiplayer_peer() and multiplayer.is_server()
