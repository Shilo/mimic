# Documentation Site

The Mimic documentation is hosted with GitHub Pages from the same repository as the addon.

The site is built so the pages, API reference, and playable web example can stay together under one domain:

```text
https://shilo.github.io/mimic/
```

## Generated API Reference

The API reference is generated from the `##` documentation comments in Mimic's GDScript files. That means the reference pages should match the same public classes and descriptions Godot can show in editor help.

The generated API section currently focuses on the user-facing surface:

- `Mimic`
- `MimicConnector`
- `MimicSync`
- `MimicProjectSettings`

Internal helpers stay out of the main API navigation so the reference remains useful for developers adding Mimic to a game.

The MkDocs hook runs Godot's doctool against `res://addons/mimic`, writes XML into `build/api_xml/`, and regenerates Markdown under `docs/api/` with `tools/generate_api_docs.py`. The generated `docs/api/` files are ignored by git and rebuilt during documentation builds.

## Playable Web Example

The documentation build can also export the Godot Web example hub into the same Pages artifact.

The playable path is:

```text
/play/
```

This is a browser client export. It can show the example hub and connect to an external WebSocket server, but GitHub Pages itself cannot run the multiplayer server.

The docs workflow builds the site with Godot 4.6.3, runs `mkdocs build --strict`, then calls `tools/export_web_example.ps1` to place the web export at `build/site/play/`.

## Brand Assets

The documentation landing page uses the source logo at `brand/logo/mimic_m_multiplayer.svg`, with `brand/logo/mimic_m_multiplayer.png` as its fallback. Pages that mention the mascot use `brand/icon/mimic.svg`, with `brand/icon/mimic.png` as the fallback. Documentation chrome on Mimic Mint surfaces uses `brand/icon/mimic_invert.svg` so the mascot stays readable without a badge background.

During the MkDocs build, `tools/mkdocs_hooks.py` copies SVG and PNG files from `brand/` into the built site so the documentation can use the same source assets as the repository README.

## Reading The Docs

Start with [Quick Start](../quick_start.md) if you want to run Mimic locally. Use the node pages for explanations, and use the generated API pages when you need exact method, signal, enum, and setting details.
