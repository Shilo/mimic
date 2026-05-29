# Repository Guidelines

## Project Structure & Module Organization

Godot 4.6 addon project for the `Mimic` multiplayer plugin.

- `addons/mimic/` contains the addon source. Core entry points are `mimic.gd`, `mimic_sync.gd`, `mimic_connector.gd`, and `plugin.gd`.
- `addons/mimic/util/` contains shared utilities for settings, logging, and run-instance helpers.
- `examples/single_to_multiplayer/` contains the current example scene and player script.
- `project.godot` defines autoloads, input actions, plugin enablement, and the main scene.
- Godot import/cache output lives under `.godot/` and is ignored.

There is no dedicated test directory yet. Add one only when introducing a repeatable test runner or test scenes.

## Build, Test, and Development Commands

Run from the repository root:

- `godot --editor --path .` opens the project in the Godot editor.
- `godot --path .` runs the configured main scene.
- `godot --headless --path . --quit` loads the project without the editor and is useful as a quick import/script parse check.

If your executable is versioned or outside `PATH`, replace `godot` with the local path.

## Coding Style & Naming Conventions

Use GDScript conventions already present in the addon:

- Tabs for indentation in `.gd` files.
- `snake_case` for variables, methods, signals, and file names.
- `PascalCase` for `class_name` values and enum names.
- Prefix private helpers and backing fields with `_`, for example `_start_server()` or `_state`.
- Keep exported settings and public methods explicit and typed where practical.

The repository has a minimal `.editorconfig` requiring UTF-8. Avoid unrelated formatting churn in Godot scene and project files.

## Testing Guidelines

No formal testing framework is configured. For networking changes, verify at minimum:

- The project loads headlessly.
- The example scene still runs.
- Server, client, and stop paths behave as expected for the touched transport.

When adding tests, prefer deterministic scenes or scripts that run in headless Godot.

## Commit & Pull Request Guidelines

Recent history follows Conventional Commit style:

- `feat(mimic): add project settings for network configuration`
- `refactor(mimic): simplify project settings registration`

Use `type(scope): summary`, with scopes such as `mimic`, `network`, `examples`, or `docs`.

Pull requests should include a short description, behavior changed, verification steps, and screenshots or recordings for visible example-scene changes. Link related issues when available and call out changes to `project.godot` or plugin settings.

## Security & Configuration Tips

Do not commit `.godot/`, local editor settings, generated exports, or credentials. Treat `MimicProjectSettings` defaults as development defaults; document production transport, port forwarding, or TLS assumptions in the PR.
