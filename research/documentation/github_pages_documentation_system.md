# Mimic GitHub Pages Documentation System Research

Last reviewed: 2026-05-30

Scope: documentation system options for a GitHub Pages-hosted Mimic Multiplayer site, including theme choice, brand flexibility, Godot Web export hosting, generated GDScript API reference, user-facing documentation structure, and migration of existing research into public developer docs.

Public-repo note: this document is intended to guide future public documentation work. Do not add private domains, credentials, unpublished infrastructure details, or user-specific deployment notes.

## Requirements

The documentation site needs to support:

- Hosting from the same GitHub repository on GitHub Pages.
- Many user-facing pages.
- Quick start.
- Installation and setup.
- Tutorials.
- Explanations for each public node and main singleton/helper.
- A Mimic vs Netfox comparison page that clearly explains when a developer should prefer Netfox.
- Migration of current `research/` material into user-facing documentation, not contributor notes.
- Generated API references from Godot GDScript `##` documentation comments.
- Example explanations.
- A playable Godot Web export, preferably on the same GitHub Pages domain and repository.
- Dark mode with Mimic brand colors and fonts.
- A friendly docs experience like Netfox, but with a visual style that fits Mimo and the Mimic brand.

## Short Answer

Use **MkDocs with Material for MkDocs**, plus a small custom Mimic stylesheet and a custom API generation step based on Godot's `--doctool --gdscript-docs` XML output.

This is not a hard dependency on Material forever. The important decision is to use MkDocs as the content/build layer. Material is currently the best-fit theme because it gives Mimic a polished developer-docs experience, built-in search, strong navigation, dark/light palettes, code-copy affordances, and direct font/color customization without needing a custom React/Vue/Astro site.

Godot Web exports can live on the same GitHub Pages site. The practical MVP should use a single-threaded Godot 4.6 Web export. A threaded export requires cross-origin isolation headers or Godot's PWA/service-worker workaround; GitHub Pages is static hosting and does not provide arbitrary per-route response-header control.

## Local Reference Findings

### Netfox

Local path: `C:\Programming_Files\Godot\netfox-main`

Netfox uses:

- MkDocs.
- The built-in `readthedocs` theme with a small custom theme override.
- `mkdocs-puml`, `pymdown-extensions`, and `include_dir_to_nav`.
- GitHub Actions workflows for site validation and publishing.
- `mike` for versioned documentation deployment.
- Godot CLI API generation:

```bash
godot --doctool apidocs/ --no-docbase --gdscript-docs .
bun sh/refdoc/ apidocs/ ./ docs/class-reference/
```

Useful lessons:

- The Netfox content model is very user-friendly: index, install, FAQ, tutorials, concepts, guides, node pages, and reference.
- The node pages are written as teaching pages, not raw API dumps. This is the right model for Mimic's `MimicSync`, `MimicConnector`, and `Mimic` singleton pages.
- Netfox proves `godot --doctool --gdscript-docs` is viable in a docs build pipeline.
- Netfox's theme is readable and familiar, but the built-in `readthedocs` theme is visually older and constrained. The current MkDocs docs note that the `readthedocs` theme has a restricted feature set and only two levels of navigation, which is a poor fit for a growing Mimic docs tree.

### PentaTile

Local path: `C:\Programming_Files\Shilocity\PentaTile`

PentaTile uses:

- MkDocs Material.
- GitHub Pages deployment via Actions artifact upload and `actions/deploy-pages`.
- `mkdocs build --strict`.
- `mkdocs-llmstxt` for `llms.txt` and `llms-full.txt`.
- A Python MkDocs hook that regenerates `docs/api-reference.md` from GDScript `##` comments before each build.
- A clear Quickstart-first information architecture.

Useful lessons:

- MkDocs Material already fits this user's Godot addon workflow and GitHub Pages setup.
- A Python hook is simple and easy to keep in the repo.
- PentaTile's current API generator is intentionally lightweight and regex-based. That was enough for that addon, but Mimic has signals, enums, enum values, settings, singleton methods, and node APIs. Mimic should use Godot's doctool XML as the source of truth instead of only regex-parsing `.gd` files.

## Candidate Stack Comparison

| Stack | Fit | Strengths | Risks | Verdict |
| --- | --- | --- | --- | --- |
| Plain MkDocs with built-in `mkdocs` theme | Medium | Very simple, Python-only, static, built-in dark/auto color mode and user toggle, easy GitHub Pages deployment | Less polished, more CSS work to make it feel like Mimic, fewer modern docs niceties than Material | Good fallback if avoiding third-party themes is more important than polish |
| MkDocs with built-in `readthedocs` theme | Low to Medium | Familiar docs layout, matches Netfox's broad structure, simple | Older visual style, restricted feature set, limited navigation depth, weaker fit for cute/brand-forward Mimic identity | Do not choose as the main theme, but borrow Netfox's content structure |
| MkDocs Material | High | Mature docs UX, strong navigation, search, dark/light palettes, code-copy, admonitions, tabs, easy Google Font config, custom CSS variables, existing PentaTile precedent | Can look generic if not customized; still Python package code in the build environment | Recommended |
| Docusaurus | Medium | Great docs/product hybrid, React components, strong versioning, dark mode, flexible custom pages | Node/React stack, more moving parts, API generation still custom, heavier than needed for a Godot addon | Good if Mimic later needs a React-heavy marketing site, not the docs MVP |
| VitePress | Medium | Very fast, polished default docs, Vue components in Markdown, built-in dark mode | Node/Vue stack, API generation still custom, less direct local precedent | Good alternative if a JS docs stack is preferred |
| Astro Starlight | Medium to High | Modern, accessible docs, strong customization, custom pages, Tailwind option, brandable, good for docs plus product pages | Node/Astro stack, API generation still custom, less local precedent than MkDocs | Strong future alternative if Mimic wants a custom docs/marketing hybrid |
| Sphinx/Furo or Sphinx/ReadTheDocs | Low | Godot's own docs use Sphinx, powerful API docs ecosystem | reStructuredText heritage, heavier config, less pleasant for this Markdown-first addon docs workflow | Not recommended for Mimic |
| Jekyll/GitHub Pages native | Low | GitHub Pages native, simple static hosting | Weak API generation story, weaker modern docs UX unless heavily customized | Not recommended |

## Recommended Stack

Recommended baseline:

```text
MkDocs
Material for MkDocs
Python API generator from Godot doctool XML
GitHub Actions Pages artifact deployment
Optional mkdocs-llmstxt
```

Recommended files:

```text
mkdocs.yml
requirements-docs.txt
tools/generate_api_docs.py
tools/mkdocs_hooks.py
.github/workflows/docs.yml
docs/index.md
docs/installation.md
docs/quick_start.md
docs/tutorials/
docs/nodes/
docs/guides/
docs/examples/
docs/api/
docs/assets/
docs/styles/brand.css
```

Recommended `requirements-docs.txt` starting point:

```text
mkdocs-material==9.*
mkdocs-llmstxt==0.5.*
```

`mkdocs-llmstxt` is optional, but useful. PentaTile already uses it to publish agent-friendly docs artifacts. Mimic is an addon that AI assistants are likely to help users integrate, so `llms.txt` and `llms-full.txt` are a good fit.

## Theme Direction

Use Material for MkDocs as a framework, not as the visual identity. Mimic should ship a custom brand layer:

```text
docs/styles/brand.css
```

The style should apply the brand decisions from `research/branding/mimo_brand_identity.md`:

- Mimic Mint: `#65E6B8`.
- Midnight Ink: `#10212B`.
- Muted Text: `#49616B`.
- Display/logo font: Fredoka.
- Body/docs font: Nunito Sans.

Material supports light/dark palette toggles and custom colors through CSS variables. It also supports Google Fonts directly through `mkdocs.yml`, or custom loaded fonts through an additional stylesheet.

Recommended look:

- Default to a friendly dark mode or respect system preference.
- Use Midnight Ink for the header/primary text and Mimic Mint for accents.
- Use M-shaped Mimo in the header logo.
- Use network-shaped Mimo for the favicon and network/sync pages.
- Keep the homepage playful, but keep reference pages dense and scannable.
- Avoid turning every page into marketing. The docs should open with the real quick start.

Do not rely only on Material's named `primary` and `accent` color presets, because Mimic's exact mint/ink palette is not a standard Material palette. Use `extra_css` to override Material variables.

## API Reference Generation

### Source Of Truth

The source of truth should be Godot `##` documentation comments in GDScript.

Godot's docs specify that documentation comments:

- Start with `##`.
- Must immediately precede the script member, or sit at the top of a script for script descriptions.
- Can document signals, enums, enum values, constants, variables, functions, and inner classes.
- Treat underscore-prefixed member variables or functions as private and omit them from generated help.
- Can be generated as XML files by the editor.

Godot's command line reference includes:

```text
--doctool [<path>]
--no-docbase
--gdscript-docs <path>
```

This makes the robust pipeline:

```text
GDScript ## comments
-> godot --headless --doctool build/api_xml --no-docbase --gdscript-docs <path>
-> tools/generate_api_docs.py
-> generated Markdown under docs/api/
-> mkdocs build --strict
```

### Why Not Only Regex Parse GDScript

PentaTile's regex hook is a good local precedent, but Mimic's public surface is more varied:

- Signals on `Mimic`.
- Enums and enum values.
- Methods with default args and typed returns.
- Exported properties on nodes.
- Project settings accessors.
- BBCode-style Godot doc links such as `[method start_client]`, `[enum NetworkState]`, `[param port_override]`, and `[code]...[/code]`.

Using Godot's doctool first should capture more of Godot's own documentation semantics and reduce drift from the editor help system.

### Recommended API Surface

The generated public API should be user-facing, not a dump of every globally named implementation helper.

Primary API pages:

- `Mimic` singleton.
- `MimicConnector`.
- `MimicSync`.
- `MimicProjectSettings` as an advanced/settings reference if needed.

Do not put internal helpers in the primary API nav:

- `MimicPortMapper` is internal.
- `MimicLog` is internal support.
- `MimicRunInstanceGrid` is optional local testing support.
- `plugin.gd` is editor plugin infrastructure.

The generator can still parse all XML, but it should render only an explicit allowlist for the user docs. If internal references become useful later, add an "Internal Support" appendix instead of mixing internals into the main API.

### Generated Page Shape

Recommended generated page structure:

```text
# Mimic

Runtime singleton for Mimic connection setup and network state.

Source: addons/mimic/mimic.gd
Extends: Node

## Signals
## Enums
## Methods
```

Each symbol should include:

- Signature.
- Description converted from Godot BBCode to Markdown.
- Parameter docs when present.
- Return type when present.
- Source path link to GitHub.
- Links to Godot built-in class docs for built-in classes like `MultiplayerSynchronizer`.

## GitHub Pages Deployment

GitHub Pages is a static hosting service. It can publish HTML, CSS, and JavaScript files from a repository, optionally after a build process. A project repository has one Pages site, normally at:

```text
https://<owner>.github.io/<repository>/
```

That is enough for both docs and a Godot Web export as long as they are part of the same built artifact.

Recommended workflow shape:

```yaml
name: Deploy docs

on:
  push:
    branches: [main]
    paths:
      - "docs/**"
      - "addons/mimic/**/*.gd"
      - "examples/**"
      - "tools/generate_api_docs.py"
      - "tools/mkdocs_hooks.py"
      - "mkdocs.yml"
      - "requirements-docs.txt"
      - ".github/workflows/docs.yml"
  workflow_dispatch:

concurrency:
  group: pages
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - name: Configure GitHub Pages
        uses: actions/configure-pages@v5
      - uses: actions/setup-python@v5
        with:
          python-version: "3.x"
          cache: pip
          cache-dependency-path: requirements-docs.txt
      - name: Install docs dependencies
        run: pip install -r requirements-docs.txt
      - name: Set up Godot
        run: echo "Use the repo-approved Godot setup action or wrapper here"
      - name: Import project
        run: godot --headless --import --path .
      - name: Generate API docs
        run: godot --headless --path . --doctool build/api_xml --no-docbase --gdscript-docs res://addons/mimic
      - name: Render API markdown
        run: python tools/generate_api_docs.py build/api_xml docs/api
      - name: Build docs
        run: mkdocs build --strict
      - uses: actions/upload-pages-artifact@v4
        with:
          path: site

  deploy:
    needs: build
    runs-on: ubuntu-latest
    permissions:
      pages: write
      id-token: write
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - id: deployment
        uses: actions/deploy-pages@v4
```

The exact Godot setup step should be chosen during implementation. Netfox uses `chickensoft-games/setup-godot@v1`; Mimic also has a local `tools/godot.ps1` wrapper for local verification. The CI build should pin the Godot version used by this project, currently Godot 4.6.3.

## Hosting A Godot Web Export In The Same Site

Yes, this is possible.

Recommended URL shape:

```text
https://<owner>.github.io/mimic/
https://<owner>.github.io/mimic/examples/single_to_multiplayer/
https://<owner>.github.io/mimic/play/single_to_multiplayer/
```

Recommended content split:

- `docs/examples/single_to_multiplayer.md`: teaching page explaining what the example demonstrates.
- `site/play/single_to_multiplayer/index.html`: generated Godot Web export for the playable example.
- A button on the example page: "Open fullscreen demo".
- Optional embedded preview:

```html
<iframe
	src="../play/single_to_multiplayer/"
	title="Mimic single to multiplayer example"
	allowfullscreen
></iframe>
```

MkDocs copies non-Markdown files in the docs directory to the built site unaltered, so a raw HTML Godot export can live under the built site. However, generated Web export files can be large and should not automatically be committed unless the project explicitly decides to version them.

Best build options:

1. Build docs with `mkdocs build`.
2. Export the Godot Web demo into `site/play/single_to_multiplayer/index.html`.
3. Upload `site` as the Pages artifact.

Alternative:

1. Export the Godot Web demo into a temporary ignored `docs/play/single_to_multiplayer/` folder.
2. Run `mkdocs build`, letting MkDocs copy the raw HTML, `.wasm`, `.pck`, `.js`, and `.png` files into `site`.

The second option makes links easier to validate during `mkdocs build --strict`, but needs careful `.gitignore` rules so generated Web files do not accidentally become source docs.

### Web Export Constraints

Use a single-threaded Godot Web export for the GitHub Pages docs MVP.

Reasons:

- Godot 4.3+ supports single-threaded Web exports, and Godot's docs describe this as the preferred/default way to export to the Web.
- Threaded Web exports use `SharedArrayBuffer` and require cross-origin isolation headers:
  - `Cross-Origin-Opener-Policy: same-origin`
  - `Cross-Origin-Embedder-Policy: require-corp`
- GitHub Pages is static hosting, so the direct Pages setup should not be treated as a custom-header host.
- Godot's PWA export can install a service-worker-based workaround for cross-origin isolation, but that adds cache and lifecycle complexity. For a docs-embedded example, avoid this unless threads are truly required.
- GitHub Pages provides gzip compression for served files, which helps with Godot `.wasm` and `.pck` payloads.

Also remember:

- Browser exports support HTTP, HTTP requests, WebSocket client, and WebRTC. They do not support low-level networking.
- GitHub Pages cannot host a multiplayer game server. A browser demo can run offline, run local-only behavior, or connect as a WebSocket client to an external `wss://` server.
- A docs page loaded over HTTPS should connect to production multiplayer services with `wss://`, not plain `ws://`.
- Browser fullscreen and mouse capture need a user gesture. A raw "Open fullscreen demo" page is more reliable than forcing the docs page itself into fullscreen.

## Recommended Information Architecture

Start with a docs tree that teaches real users, then add reference depth.

```text
docs/
  index.md
  installation.md
  quick_start.md
  concepts/
    what_mimic_is.md
    godot_multiplayer_basics.md
    transports.md
    authority_and_peers.md
  tutorials/
    add_mimic_to_a_scene.md
    host_and_join_locally.md
    use_mimic_connector.md
    prepare_a_websocket_build.md
  nodes/
    mimic.md
    mimic_connector.md
    mimic_sync.md
  guides/
    project_settings.md
    enet.md
    websockets.md
    port_forwarding.md
    logging.md
    deployment.md
  examples/
    single_to_multiplayer.md
  compare/
    mimic_vs_netfox.md
  api/
    index.md
    mimic.md
    mimic_connector.md
    mimic_sync.md
    mimic_project_settings.md
  about/
    brand.md
```

### Homepage

The homepage should be a product docs entry, not a generic landing page.

Recommended first screen:

- Mimo brand mark.
- One sentence: "Mimic Multiplayer helps Godot projects start hosting, joining, and syncing with one small addon layer around Godot's high-level multiplayer API."
- Two primary actions:
  - Quick Start.
  - Installation.
- A small "View playable example" action if the Web export is available.

### Quick Start

Goal: user gets a basic scene running quickly.

The page should be terse and task-based:

1. Install addon.
2. Enable plugin.
3. Confirm Mimic autoload.
4. Add `MimicConnector` or call `Mimic.start_server()`.
5. Add `MimicSync` to a scene/entity when replication work returns.
6. Run two local instances.

### Node Pages

Borrow Netfox's teaching style:

- Start with what the node is for.
- Show when to use it.
- Show a screenshot once final docs assets exist.
- Show minimal code.
- Link to API reference at the bottom.

### Mimic vs Netfox Page

This page should be generous and clear, not competitive.

Mimic is best when:

- The user wants a small helper around Godot's high-level multiplayer API.
- The project is early and needs connection setup, project settings, and straightforward replication ergonomics.
- The team wants to stay close to Godot-native `MultiplayerSynchronizer` and `SceneReplicationConfig`.

Netfox is best when:

- The game needs a fuller networking framework.
- The game needs rollback, prediction, reconciliation, tick management, lag compensation, or advanced multiplayer architecture.
- The team is ready to adopt Netfox's network model and supporting nodes.

Link to Netfox:

```text
https://github.com/foxssake/netfox
https://foxssake.github.io/netfox/
```

## Research Migration Plan

Existing research should be rewritten into user-facing docs rather than copied verbatim.

Recommended mapping:

| Research file | Future docs page | Rewrite goal |
| --- | --- | --- |
| `research/networking/port_selection_and_websocket_deployment.md` | `docs/guides/deployment.md` or `docs/guides/websockets.md` | Explain default ports, local testing, `ws://` vs `wss://`, reverse proxy topology, and browser limitations for users shipping games |
| `research/branding/mimo_brand_identity.md` | `docs/about/brand.md` or future press kit | Keep public brand rules and assets; remove internal decision notes if the page is aimed at users |
| `research/documentation/github_pages_documentation_system.md` | Usually not migrated as a user doc | Use this to implement the docs system; do not publish it unless creating contributor docs later |

## Open Decisions

- Use Material for MkDocs now, or prototype both Material and Astro Starlight before committing to the site framework?
- Should docs default to dark mode, system preference, or light mode with a prominent toggle?
- Should generated API docs be a single page first, or one page per public class from the start?
- Should generated Web export files be committed, published only as CI artifacts, or attached to releases and copied into Pages from release artifacts?
- Should the playable demo be offline/local-only at first, or connect to a public `wss://` demo server?
- Should `MimicProjectSettings` be surfaced as a public API page or documented only through the Project Settings guide?

## Sources

- GitHub Pages overview: https://docs.github.com/en/pages/getting-started-with-github-pages/what-is-github-pages
- GitHub Pages custom workflows: https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages
- MkDocs home: https://www.mkdocs.org/
- MkDocs choosing themes: https://www.mkdocs.org/user-guide/choosing-your-theme/
- MkDocs writing docs and static file copying: https://www.mkdocs.org/user-guide/writing-your-docs/
- MkDocs deployment guide: https://www.mkdocs.org/user-guide/deploying-your-docs/
- Material for MkDocs color customization: https://squidfunk.github.io/mkdocs-material/setup/changing-the-colors/
- Material for MkDocs font customization: https://squidfunk.github.io/mkdocs-material/setup/changing-the-fonts/
- Godot GDScript documentation comments: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_documentation_comments.html
- Godot command line `--doctool` and `--gdscript-docs`: https://docs.godotengine.org/en/latest/tutorials/editor/command_line_tutorial.html
- Godot Web export docs: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html
- Docusaurus deployment: https://www.docusaurus.io/docs/next/deployment
- Docusaurus theme configuration: https://docusaurus.io/docs/api/themes/configuration/
- VitePress deployment: https://vitepress.dev/guide/deploy.html
- VitePress site config and dark mode: https://vitepress.dev/reference/site-config
- Astro GitHub Pages deployment: https://docs.astro.build/en/guides/deploy/github/
- Starlight CSS and styling: https://starlight.astro.build/guides/css-and-tailwind/
- Local Netfox docs reference: `C:\Programming_Files\Godot\netfox-main`
- Local PentaTile docs reference: `C:\Programming_Files\Shilocity\PentaTile`
