# Mimic Multiplayer Brand Identity Research

Last reviewed: 2026-05-30

Scope: early visual identity for Mimic Multiplayer, including the Mimo mascot, logo/icon variants, colors, typography, voice, and GitHub Pages documentation styling direction.

Public-repo note: this document is intended to migrate into public documentation later. Do not add private file paths, unpublished asset locations, credentials, private deployment details, or user-specific notes.

## Source Inputs

- Product name: Mimic Multiplayer.
- Short name: Mimic.
- Mascot name: Mimo.
- Concept logo 1: Mimo shaped like a soft network icon with connected node-like points.
- Concept logo 2: Mimo shaped like a rounded letter M.
- Brand goal: playful, cute, approachable, and mascot-driven while still professional enough for a Godot developer tool and open-source GitHub project.

## Brand Position

Mimic Multiplayer is a small helper around Godot's native high-level multiplayer workflow. The brand should make multiplayer feel less intimidating without making the tool feel unserious.

The core brand idea is:

```text
Mimo is the shapeshifting Mimic mascot.
Mimic helps Godot scenes adapt into multiplayer-aware scenes.
```

Mimo should visually communicate shapeshifting, copying, morphing, networking, synchronization, replication, friendliness, and simplicity.

## Naming And Voice

Use these names consistently:

- Full product name: Mimic Multiplayer.
- Short product name: Mimic.
- Mascot name: Mimo.

Mimo changes shape, so use Mimo's name instead of gendered pronouns.

Preferred examples:

- Mimo can morph into network shapes.
- Mimo represents synchronization, replication, and adaptability.
- Mimo is the Mimic Multiplayer mascot.

Avoid:

- He is the mascot.
- She is the mascot.
- It is just a blob.

Mimic Multiplayer should sound simple, helpful, friendly, confident, developer-oriented, and lightly playful. Avoid overly corporate language, forced jokes, or cute copy that gets in the way of developer clarity.

Possible tagline:

```text
Drag-and-drop multiplayer replication for Godot.
```

Possible mascot phrase:

```text
Mimo morphs to match your multiplayer needs.
```

## Mascot Direction

Mimo is a playful slime-like creature that can copy, morph, and adapt into different shapes. This fits Mimic Multiplayer because the product is about making multiplayer replication feel flexible, automatic, and adaptable to different Godot nodes, objects, and gameplay needs.

Mimo should always feel:

- Rounded.
- Soft.
- Slime-like.
- Cute.
- Friendly.
- Simple.
- Professional enough for developer tooling.

Important visual rules:

- Use a thick dark outline.
- Use a mint/teal fill.
- Keep the eyes perfectly circular.
- Keep the face kawaii and simple.
- Keep the mouth close to the eyes.
- Prefer a flat two-color mark for primary logo/icon usage.
- Allow subtle depth only in larger marketing artwork, not in the core logo system.
- Avoid overly complex detail.
- Avoid sharp corners.
- Avoid thin outlines.
- Avoid making Mimo look like a monster, skull, or generic blob.
- Avoid mint-only icons when the outline is needed for recognition and contrast.

## Logo Variants

### Network-Shaped Mimo

The network-shaped variant forms Mimo into a soft connection graph. The rounded node-like points around the body immediately suggest multiplayer, synchronization, replication, and network links.

Recommended uses:

- GitHub repository avatar.
- Documentation favicon, simplified if needed.
- Multiplayer, networking, sync, or replication feature pages.
- Small icon usage where the mark needs to communicate networking quickly.
- Feature cards or diagrams that need a friendly network cue.

Design notes:

- Preserve the thick outline so the shape remains readable at small sizes.
- Keep the node ends rounded and friendly, not technical or angular.
- Simplify the number of interior curves if a favicon-size version becomes muddy.

### M-Shaped Mimo

The M-shaped variant forms Mimo into a rounded letter M. This version keeps the cute face and slime-like body while making the Mimic initial recognizable.

Recommended uses:

- Main brand mark.
- Documentation header logo.
- Landing page hero.
- Logo lockup.
- Product identity moments.
- Larger placements where the Mimic name should be the first read.

Design notes:

- Preserve the top center valley and lower rounded lobes so the M remains legible.
- Keep the face centered and simple.
- Use this variant when brand recognition matters more than the immediate networking metaphor.

### Default Usage Decision

- GitHub repo avatar: network-shaped Mimo.
- Documentation favicon: simplified network-shaped Mimo.
- Documentation header logo: M-shaped Mimo plus Mimic Multiplayer wordmark.
- Landing page hero: Mimo can be shown morphing between the M shape and the network shape.
- Feature cards: use small simplified Mimo/network marks sparingly.

## Logo Lockup Guidance

Preferred horizontal lockup:

```text
[Mimo icon] Mimic
            Multiplayer
```

Alternative compact lockup:

```text
[Mimo icon] Mimic Multiplayer
```

Recommended hierarchy:

- Mimo icon on the left.
- Mimic should be large, friendly, rounded, and prominent.
- Multiplayer should be smaller and more practical.
- Use Midnight Ink for the wordmark.
- Use Muted Text for the subtitle if softer hierarchy is needed.
- Use Mimic Mint as the icon fill and accent color.

Do not make the entire wordmark mint by default. Mint text on light backgrounds is too low contrast for small text.

## Core Color System

| Token | Value | Primary Uses | Notes |
| --- | --- | --- | --- |
| Mimic Mint | `#65E6B8` | Mimo body fill, primary accent, CTA background, active navigation, focus accents, documentation accent | Playful, slime-like, friendly, fresh, tech-adjacent. |
| Midnight Ink | `#10212B` | Mimo outline, eyes, mouth, logo text, headings, primary text, dark UI sections, button borders | Professional, stable, readable, balances the cute mascot. |
| Muted Text | `#49616B` | Secondary text, subtitles, captions, quieter navigation | Softer than Midnight Ink while remaining readable on light backgrounds. |
| Page Background | `#FAFCFB` | Documentation page background | Keeps pages clean and slightly warmer than pure white. |
| Soft Mint Background | `#E9FFF7` | Callouts, gentle highlights, subtle brand panels | Use behind dark text, not as text color. |
| Card Background | `#FFFFFF` | Cards, tables, framed content blocks | Use with Border for separation. |
| Border | `#DDE8E5` | Dividers, cards, tables, inputs | Low-noise structure color. |
| Accent Hover | `#4FD9A8` | Hover state for mint buttons and accents | Slightly deeper mint for interaction feedback. |
| Focus Ring | `rgba(101, 230, 184, 0.45)` | Keyboard focus outlines and form focus states | Pair with visible outlines or dark borders when needed. |

Recommended CSS variables:

```css
:root {
	--mimic-mint: #65E6B8;
	--mimic-ink: #10212B;

	--mimic-text: #10212B;
	--mimic-muted-text: #49616B;

	--mimic-page-bg: #FAFCFB;
	--mimic-soft-mint-bg: #E9FFF7;
	--mimic-dark-bg: #10212B;

	--mimic-border: #DDE8E5;
	--mimic-card-bg: #FFFFFF;

	--mimic-accent: #65E6B8;
	--mimic-accent-hover: #4FD9A8;
	--mimic-focus-ring: rgba(101, 230, 184, 0.45);

	--mimic-font-display: "Fredoka", sans-serif;
	--mimic-font-body: "Nunito Sans", sans-serif;
}
```

## Accessibility Notes

Checked contrast ratios for the initial palette:

- Midnight Ink on Mimic Mint: `10.64:1`.
- Midnight Ink on Page Background: `15.99:1`.
- Muted Text on Page Background: `6.36:1`.
- Mimic Mint on Page Background: `1.50:1`.

Good combinations:

- Midnight Ink text on Mimic Mint.
- Mimic Mint icon or accents on Midnight Ink.
- Midnight Ink text on Page Background.
- Muted Text on Page Background for secondary copy.
- Mimic Mint as a decorative accent with dark text nearby.

Avoid:

- Mimic Mint as small text on white or near-white backgrounds.
- Thin outlines.
- Low-contrast mint-only icons.
- Relying on color alone to communicate important states.

## Typography

### Display And Logo Font

Recommended font: Fredoka.

Suggested usage:

- Main Mimic wordmark.
- Large marketing headings.
- Hero titles.
- Brand-heavy labels.

Suggested weights:

- `600` for the Mimic wordmark.
- `500` or `600` for large headings.
- `700` only where extra impact is needed.

Reason: Fredoka is rounded, playful, friendly, and matches Mimo's soft slime-like shape. It can feel cute without becoming too childish when paired with a cleaner documentation font.

### Documentation And UI Font

Recommended font: Nunito Sans.

Suggested usage:

- Documentation body text.
- Navigation.
- Buttons.
- Cards.
- Tables.
- Captions.
- GitHub Pages content.

Suggested weights:

- `400` for body text.
- `500` for secondary UI.
- `600` for navigation and buttons.
- `700` or `800` for section labels.

Reason: Nunito Sans keeps documentation readable, clean, and friendly. It pairs well with Fredoka because it is rounded but more practical for long-form docs.

### Technical Alternative

Alternative documentation font: Manrope.

Use Manrope instead of Nunito Sans if the documentation site needs to feel more like a serious developer tool and less mascot-forward.

Current recommendation: use Fredoka for brand/logo/display and Nunito Sans for docs/body/UI.

Recommended Google Fonts include:

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Fredoka:wght@500;600;700&family=Nunito+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
```

## GitHub Pages Styling Direction

The documentation site should feel friendly, clean, lightweight, developer-focused, slightly playful, not overly corporate, and not overly childish.

Suggested base styling:

```css
body {
	font-family: var(--mimic-font-body);
	color: var(--mimic-text);
	background: var(--mimic-page-bg);
}

h1,
h2,
.brand-logo-text {
	font-family: var(--mimic-font-display);
	color: var(--mimic-ink);
}

a {
	color: var(--mimic-ink);
	text-decoration-color: var(--mimic-mint);
	text-decoration-thickness: 2px;
}

a:hover {
	color: var(--mimic-accent-hover);
}

.button-primary {
	background: var(--mimic-mint);
	color: var(--mimic-ink);
	border: 2px solid var(--mimic-ink);
	border-radius: 999px;
	font-weight: 700;
}

.button-primary:hover {
	background: var(--mimic-accent-hover);
}
```

Documentation should use Mimo as a recognizable brand signal without letting mascot art crowd reference material. Keep pages readable first, then add mascot warmth through the header, favicon, homepage, feature callouts, and occasional empty states.

## Future Asset Plan

When final logo files are supplied, prefer storing web-ready brand assets under the future documentation asset tree:

```text
docs/assets/logo/mimo_network.svg
docs/assets/logo/mimo_network.png
docs/assets/logo/mimo_m.svg
docs/assets/logo/mimo_m.png
docs/assets/logo/mimic_logo_lockup.svg
docs/assets/logo/favicon.svg
docs/styles/brand.css
```

Asset naming should stay snake_case to match the repository style.

Preferred deliverables:

- Editable SVG source for each logo variant.
- PNG exports for GitHub/social contexts.
- Simplified favicon SVG.
- Dark-background and light-background checks for each mark.
- A horizontal lockup with Mimo plus Mimic Multiplayer.

## Final Brand Decisions For Now

- Mimo is the shapeshifting Mimic mascot.
- Mimo should be referred to as Mimo, not he, she, or it.
- Mimo uses `#65E6B8` for the body fill.
- Mimo uses `#10212B` for the outline, eyes, and mouth.
- Mimo has two main icon shapes: network-shaped and M-shaped.
- The network-shaped Mimo is best for repo avatar, favicon, and networking-specific contexts.
- The M-shaped Mimo is best for the main brand mark, documentation header, logo lockup, and larger brand placements.
- The logo wordmark should use `#10212B`.
- Fredoka should be used for display/logo typography.
- Nunito Sans should be used for documentation/body typography.
- GitHub Pages should use `#65E6B8` as the main accent and `#10212B` as the main text/logo color.
- The style should remain playful and cute, but still professional for a developer multiplayer tool.

## Open Questions

- Should the final wordmark be pure Fredoka text or a custom adjusted logo type?
- Does the network-shaped mark need a simplified small-size version separate from the full mascot face?
- Should docs include small Mimo expressions or only the two primary logo shapes at first?
- Should the final GitHub Pages homepage show a morphing animation between the M shape and network shape, or keep the brand static for the MVP?
