## RunInstanceGrid AutoLoad
## Automatically tiles multiple Godot run-instance windows into a shared grid.
##
## This utility is intended for local multiplayer testing from the editor. Make
## sure "Game > Embedding Options > Embed Game on Next Play" is disabled so run
## instances open as separate windows. Each run instance writes a short-lived
## marker file, discovers sibling instances from the same launch burst, then
## moves and resizes itself into a screen tile.
extends Node

const _DIR := "user://mimic/run_grid"
const _WAIT := 0.5
const _GROUP_MS := 3000
const _STALE_MS := 15000
const _MIN_SIZE := Vector2i(96, 96)


func _ready() -> void:
	if not OS.has_feature("editor") or OS.has_feature("dedicated_server"):
		return

	DirAccess.make_dir_recursive_absolute(_DIR)

	var started_at := _now_ms()
	var marker := "%d_%d" % [started_at, OS.get_process_id()]
	FileAccess.open("%s/%s" % [_DIR, marker], FileAccess.WRITE)

	await get_tree().create_timer(_WAIT).timeout

	var markers := _get_markers(started_at)
	var index := markers.find(marker)

	if index < 0 or markers.size() < 2:
		return

	_tile(index, markers.size())


func _get_markers(started_at: int) -> Array[String]:
	var markers: Array[String] = []
	var now := _now_ms()

	for file_name in DirAccess.get_files_at(_DIR):
		var time := file_name.get_slice("_", 0).to_int()

		if now - time > _STALE_MS:
			DirAccess.remove_absolute("%s/%s" % [_DIR, file_name])
		elif abs(time - started_at) <= _GROUP_MS:
			markers.append(file_name)

	markers.sort()
	return markers


func _tile(index: int, count: int) -> void:
	var area := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	var grid := _get_grid(count, area.size)
	var cell := Vector2i(area.size.x / grid.x, area.size.y / grid.y)
	var slot := Vector2i(index % grid.x, index / grid.x)

	_set_outer_rect(Rect2i(area.position + slot * cell, cell))


func _get_grid(count: int, screen_size: Vector2i) -> Vector2i:
	var best := Vector2i(count, 1)
	var best_score := INF

	for rows in range(1, count + 1):
		var columns := ceili(float(count) / rows)
		var cell := Vector2(float(screen_size.x) / columns, float(screen_size.y) / rows)
		var score := abs(cell.aspect() - 16.0 / 9.0)

		if score < best_score:
			best_score = score
			best = Vector2i(columns, rows)

	return best


func _set_outer_rect(rect: Rect2i) -> void:
	var client_position := DisplayServer.window_get_position()
	var outer_position := DisplayServer.window_get_position_with_decorations()
	var client_size := DisplayServer.window_get_size()
	var outer_size := DisplayServer.window_get_size_with_decorations()

	var decoration_offset := client_position - outer_position
	var decoration_size := outer_size - client_size
	var bottom_decoration := decoration_size.y - decoration_offset.y
	var decorated_size := rect.size + Vector2i(decoration_size.x, bottom_decoration)

	get_window().size = (decorated_size - decoration_size).max(_MIN_SIZE)
	get_window().position = rect.position + Vector2i(0, decoration_offset.y)


func _now_ms() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0)
