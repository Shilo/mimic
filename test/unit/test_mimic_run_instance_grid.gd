extends GutTest

const GRID_SCRIPT := preload("res://addons/mimic/testing/mimic_run_instance_grid.gd")

var _grid = null
var _custom_multiplayer_roots: Array[Node] = []
var _custom_multiplayer_apis: Array[SceneMultiplayer] = []
var _next_title_test_port := 19700
var _saved_multiplayer_poll := true
var _saved_window_title := ""


func before_each() -> void:
	_grid = GRID_SCRIPT.new()
	_custom_multiplayer_roots.clear()
	_custom_multiplayer_apis.clear()
	_saved_multiplayer_poll = get_tree().is_multiplayer_poll_enabled()
	_saved_window_title = get_window().title
	get_tree().set_multiplayer_poll_enabled(true)


func after_each() -> void:
	if is_instance_valid(_grid):
		_grid.free()
	_grid = null

	for multiplayer_api in _custom_multiplayer_apis:
		if multiplayer_api.multiplayer_peer != null:
			multiplayer_api.multiplayer_peer.close()
	_custom_multiplayer_apis.clear()

	for root in _custom_multiplayer_roots:
		if is_instance_valid(root):
			get_tree().set_multiplayer(null, root.get_path())
			root.free()
	_custom_multiplayer_roots.clear()

	get_tree().set_multiplayer_poll_enabled(_saved_multiplayer_poll)
	get_window().title = _saved_window_title


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


func test_window_index_title_uses_launch_order_until_connected() -> void:
	var title: String = _grid.call("_format_window_index_title", "Mimic Multiplayer", 1, 3)

	assert_eq(title, "Mimic Multiplayer [Session 2/3]")


func test_peer_title_appends_peer_id_to_launch_order_after_connection() -> void:
	var title: String = _grid.call(
		"_format_peer_title",
		"Mimic Multiplayer [Session 2/3]",
		618443343
	)

	assert_eq(title, "Mimic Multiplayer [Session 2/3] [Peer 618443343]")


func test_window_title_switches_to_peer_id_when_multiplayer_connects() -> void:
	var port := _next_title_test_port
	_next_title_test_port += 1
	var host := _create_multiplayer_root("TitleHost")
	var client := _create_multiplayer_root("TitleClient")
	var host_api: SceneMultiplayer = host["multiplayer_api"]
	var client_api: SceneMultiplayer = client["multiplayer_api"]

	client["root"].add_child(_grid)
	_grid.set("_base_title", "Mimic Multiplayer")
	_grid.call("_set_grid_title", 1, 2)
	_grid.call("_connect_multiplayer_title_signals")

	assert_eq(get_window().title, "Mimic Multiplayer [Session 2/2]")

	var host_peer := ENetMultiplayerPeer.new()
	assert_eq(host_peer.create_server(port, 2), OK)
	host_api.multiplayer_peer = host_peer

	var client_peer := ENetMultiplayerPeer.new()
	assert_eq(client_peer.create_client("127.0.0.1", port), OK)
	client_api.multiplayer_peer = client_peer

	var title_changed: bool = await wait_until(
		func() -> bool:
			var peer_id := client_api.get_unique_id()
			return (
				client_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED
				and peer_id > 1
				and get_window().title == "Mimic Multiplayer [Session 2/2] [Peer %d]" % peer_id
			),
		5.0
	)

	assert_true(title_changed)


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


func _create_multiplayer_root(root_label: String) -> Dictionary:
	var root := Node.new()
	root.name = "%s%d" % [root_label, _custom_multiplayer_roots.size()]
	add_child(root)

	var multiplayer_api := SceneMultiplayer.new()
	get_tree().set_multiplayer(multiplayer_api, root.get_path())
	_custom_multiplayer_roots.append(root)
	_custom_multiplayer_apis.append(multiplayer_api)

	return {
		"root": root,
		"multiplayer_api": multiplayer_api,
	}
