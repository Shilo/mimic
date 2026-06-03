extends GutTest

const GRID_SCRIPT := preload("res://addons/mimic/testing/mimic_run_instance_grid.gd")

var _grid = null


func before_each() -> void:
	_grid = GRID_SCRIPT.new()


func after_each() -> void:
	_grid.free()
	_grid = null


func test_fit_frame_rect_preserves_client_aspect_inside_tall_cell() -> void:
	var cell_rect := Rect2i(Vector2i.ZERO, Vector2i(960, 1080))
	var reference_client_size := Vector2i(1152, 648)
	var titlebar_height := 31
	var frame_border_size := Vector2i(1, 1)

	var fitted_rect: Rect2i = _grid.call(
		"_fit_frame_rect_to_cell",
		cell_rect,
		reference_client_size,
		titlebar_height,
		frame_border_size
	)

	assert_eq(fitted_rect, Rect2i(Vector2i(0, 255), Vector2i(960, 570)))
	assert_almost_eq(
		_get_client_aspect(fitted_rect, titlebar_height, frame_border_size),
		16.0 / 9.0,
		0.01
	)


func test_fit_frame_rect_centers_window_inside_wide_cell() -> void:
	var cell_rect := Rect2i(Vector2i.ZERO, Vector2i(1920, 540))
	var reference_client_size := Vector2i(1152, 648)
	var titlebar_height := 31
	var frame_border_size := Vector2i(1, 1)

	var fitted_rect: Rect2i = _grid.call(
		"_fit_frame_rect_to_cell",
		cell_rect,
		reference_client_size,
		titlebar_height,
		frame_border_size
	)

	assert_eq(fitted_rect, Rect2i(Vector2i(507, 0), Vector2i(905, 540)))
	assert_almost_eq(
		_get_client_aspect(fitted_rect, titlebar_height, frame_border_size),
		16.0 / 9.0,
		0.01
	)


func test_fit_frame_rect_keeps_adjacent_frames_at_cell_seam() -> void:
	var left_cell_rect := Rect2i(Vector2i.ZERO, Vector2i(960, 1032))
	var right_cell_rect := Rect2i(Vector2i(960, 0), Vector2i(960, 1032))
	var reference_client_size := Vector2i(1152, 648)
	var titlebar_height := 31
	var frame_border_size := Vector2i(1, 1)

	var left_rect: Rect2i = _grid.call(
		"_fit_frame_rect_to_cell",
		left_cell_rect,
		reference_client_size,
		titlebar_height,
		frame_border_size
	)
	var right_rect: Rect2i = _grid.call(
		"_fit_frame_rect_to_cell",
		right_cell_rect,
		reference_client_size,
		titlebar_height,
		frame_border_size
	)

	assert_eq(left_rect.end.x, right_rect.position.x)


func test_fit_frame_rect_accounts_for_windows_border_inside_quarter_cell() -> void:
	var cell_rect := Rect2i(Vector2i.ZERO, Vector2i(960, 516))
	var reference_client_size := Vector2i(1152, 648)
	var titlebar_height := 31
	var frame_border_size := Vector2i(1, 1)

	var fitted_rect: Rect2i = _grid.call(
		"_fit_frame_rect_to_cell",
		cell_rect,
		reference_client_size,
		titlebar_height,
		frame_border_size
	)

	assert_eq(fitted_rect, Rect2i(Vector2i(49, 0), Vector2i(862, 516)))
	assert_almost_eq(
		_get_client_aspect(fitted_rect, titlebar_height, frame_border_size),
		16.0 / 9.0,
		0.01
	)


func test_grid_selection_uses_reference_aspect() -> void:
	var screen_size := Vector2i(1200, 900)
	var portrait_aspect := 9.0 / 16.0

	var grid: Vector2i = _grid.call("_get_grid", 2, screen_size, portrait_aspect)

	assert_eq(grid, Vector2i(2, 1))


func test_should_fit_requires_active_stretch_mode() -> void:
	var cell_rect := Rect2i(Vector2i.ZERO, Vector2i(960, 1080))
	var reference_client_size := Vector2i(1152, 648)

	assert_false(_should_fit(cell_rect, reference_client_size, "disabled", "keep"))
	assert_false(_should_fit(cell_rect, reference_client_size, "canvas_items", "ignore"))
	assert_false(_should_fit(cell_rect, reference_client_size, "viewport", "expand"))


func test_should_fit_keep_when_cell_aspect_differs() -> void:
	var tall_cell_rect := Rect2i(Vector2i.ZERO, Vector2i(960, 1080))
	var wide_cell_rect := Rect2i(Vector2i.ZERO, Vector2i(1920, 540))
	var reference_client_size := Vector2i(1152, 648)

	assert_true(_should_fit(tall_cell_rect, reference_client_size, "canvas_items", "keep"))
	assert_true(_should_fit(wide_cell_rect, reference_client_size, "viewport", "keep"))


func test_should_fill_keep_when_cell_client_aspect_matches() -> void:
	var reference_client_size := Vector2i(1152, 648)
	var matching_cell_rect := Rect2i(Vector2i.ZERO, Vector2i(1154, 680))

	assert_false(_should_fit(matching_cell_rect, reference_client_size, "canvas_items", "keep"))


func test_should_fit_keep_width_only_when_cell_is_wider() -> void:
	var tall_cell_rect := Rect2i(Vector2i.ZERO, Vector2i(960, 1080))
	var wide_cell_rect := Rect2i(Vector2i.ZERO, Vector2i(1920, 540))
	var reference_client_size := Vector2i(1152, 648)

	assert_true(_should_fit(wide_cell_rect, reference_client_size, "canvas_items", "keep_width"))
	assert_false(_should_fit(tall_cell_rect, reference_client_size, "canvas_items", "keep_width"))


func test_should_fit_keep_height_only_when_cell_is_taller() -> void:
	var tall_cell_rect := Rect2i(Vector2i.ZERO, Vector2i(960, 1080))
	var wide_cell_rect := Rect2i(Vector2i.ZERO, Vector2i(1920, 540))
	var reference_client_size := Vector2i(1152, 648)

	assert_true(_should_fit(tall_cell_rect, reference_client_size, "canvas_items", "keep_height"))
	assert_false(_should_fit(wide_cell_rect, reference_client_size, "canvas_items", "keep_height"))


func test_should_fit_uses_unclamped_cell_aspect_for_tiny_cells() -> void:
	var tiny_wide_cell_rect := Rect2i(Vector2i.ZERO, Vector2i(100, 40))
	var reference_client_size := Vector2i(1152, 648)

	assert_true(_should_fit(tiny_wide_cell_rect, reference_client_size, "canvas_items", "keep_width"))
	assert_false(_should_fit(tiny_wide_cell_rect, reference_client_size, "canvas_items", "keep_height"))


func _get_client_aspect(
	frame_rect: Rect2i,
	titlebar_height: int,
	frame_border_size: Vector2i
) -> float:
	var client_size := frame_rect.size - Vector2i(
		frame_border_size.x * 2,
		titlebar_height + frame_border_size.y
	)
	return float(client_size.x) / float(client_size.y)


func _should_fit(
	cell_rect: Rect2i,
	reference_client_size: Vector2i,
	stretch_mode: String,
	stretch_aspect: String
) -> bool:
	return _grid.call(
		"_should_fit_to_cell_for_stretch",
		cell_rect,
		reference_client_size,
		31,
		Vector2i(1, 1),
		stretch_mode,
		stretch_aspect
	)
