# Design tokens

The full palette is **7 color custom properties + 1 font stack**. Both themes share the property names; only values differ. Switching themes is a single attribute change on `<html>`.

## CSS

```css
/* Dark = default. Tailwind 4: put inside @theme {}. Plain CSS: put inside :root {}. */
--color-bg: #000000;
--color-surface: #0B0B0C;
--color-border: #1A1A1C;
--color-border-hi: #2A2A2D;
--color-text: #F4F4F5;
--color-muted: #8A8A91;
--color-dim: #5A5A60;

--font-mono: "Geist Mono", ui-monospace, SFMono-Regular, Menlo, monospace;
```

```css
/* Light overrides. Tailwind 4 + plain CSS: same selector. */
[data-theme="light"] {
  --color-bg: #FFFFFF;
  --color-surface: #F7F7F8;
  --color-border: #E4E4E7;
  --color-border-hi: #D4D4D8;
  --color-text: #0A0A0B;
  --color-muted: #71717A;
  --color-dim: #A8A8B0;
}
```

## What each token does

| Token | Dark | Light | Used by |
|-------|------|-------|---------|
| `--color-bg` | `#000000` | `#FFFFFF` | `<html>`/`<body>` background. |
| `--color-surface` | `#0B0B0C` | `#F7F7F8` | Install boxes, code blocks, inline `<code>`, anything that needs a slightly elevated background. |
| `--color-border` | `#1A1A1C` | `#E4E4E7` | Hairline borders, hr, divider lines, table cell borders. |
| `--color-border-hi` | `#2A2A2D` | `#D4D4D8` | Hover-state borders, table header borders, slightly stronger dividers. |
| `--color-text` | `#F4F4F5` | `#0A0A0B` | Primary body text, headings, link text at rest. |
| `--color-muted` | `#8A8A91` | `#71717A` | Secondary text — section labels, descriptions under headings, the `light/dark` toggle, github-style links. |
| `--color-dim` | `#5A5A60` | `#A8A8B0` | Tertiary — bracketed `[category]` and `[date]` chips, the `→` link arrow at rest, scrollbar track, the toggle's inactive state. |

## Hierarchy

The three text colors form a deliberate brightness ladder: **text** (most prominent) → **muted** (secondary) → **dim** (tertiary). Same ladder works in both themes — light mode inverts dim/text but keeps the same *relative* contrast.

Hover states almost always promote one level (dim → muted, muted → text). They never change hue. Never introduce a 4th color "just for hover."

## The font

`Geist Mono` is loaded via Google Fonts on the source site (preconnect + stylesheet `<link>`):

```html
<link rel="preconnect" href="https://fonts.googleapis.com" />
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
<link
  href="https://fonts.googleapis.com/css2?family=Geist+Mono:wght@400;500;600&display=swap"
  rel="stylesheet"
/>
```

**Self-hosting trade-off.** Loading from Google Fonts adds a third-party request per pageview (privacy + reliability cost). For zero-third-party setups, download Geist Mono from [vercel/geist-font on GitHub](https://github.com/vercel/geist-font/) and self-host the woff2 files via `@font-face`. Same fallback stack applies — the `ui-monospace, SFMono-Regular, Menlo` chain renders an acceptable approximation if the font fails to load.

If using Next.js, prefer `next/font/google` (or `next/font/local` for self-hosted) — handles preloading, layout-shift prevention, and CSS variables automatically. See `stack-nextjs-tailwind.md`.

## Color-scheme metadata

Set `<meta name="theme-color" content="#000000" />` in `<head>` so mobile browser chrome (Safari address bar, Android task switcher) tints to match the dark theme. For light-mode users, browsers usually adapt this automatically when you also include the CSS:

```css
html { color-scheme: dark; }
[data-theme="light"] html { color-scheme: light; }
```

This signals to native scrollbars/form controls to render in the matching mode.
