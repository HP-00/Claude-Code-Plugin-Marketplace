# Minimal Mono Design System

A coherent monochrome design system for developer-tool sites — Geist Mono throughout, light/dark/system theming via CSS custom properties with FOUC-free init, terminal-styled install boxes, and prose styling for rendered markdown. The same design system used by [HP-00/Plugins](https://huzayfah.here.now/plugins/), packaged as a reusable Skill.

## Installation

```shell
/plugin marketplace add HP-00/Claude-Code-Plugin-Marketplace
/plugin install minimal-mono-design@hp-00-plugins
```

## How to use

The plugin's skill auto-discovers when you describe building a site that fits the design system. Trigger phrases include:

- "Build a minimalist developer-tool site"
- "Make a plugin marketplace listing UI"
- "Create a dev documentation site with dark/light"
- "I want a Geist Mono-styled monospace site"
- "Build a clean dev portfolio with light/dark"

When triggered, the skill walks through the design tokens + theme system + components, asks about your stack (or detects it from the project), and writes the appropriate code.

You can also invoke it explicitly: ask Claude to "use the minimal-mono-design skill".

## What you get

- **Design tokens** — 7 CSS custom properties for both dark (default) and light themes.
- **Theme system** — `data-theme` attribute on `<html>`, FOUC-free inline init script, `light / dark` toggle that defaults to system preference and tracks OS-level changes when no explicit choice is stored.
- **Typography** — Geist Mono throughout, sized for readability with tabular numerals for dates/numbers.
- **Layout primitives** — 640px centered column, generous vertical spacing, `BASE_URL` normalization for subpath deployments.
- **Components** — `Eyebrow` tag, `InstallBox` (terminal command + copy/check cross-fade), `ThemeToggle`, plugin-list grid (using `display: contents` for cross-row column alignment), section label, link with arrow, copy button.
- **Prose styling** — `.prose-md` class for rendering README markdown consistently (headings, code, pre, lists, tables, blockquotes, strong, links, images, hr, figures).

## Stacks supported

| Stack | When to use |
|-------|-------------|
| **Astro + Tailwind 4 + Geist Mono** | Default. Optimal for content-heavy / static sites. Mirrors this site's exact stack. |
| **Next.js (App Router) + Tailwind 4** | When you need server components, API routes, or to integrate with an existing React app. |
| **Plain HTML/CSS** | Zero-JS, single-file. README-as-a-site, single landing page, simple demos. |
| **Any other framework** | Generic guidance for SvelteKit, Vue, Remix, 11ty, Hugo, etc. |

## Skill structure

```
skills/minimal-mono-design/
├── SKILL.md
└── references/
    ├── tokens.md              # CSS custom properties for dark + light
    ├── theme-system.md        # FOUC-free init + toggle component
    ├── components.md          # Eyebrow, InstallBox, ThemeToggle, etc.
    ├── prose-md.md            # Rendered-markdown styling
    ├── stack-astro-tailwind.md   # default
    ├── stack-nextjs-tailwind.md
    ├── stack-plain-html.md
    └── stack-generic.md
```

## License

MIT — see the marketplace root `LICENSE`.
