# Brand

Mimic Multiplayer's mascot is **Mimo**, a small shapeshifting character that can morph between playful logo shapes. Mimo gives the project a friendlier face for a topic that often feels intimidating: multiplayer.

The mascot idea matches the product idea. Mimic helps a Godot scene adapt into a network-aware scene while staying close to Godot's built-in multiplayer tools.

## Mimo Shapes

Mimo currently appears in two concept shapes:

- **Network Mimo** looks like a soft connection graph. This version hints at peers, synchronization, replication, and network links.
- **M-shaped Mimo** turns the mascot into the first letter of Mimic. This version works best for headers, lockups, and places where the product name should be the first read.

Both shapes use the same simple face, rounded body, mint fill, and dark outline so Mimo stays recognizable across sizes.

## Assets

The source mascot assets live in `brand/`.

| Asset | Use |
| --- | --- |
| `mimo_net.svg` | Scalable Network Mimo icon |
| `mimo_m.svg` | Scalable M-shaped Mimo icon |
| `mimo_net.png` | Original Network Mimo raster source |
| `mimo_m.png` | Original M-shaped Mimo raster source |
| `logos/logo_m_hero_700.svg` | M-shaped Mimo hero wordmark |
| `logos/logo_net_stacked_700.svg` | Network Mimo stacked wordmark |
| `logos/logo_net_horizontal_700.svg` | Network Mimo horizontal wordmark |

The SVG files use a `512x512` viewBox, no fixed display size, and only Mimic Mint plus Midnight Ink. Both SVGs share the same face proportions so Mimo remains recognizable while each body shape positions the face on its own visual center. The body outline uses a `12` unit ink width in the SVG viewBox, and the smile uses a `24` unit stroke so it reads at exactly double the outline weight.

The logo SVGs use outlined Fredoka wordmark shapes, so they do not depend on local font installation. Network Mimo logos keep the full `MIMIC` word. M-shaped Mimo logos replace the first `M`, so the visible wordmark text is `IMIC`.

Full-name logo variants add `MULTIPLAYER` below the primary wordmark with the same outlined Fredoka weight as the main line. The subtitle is width-matched to the primary text line: the full `MIMIC` word for Network Mimo logos and the mascot-plus-`IMIC` lockup for M-shaped Mimo logos.

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
| Universal Wordmark | `#5B7680` | Logo text that needs to sit on both light and dark brand surfaces |
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
