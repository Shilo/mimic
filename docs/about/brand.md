# Brand

Mimic Multiplayer's mascot is **Mimo**, a small shapeshifting character that can morph between playful logo shapes. Mimo gives the project a friendlier face for a topic that often feels intimidating: multiplayer.

The mascot idea matches the product idea. Mimic helps a Godot scene adapt into a network-aware scene while staying close to Godot's built-in multiplayer tools.

## Mimo Shapes

Mimo currently appears in two concept shapes:

- **Network Mimo** looks like a soft connection graph. This version hints at peers, synchronization, replication, and network links.
- **M-shaped Mimo** turns the mascot into the first letter of Mimic. This version is the secondary shape for compact lockups and places where the mascot should merge into the wordmark.

Both shapes use the same simple face, rounded body, mint fill, and dark outline so Mimo stays recognizable across sizes.

## Assets

Brand assets live in two folders:

- `brand/icon/` for product icon assets.
- `brand/logo/` for full wordmark and lockup assets.

| Asset | Use |
| --- | --- |
| `icon/mimic.svg` | Scalable primary product icon |
| `icon/mimic_m.svg` | Scalable secondary M-shaped product icon |
| `icon/mimic.png` | SVG-derived primary icon PNG |
| `icon/mimic_m.png` | SVG-derived secondary M-shaped icon PNG |
| `logo/mimic.svg` | Primary wordmark |
| `logo/mimic_flat.svg` | Restrained primary fallback wordmark |
| `logo/mimic_multiplayer.svg` | Large primary full-name lockup |
| `logo/mimic_m.svg` | Secondary M-shaped wordmark |
| `logo/mimic_m_flat.svg` | Restrained secondary M-shaped fallback wordmark |
| `logo/mimic_m_multiplayer.svg` | Large secondary M-shaped full-name lockup |

Each icon and logo SVG has a matching `.png` export in the same folder for tools that do not read SVG reliably.

Plain `mimic` filenames use the primary network-shaped mark. `_m` filenames use the secondary M-shaped mark.

The icon SVG files use a `512x512` viewBox, no fixed display size, and only Mimic Mint plus Midnight Ink. Both icon SVGs share the same face proportions so Mimo remains recognizable while each body shape positions the face on its own visual center. The body outline uses a `12` unit ink width in the SVG viewBox, and the smile uses a `24` unit stroke so it reads at exactly double the outline weight.

The logo SVGs use outlined Fredoka wordmark shapes, so they do not depend on local font installation. Network-shaped logos keep the full `MIMIC` word. M-shaped logos replace the first `M`, so the visible wordmark text is `IMIC`.

The primary universal transparent wordmark style uses Mimic Mint fill with a modest Midnight Ink stroke behind the Fredoka paths. The stroke is sized to render at about `4px` when the SVG is exported at `700px` wide, using `paint-order: stroke fill` so the stroke supports the letters without eating into them. Restrained fallback wordmarks use flat Mimic Slate text with no stroke.

Full-name logo variants add `MULTIPLAYER` below the primary wordmark. The subtitle is width-matched to the primary text line: the full `MIMIC` word for network-shaped logos and the icon-plus-`IMIC` lockup for M-shaped logos. The `MULTIPLAYER` subtitle stays flat Mimic Slate by default so it remains secondary and does not add visual noise at smaller sizes.

## Names

| Name | Meaning |
| --- | --- |
| Mimic Multiplayer | The full product name |
| Mimic | The short name |
| Mimo | The mascot |

Mimo is referred to by name because the mascot is a character, not just a generic icon.

## Colors

Mimic's primary colors come directly from Mimo:

| Token | Value | Use |
| --- | --- | --- |
| Mimic Mint | `#65E6B8` | Mimo fill, primary buttons, links, active states, focus accents |
| Midnight Ink | `#10212B` | Mimo outline, face, headers, dark navigation, body text on light pages |
| Muted Text | `#49616B` | Secondary copy and quieter UI text |
| Mimic Slate | `#537D78` | Restrained universal logo text and large `MULTIPLAYER` subtitles |
| Soft Mint | `#E9FFF7` | Gentle callouts and highlights |

Mint is best as an accent, not as small text on white. Midnight Ink keeps the site readable and gives the cute mascot enough weight to feel like a developer tool.

## Readability

Mimic documentation should follow WCAG AA contrast as the baseline:

- Normal text should be at least `4.5:1` against its background.
- Large text, icons, and UI boundaries should be at least `3:1`.
- Mint can carry buttons, highlights, and active states, but small text should use Midnight Ink on light surfaces or near-white text on dark surfaces.

## Typography

Mimic uses rounded type to echo Mimo's soft shape:

- **Fredoka** for the product wordmark and major headings.
- **Nunito Sans** for documentation, navigation, code-adjacent UI, and longer reading.

The result should feel warm and approachable without making the reference pages harder to scan.
