extends Node
## MimicRunInstanceGrid optional editor-only AutoLoad.
## [br][br]
## Not registered automatically by the plugin; add this script as an AutoLoad
## to enable window tiling.
## Automatically tiles multiple Godot run-instance windows into a shared grid.
## [br][br]
## This utility is intended for local multiplayer testing from the editor. Make
## sure "Game > Embedding Options > Embed Game on Next Play" is disabled so run
## instances open as separate windows. Each run instance writes a short-lived
## marker file, discovers sibling instances from the same launch burst, then
## moves and resizes itself into a screen tile.

const _DIR := "user://mimic/run_grid"
const _GROUP_MS := 3000
const _STALE_MS := 15000
const _SETTLE_TIMEOUT := 2.0
const _SETTLE_STEP := 0.15
const _STABLE_SCANS := 3
const _MIN_SIZE := Vector2i(96, 96)
const _APPEND_WINDOW_INDEX := true

var _base_title := ""


func _ready() -> void:
	if not OS.has_feature("editor"):
		return
	if DisplayServer.get_name() == "headless":
		return

	_base_title = get_window().title

	DirAccess.make_dir_recursive_absolute(_DIR)

	var started_at := _now_ms()
	var marker := "%d_%d" % [started_at, OS.get_process_id()]
	FileAccess.open("%s/%s" % [_DIR, marker], FileAccess.WRITE)

	var markers := await _wait_for_markers(started_at)
	var index := markers.find(marker)

	if index < 0 or markers.size() < 2:
		return

	if _APPEND_WINDOW_INDEX:
		get_window().title = "%s [%d/%d]" % [_base_title, index + 1, markers.size()]

	_tile(index, markers.size())


func _wait_for_markers(started_at: int) -> Array[String]:
	var markers: Array[String] = []
	var previous_count := -1
	var stable_scans := 0
	var elapsed := 0.0

	while elapsed < _SETTLE_TIMEOUT:
		markers = _get_markers(started_at)

		if markers.size() == previous_count:
			stable_scans += 1
		else:
			stable_scans = 0
			previous_count = markers.size()

		if stable_scans >= _STABLE_SCANS:
			break

		await get_tree().create_timer(_SETTLE_STEP).timeout
		elapsed += _SETTLE_STEP

	return markers


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
	var reference_client_size := _get_reference_client_size()
	var cell_rect := _get_cell_rect(index, count, area, reference_client_size)
	var titlebar_height := _get_titlebar_height()
	var frame_border_size := _get_frame_border_size()
	var frame_rect := _fit_frame_rect_to_cell(
		cell_rect,
		reference_client_size,
		titlebar_height,
		frame_border_size
	)

	var applied_client_size := _set_frame_rect(frame_rect, titlebar_height, frame_border_size)
	_log_tile(index, count, cell_rect, frame_rect, applied_client_size)


func _get_cell_rect(index: int, count: int, area: Rect2i, reference_client_size: Vector2i) -> Rect2i:
	var grid := _get_grid(count, area.size, _get_aspect(reference_client_size))
	var cell := Vector2i(area.size.x / grid.x, area.size.y / grid.y)
	var slot := Vector2i(index % grid.x, index / grid.x)

	return Rect2i(area.position + slot * cell, cell)


func _get_reference_client_size() -> Vector2i:
	var reference_size := get_window().content_scale_size
	if reference_size.x <= 0 or reference_size.y <= 0:
		reference_size = DisplayServer.window_get_size()

	return reference_size.max(_MIN_SIZE)


func _get_grid(count: int, screen_size: Vector2i, target_aspect := 16.0 / 9.0) -> Vector2i:
	var best := Vector2i(count, 1)
	var best_score := INF

	for rows in range(1, count + 1):
		var columns := ceili(float(count) / rows)
		var cell := Vector2(float(screen_size.x) / columns, float(screen_size.y) / rows)
		var score := abs(cell.aspect() - target_aspect)

		if score < best_score:
			best_score = score
			best = Vector2i(columns, rows)

	return best


func _get_titlebar_height() -> int:
	var client_position := DisplayServer.window_get_position()
	var outer_position := DisplayServer.window_get_position_with_decorations()
	return maxi(0, client_position.y - outer_position.y)


func _get_frame_border_size() -> Vector2i:
	if OS.has_feature("windows"):
		return Vector2i(1, 1)

	return Vector2i.ZERO


func _fit_frame_rect_to_cell(
	cell_rect: Rect2i,
	reference_client_size: Vector2i,
	titlebar_height: int,
	frame_border_size := Vector2i.ZERO
) -> Rect2i:
	var frame_chrome_size := Vector2i(
		frame_border_size.x * 2,
		titlebar_height + frame_border_size.y
	)
	var available_client_size := (cell_rect.size - frame_chrome_size).max(_MIN_SIZE)
	var fitted_client_size := _fit_size_to_aspect(available_client_size, reference_client_size)
	var fitted_frame_size := fitted_client_size + frame_chrome_size
	var fitted_frame_position := cell_rect.position + (cell_rect.size - fitted_frame_size) / 2

	return Rect2i(fitted_frame_position, fitted_frame_size)


func _fit_size_to_aspect(available_size: Vector2i, reference_size: Vector2i) -> Vector2i:
	if reference_size.x <= 0 or reference_size.y <= 0:
		return available_size

	var aspect := _get_aspect(reference_size)
	var height_from_width := maxi(1, floori(float(available_size.x) / aspect))
	if height_from_width <= available_size.y:
		return Vector2i(available_size.x, height_from_width)

	var width_from_height := maxi(1, floori(float(available_size.y) * aspect))
	return Vector2i(width_from_height, available_size.y)


func _get_aspect(size: Vector2i) -> float:
	if size.y <= 0:
		return 16.0 / 9.0

	return float(size.x) / float(size.y)


func _set_frame_rect(rect: Rect2i, titlebar_height: int, frame_border_size := Vector2i.ZERO) -> Vector2i:
	var frame_chrome_size := Vector2i(
		frame_border_size.x * 2,
		titlebar_height + frame_border_size.y
	)
	var client_size := (rect.size - frame_chrome_size).max(_MIN_SIZE)
	var frame_size := client_size + frame_chrome_size
	var frame_position := rect.position + (rect.size - frame_size) / 2

	get_window().size = client_size
	get_window().position = frame_position + Vector2i(frame_border_size.x, titlebar_height)

	return client_size


func _log_tile(index: int, count: int, cell_rect: Rect2i, frame_rect: Rect2i, client_size: Vector2i) -> void:
	MimicLog.log_forced(
		"Run instance grid %d/%d: cell=%s frame=%s client=%s" % [
			index + 1,
			count,
			str(cell_rect),
			str(frame_rect),
			str(client_size),
		]
	)


func _now_ms() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0)
