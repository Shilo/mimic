Project: Mimic Multiplayer

Description: Clone-and-play multiplayer for Godot. Drop in a MimicSync node and make your scenes network-aware, with high-level nodes for connection and gameplay.

Technical description: Mimic Multiplayer is a Godot 4 addon for making Godot's high-level multiplayer API easier to author. The long-term product direction is to reduce the usual MultiplayerSpawner, MultiplayerSynchronizer, SceneReplicationConfig, fixed spawn path, spawn configuration, and manual property-selection workflow into a smaller authoring model centered on one visible network component per entity plus one stable Mimic backend.

Goals: The intended authoring shape is that a user adds one MimicSync node to a networked scene/entity, while Mimic handles network lifecycle concerns that would otherwise require separate spawner setup. Dynamic synced objects should eventually be spawnable anywhere in the scene tree as long as the same parent path exists on each peer. Runtime property replication should continue to lean on Godot's native MultiplayerSynchronizer and SceneReplicationConfig wherever possible instead of replacing Godot's replication system.

Current focus: The current implementation has pivoted toward a small connection and configuration MVP. The plugin manages the Mimic autoload and project settings, Mimic exposes connection helpers for ENet/WebSocket/offline states plus stop/cancel/status helpers, MimicConnector provides simple auto-connect entry points, MimicProjectSettings owns typed ProjectSettings accessors, and MimicLog provides compact connection logging. Keep this layer explicit and stable before reintroducing custom spawn/despawn behavior.

Boundaries: Avoid adding gameplay scenes, player scenes, resources, input maps, art, custom inspectors, docks, debug UI, prediction, rollback, interpolation, time sync, command/event systems, client spawn requests, authority transfer, or raw packet protocols unless explicitly requested. Ask before adding files outside the addon/example structure or changing the core design away from the Mimic autoload plus MimicSync component direction. Do not add migration shims, deprecated-name aliases, compatibility wrappers, or fallback behavior anywhere in the project unless explicitly requested; update callers, scenes, docs, and settings to the current Mimic model instead.

Discovery: Prioritize progressive discovery over token usage. Read only the files needed for the current task, then expand outward when the code path requires it. Challenge and verify important ideas before changing the codebase, especially when a request affects architecture, public API, project settings, networking behavior, editor behavior, or file structure. Check local Godot docs/source when behavior depends on MultiplayerAPI, MultiplayerPeer, SceneMultiplayer, MultiplayerSynchronizer, MultiplayerSpawner, SceneReplicationConfig, GDScript syntax, or Godot 4 API style details.

Git commits: Use Conventional Commits in type(scope): summary form, such as feat(mimic): add connection logging.

Code style: Follow the Godot GDScript style guide at https://docs.godotengine.org/en/4.4/tutorials/scripting/gdscript/gdscript_styleguide.html; since GDScript is close to Python, the guide is inspired by Python's PEP 8 programming style guide. Use tabs for indentation, UTF-8 text, snake_case for files/functions/variables/signals, PascalCase for class_name values and enum names, UPPER_CASE for constants, and \_private_name for private helpers or backing fields. Prefer explicit typed public API, guard clauses, small functions, minimal comments, and no unrelated formatting churn. Use current Godot 4, GDScript 2 patterns; do not use outdated Godot 3 or GDScript 1 habits. Prefer typed Callable usage such as `some_method.call_deferred(args)` over string-based `call_deferred("some_method", args)` for local methods. Prefer `class_name` scripts over `preload()` for addon script dependencies unless there is a concrete reason to avoid a global class. Document every public class, signal, enum, enum value, exported property, public variable, and public method with GDScript `##` documentation comments; do not document private API with `##`. Use `## [br][br]` for public documentation paragraph breaks so comments stay readable in code and render correctly in Godot tooltips.

Files:

```
project.godot: Godot project configuration, autoloads, plugin enablement, input actions, and main scene.
icon.svg: Default Godot project icon.
icon.svg.import: Godot import metadata for the project icon.
AGENTS.md: Agent-facing project guidance.
README.md: User-facing developer guide for installing, configuring, and using Mimic.
addons/: Godot addon root.
addons/mimic/: Mimic addon source folder.
addons/mimic/plugin.cfg: Godot editor plugin manifest.
addons/mimic/plugin.gd: Editor plugin that registers Mimic project settings and manages the Mimic autoload.
addons/mimic/mimic.gd: Runtime Mimic autoload for connection helpers, network state, transport startup, shutdown, and port forwarding.
addons/mimic/nodes/: Public user-facing scene-tree nodes developers add to scenes.
addons/mimic/nodes/mimic_connector.gd: CanvasLayer connector that calls Mimic connection helpers and supports future UI plus auto-connect modes.
addons/mimic/nodes/mimic_sync.gd: Visible per-entity component that subclasses MultiplayerSynchronizer.
addons/mimic/connection/: Internal connection infrastructure and transport helpers.
addons/mimic/connection/mimic_port_mapper.gd: Internal UPnP port mapping worker used by the Mimic autoload.
addons/mimic/settings/: Project settings registration and typed settings access.
addons/mimic/settings/mimic_project_settings.gd: Static ProjectSettings helper with typed property accessors for Mimic settings.
addons/mimic/debug/: Logging and debug-facing support scripts.
addons/mimic/debug/mimic_log.gd: Static logging helper for Mimic connection, warning, and error output.
addons/mimic/testing/: Optional local testing helpers.
addons/mimic/testing/mimic_run_instance_grid.gd: Utility for tiling multiple editor-launched game windows during local multiplayer testing.
examples/: Example projects and scenes.
examples/single_to_multiplayer/: Current sample showing a single-player scene adapted toward Mimic networking.
examples/single_to_multiplayer/single_to_multiplayer.tscn: Example scene.
examples/single_to_multiplayer/single_to_multiplayer.gd: Example scene script.
examples/single_to_multiplayer/player/: Example player scene and script.
examples/single_to_multiplayer/player/player.tscn: Example player scene.
examples/single_to_multiplayer/player/player.gd: Example player script.
```
