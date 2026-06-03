Project: Mimic Multiplayer

Description: Clone-and-play multiplayer for Godot. Drop in a MimicSync node and make your scenes network-aware, with high-level nodes for connection and gameplay.

Technical description: Mimic Multiplayer is a Godot 4 addon for making Godot's high-level multiplayer API easier to author. The long-term product direction is to reduce the usual MultiplayerSpawner, MultiplayerSynchronizer, SceneReplicationConfig, fixed spawn path, spawn configuration, and manual property-selection workflow into a smaller authoring model centered on one visible network component per entity plus one stable Mimic backend.

Goals: The intended authoring shape is that a user adds one MimicSync node to a networked scene/entity, while Mimic handles network lifecycle concerns that would otherwise require separate spawner setup. Dynamic synced objects should eventually be spawnable anywhere in the scene tree as long as the same parent path exists on each peer. Runtime property replication should continue to lean on Godot's native MultiplayerSynchronizer and SceneReplicationConfig wherever possible instead of replacing Godot's replication system.

Current focus: The current implementation has pivoted toward a small connection and configuration MVP. The plugin manages the Mimic autoload and project settings, Mimic exposes connection helpers for ENet/WebSocket/offline states plus stop/cancel/status helpers, MimicProjectSettings owns typed ProjectSettings accessors including editor-only startup auto-connect, MimicConnector is reserved for future connection form UI, and MimicLog provides compact connection logging. Keep this layer explicit and stable before reintroducing custom spawn/despawn behavior.

Boundaries: Avoid adding gameplay scenes, player scenes, resources, input maps, art, custom inspectors, docks, debug UI, prediction, rollback, interpolation, time sync, command/event systems, client spawn requests, authority transfer, or raw packet protocols unless explicitly requested. Ask before adding files outside the addon/example structure or changing the core design away from the Mimic autoload plus MimicSync component direction. Do not add migration shims, deprecated-name aliases, compatibility wrappers, or fallback behavior anywhere in the project unless explicitly requested; update callers, scenes, docs, and settings to the current Mimic model instead.

Discovery: Prioritize progressive discovery over token usage. Read only the files needed for the current task, then expand outward when the code path requires it. Challenge and verify important ideas before changing the codebase, especially when a request affects architecture, public API, project settings, networking behavior, editor behavior, or file structure. Check local Godot docs/source when behavior depends on MultiplayerAPI, MultiplayerPeer, SceneMultiplayer, MultiplayerSynchronizer, MultiplayerSpawner, SceneReplicationConfig, GDScript syntax, or Godot 4 API style details.

Source references: Use `C:\Programming_Files\Godot\godot-master` as the local Godot engine source reference when implementing or improving behavior that depends on Godot multiplayer internals, editor/plugin behavior, GDScript APIs, CLI behavior, project settings, or testing hooks. Use `C:\Programming_Files\Godot\netfox-main` as an inspiration/reference point for multiplayer library architecture, tests, and tradeoffs, while preserving Mimic's different vision: a small helper around Godot's native high-level multiplayer rather than a prediction/rollback/netcode framework.

Documentation: User-facing docs live in docs/. Keep docs phrased for Mimic users. Use `brand/logo/mimic_m_multiplayer.svg` as the preferred full-logo asset, with `brand/logo/mimic_m_multiplayer.png` as the fallback when SVG is not supported. Documentation pages that reference Mimo should show the primary product icon from `brand/icon/mimic.svg`, with `brand/icon/mimic.png` as the fallback when SVG is not supported. When the icon appears on a Mimic Mint surface, use the inverted icon from `brand/icon/mimic_invert.svg`, with `brand/icon/mimic_invert.png` as the fallback.

Consistency updates: When changing public behavior, public API, Project Settings, scene structure, examples, or automation flags, search the repository for the affected names and concepts. Update callers, scenes, tests, README/docs, generated API inputs, examples, project settings, and local automation in the same change so no stale workflow remains.

Godot MCP: Use the repo-local `.mcp.json` server named `godot` when an MCP-capable agent needs to query Godot, launch the editor, run the project, inspect project info, or capture debug output. The server is configured to run `npx -y @coding-solo/godot-mcp@latest` with `GODOT_PATH` set to `C:\Programming_Files\Godot\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64.exe`. Keep MCP configuration local to this repository unless explicitly requested otherwise.

Testing and automation: Treat tests as regression guardrails for AI-assisted changes, not as a mandatory TDD ceremony. Add or update GUT tests in `res://test/unit/` when changing public Mimic behavior, fixing bugs, or touching connection lifecycle, project settings, editor plugin behavior, networking helpers, or example flows that should stay stable. For meaningful feature changes, behavior changes, and risky refactors, run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/verify.ps1` before final response; for especially risky work, run it before and after the change to catch regressions early. Do not add tests for docs-only edits, comments-only edits, or mechanical formatting with no behavior impact. Use `tools/run_two_instances.ps1` for explicit local ENet server/client smoke coverage; prefer these deterministic CLI scripts over MCP as the source of truth for CI-style verification.

Git commits: Use Conventional Commits in type(scope): summary form, such as feat(mimic): add connection logging.

Code style: Follow the Godot GDScript style guide at https://docs.godotengine.org/en/4.4/tutorials/scripting/gdscript/gdscript_styleguide.html; since GDScript is close to Python, the guide is inspired by Python's PEP 8 programming style guide. Use tabs for indentation, UTF-8 text, snake_case for files/functions/variables/signals, PascalCase for class_name values and enum names, UPPER_CASE for constants, and \_private_name for private helpers or backing fields. The snake_case file naming rule applies to every repository file you create or rename, including Markdown, research, docs, scripts, scenes, and resources; use underscores, not hyphens, for multiword file names. Prefer explicit typed public API, guard clauses, small functions, minimal comments, and no unrelated formatting churn. Use current Godot 4, GDScript 2 patterns; do not use outdated Godot 3 or GDScript 1 habits. Prefer typed Callable usage such as `some_method.call_deferred(args)` over string-based `call_deferred("some_method", args)` for local methods. Prefer `class_name` scripts over `preload()` for addon script dependencies unless there is a concrete reason to avoid a global class. Document every public class, signal, enum, enum value, exported property, public variable, and public method with GDScript `##` documentation comments; do not document private API with `##`. Use `## [br][br]` for public documentation paragraph breaks so comments stay readable in code and render correctly in Godot tooltips.

Files:

```
.mcp.json: Repo-local MCP configuration for Coding-Solo godot-mcp using Godot 4.6.3.
.gutconfig.json: GUT command-line test configuration for Mimic unit tests.
C:\Programming_Files\Godot\godot-master: Local Godot engine source reference for API and multiplayer behavior research.
C:\Programming_Files\Godot\netfox-main: Local Netfox multiplayer library reference for inspiration and comparative architecture research.
project.godot: Godot project configuration, autoloads, plugin enablement, input actions, project icon, and main scene.
brand/: Source brand assets for icons, logos, and generated image imports.
brand/icon/: Product icon assets. Plain `mimic` files are the primary network-shaped icon; `_m` files are the secondary M-shaped icon.
brand/icon/mimic.svg: Primary two-color product icon used when documentation references Mimo.
brand/icon/mimic_invert.svg: Inverted primary product icon for Mimic Mint surfaces such as documentation chrome.
brand/logo/: Product wordmark and lockup assets. Plain `mimic` files are the primary network-shaped logo; `_m` files are secondary M-shaped logo variants.
brand/logo/mimic_m_multiplayer.svg: Preferred full Mimic Multiplayer logo for README and documentation surfaces.
mkdocs.yml: MkDocs Material configuration for the documentation site, navigation, API generation, and styling.
requirements-docs.txt: Python requirements for building the documentation site.
AGENTS.md: Agent-facing project guidance.
CLAUDE.md: Claude-facing project guidance, kept aligned with AGENTS.md.
README.md: User-facing developer guide for installing, configuring, and using Mimic.
docs/: User-facing documentation source for the MkDocs site.
docs/index.md: Documentation landing page using the preferred Mimic Multiplayer logo.
docs/about/brand.md: Brand asset, naming, color, and typography guidance.
docs/styles/brand.css: Custom documentation site theme styles.
addons/: Godot addon root.
addons/gut/: Vendored GUT test framework used only for regression tests.
addons/mimic/: Mimic addon source folder.
addons/mimic/icon.svg: Mimic addon icon used as the project icon and public node icon.
addons/mimic/plugin.cfg: Godot editor plugin manifest.
addons/mimic/plugin.gd: Editor plugin that registers Mimic project settings and manages the Mimic autoload.
addons/mimic/mimic.gd: Runtime Mimic autoload for connection helpers, network state, transport startup, shutdown, and port forwarding.
addons/mimic/nodes/: Public user-facing scene-tree nodes developers add to scenes.
addons/mimic/nodes/mimic_connector.gd: CanvasLayer placeholder reserved for future Mimic connection form UI.
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
test/: Automated regression tests and integration probes.
test/.output/: Ignored local verification output for GUT reports and integration logs; the dot-prefixed folder is skipped by Godot's editor file scan.
test/unit/: GUT unit/regression tests for public Mimic behavior.
test/integration/mimic_startup_probe.tscn: Minimal headless scene used by the no-network startup smoke test.
test/integration/mimic_startup_probe.gd: Startup probe script that exits after the project and autoloads initialize.
test/integration/mimic_connection_probe.tscn: Headless scene used by the two-instance connection smoke test.
test/integration/mimic_connection_probe.gd: Explicit server/client probe script used by automation.
tools/: Local PowerShell automation entry points.
tools/godot.ps1: Repo-local Godot CLI wrapper with Godot 4.6.3 fallback.
tools/verify.ps1: Full local verification pass for import, unit tests, startup smoke, ENet explicit/auto-connect smoke, and WebSocket smoke.
tools/run_two_instances.ps1: Explicit ENet/WebSocket server/client and auto-connect smoke test runner.
tools/mkdocs_hooks.py: MkDocs hook that generates API docs and copies SVG/PNG brand assets into the built documentation site.
```
