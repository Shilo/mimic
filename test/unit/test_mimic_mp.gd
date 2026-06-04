extends GutTest


func test_mp_is_set_and_typed() -> void:
	assert_not_null(Mimic.mp, "Mimic.mp should be assigned once the autoload is ready.")
	assert_true(Mimic.mp is MultiplayerAPI, "Mimic.mp should be a MultiplayerAPI.")


func test_mp_matches_scene_tree_multiplayer() -> void:
	# Mimic caches the root SceneTree MultiplayerAPI, so the reference must be the
	# same object Godot resolves through Node.multiplayer / SceneTree.get_multiplayer().
	assert_eq(Mimic.mp, get_tree().get_multiplayer(), "Mimic.mp should be the root MultiplayerAPI.")
	assert_eq(Mimic.mp, multiplayer, "Mimic.mp should match the inherited multiplayer property.")
