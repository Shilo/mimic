# AI Quality Workflow

Mimic uses a small deterministic quality gate to catch the two failure modes AI-assisted changes tend to create first: regressions and duplicated code.

This workflow is inspired by tools like [Impeccable](https://impeccable.style/) and [Fallow](https://fallow.tools/), but it is shaped for a Godot addon instead of a frontend app or JavaScript/TypeScript codebase.

## What This Is

Run the fast quality pass:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/quality.ps1
```

This command requires Node.js because the duplicate-code gate runs pinned `jscpd` through `npx`.

Run it and bootstrap the optional pinned `gdcruiser` and `gdstyle` tools into ignored local tooling:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/quality.ps1 -BootstrapTools
```

Run the full regression pass:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/verify.ps1
```

`tools/verify.ps1` runs `tools/quality.ps1` first, then Godot import, GUT unit tests, startup smoke, ENet smoke, ENet auto-connect smoke, and WebSocket smoke.

Plain local runs use any optional pinned tools that are already present. CI runs `tools/quality.ps1 -BootstrapTools`, and local developers can run that command once to install hash-locked `gdcruiser` and checksum-verified `gdstyle` copies under ignored `tools/.bin/`.

The GitHub Actions workflow also runs a Godot regression job with `tools/verify.ps1 -SkipQuality`, so pull requests get static quality checks and runtime regression checks without running the static gate twice.

Use `tools/verify.ps1 -SkipQuality` when you need only the Godot regression checks on a machine without Node.js.

## Checks

The quality pass has five layers:

- Mimic AI policy checks for project-specific mistakes and public API documentation.
- PowerShell syntax checks for repo automation scripts.
- Lockfile-backed `jscpd@4.2.4` duplicate-code detection for GDScript.
- Hash-locked `gdcruiser==1.7.0` dependency architecture checks when bootstrapped.
- Checksum-verified `gdstyle v0.1.5` diagnostics when available.

The duplicate-code gate uses 8-line and 70-token minimums, then fails on every reported clone. Mimic does not maintain a clone allowlist; treat any clone report as a refactor prompt. For rare generated or fixture blocks that would be worse when abstracted, use a narrow `# jscpd:ignore-start` / `# jscpd:ignore-end` block with a nearby explanation.

## AI Policy Rules

The custom policy check targets mistakes that generic linters do not understand:

- String-based `call_deferred("...")` instead of typed callable dispatch.
- Direct addon runtime `print()`, `prints()`, or `printerr()` outside `MimicLog`.
- Scattered `mimic_multiplayer/*` Project Settings reads/writes outside `MimicProjectSettings`.
- Production addon `preload("res://addons/mimic/...")` dependencies instead of `class_name` usage.
- New `MultiplayerSpawner` logic before the project explicitly returns to spawn/despawn design.
- Raw RPC layers inside the addon before there is a design request for that behavior.
- Local declarations that shadow base class members, matching Godot's `SHADOWED_VARIABLE_BASE_CLASS` warning shape.
- Inferred `var value := expression as Type` declarations when an explicit `var value: Type = expression` declaration is clearer.
- Enum values detouring through `int`, especially enum-like function parameters typed as `int` instead of the relevant enum type.
- Missing `##` documentation comments for addon-owned public classes, signals, enums, enum values, exported/public variables, constants, methods, and inner classes.
- Runtime references to quality tooling from `project.godot`.

These are intentionally Mimic-shaped. They are not a general Godot style guide.
The documentation rule accepts Godot's official member documentation shapes:
`##` comments immediately before a public member or inline `##` comments on the
member line. Mimic still prefers preceding comments for readability.

## Godot Style Guide Coverage

`gdstyle` already covers a large part of the official Godot GDScript style guide, including file naming, identifier naming, tabs instead of spaces, line length, trailing whitespace, comment spacing, enum formatting, member ordering, and several quality rules such as duplicate dictionary keys, duplicated loads, unreachable code, allocation in loops, and `get_node()` in process callbacks.

Mimic keeps `class_name X extends Y` on one line when both are present, so the workflow should not enforce the upstream split declaration style. Project-specific policy checks cover a few style choices that generic tools do not know, such as typed callable dispatch instead of string-based `call_deferred("...")`, preferring `class_name` dependencies over production addon preloads, and requiring public API documentation comments.

The style layer is intentionally split: warning-level diagnostics are advisory, while error-level safety rules in `tools/quality/gdstyle.toml` fail the quality pass. The main styleguide-adjacent gap left for later is stricter member ordering after the current advisory diagnostics are cleaned up. It should not block this first workflow because a noisy style gate trains agents to ignore the gate.

## Automation Syntax Rules

The quality pass parses every PowerShell script in `tools/` before running the heavier checks. This is a small regression guard for the verification scripts themselves: broken PowerShell should fail quickly, before Godot or external tools are involved.

## Dependency Architecture Rules

`gdcruiser` gives Mimic a lightweight Fallow-like dependency graph for Godot files. It parses GDScript plus scene/resource references, checks `tools/quality/gdcruiser.json`, fails on detected cycles, and fails when parser errors would make the graph incomplete.

The current rules are intentionally narrow:

- Addon runtime code must not depend on examples, tests, docs, or tooling.
- Godot project modules must stay acyclic.

The current baseline is 21 modules, 29 dependency edges, zero cycles, and zero parser errors, with expected unresolved `GutTest` base classes in unit tests because vendored GUT is excluded from project-owned analysis.

## Impeccable Comparison

Impeccable is valuable because it turns vague "AI slop" into deterministic checks and shared vocabulary. Its public CLI advertises deterministic design anti-pattern detection for PR checks, while its skill teaches AI agents how to avoid generic frontend defaults.

Mimic needs the same operating model, but for code:

- deterministic checks before agent opinions;
- project vocabulary captured in docs and scripts;
- reports that agents can act on without guessing;
- ratchets that improve the codebase over time instead of demanding a risky all-at-once rewrite.

Impeccable itself is still frontend/design oriented. It is not a GDScript analyzer, duplicate-code detector, Godot runtime checker, or multiplayer regression tool.

## Godot Tool Direction

Useful Godot-adjacent options:

- `jscpd` now supports GDScript and is the best duplicate-code detector for this repo; Mimic runs it from `tools/quality/package-lock.json` rather than floating through `npx`.
- `gdcruiser` is useful for dependency and architecture drift, especially circular dependencies and addon-to-example/test mistakes.
- `gdstyle` is promising for GDScript linting/formatting; Mimic currently blocks only on its error-level safety rules and treats the remaining warnings as advisory.
- GDQuest's GDScript formatter is useful for editor formatting, but it is not the duplicate/regression layer Mimic needs.
- Godot warnings and the existing GUT/integration scripts remain the source of truth for runtime behavior.

The practical direction is not to install a large Godot editor plugin. Keep the gate local, scriptable, reviewable, and CI-friendly.

## Dev-Only Boundary

The workflow lives under `tools/` and writes reports under `test/.output/quality/`. Both are development-only locations, and `tools/.gdignore` keeps the tooling out of Godot's resource scan.

Do not reference `tools/quality.ps1`, `jscpd`, `gdcruiser`, `gdstyle`, or generated quality reports from addon runtime code, scenes, autoloads, exported resources, or Project Settings.
