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

The SVG files use a `512x512` viewBox, no fixed display size, and only Mimic Mint plus Midnight Ink. Both SVGs share the same face geometry so Mimo remains recognizable while the body shape changes.

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
