---
name: minimal-mono-design
description: Apply a minimal monochrome design system — Geist Mono throughout, light/dark/system theme via CSS custom properties with FOUC-free init, 640px centered column, terminal-styled install boxes with copy-to-tick cross-fade, theme toggle, and prose-md README rendering. Default stack is Astro + Tailwind 4 + Geist Mono; explicit guidance for Next.js (App Router), plain HTML/CSS, and any other CSS-based framework. Use when building developer-tool sites, plugin marketplaces, documentation-style listings, dev portfolios, or any minimalist monospace site with a dark/light toggle. Triggers on mentions of monospace developer site, marketplace listing UI, minimalist dark/light theme, Geist Mono site, dev documentation site, plugin showcase site, or "design system from HP-00 marketplace".
---

# Minimal Mono Design System

A coherent monochrome design system extracted from the [HP-00 plugin marketplace site](https://huzayfah.here.now/plugins/). Apply this when the user wants to build a minimalist developer-tool site, a plugin showcase, a documentation-style listing, or any monospace site with a clean dark/light toggle.

## Philosophy (non-negotiable)

1. **Mono throughout.** Geist Mono for headings, body, install commands, navigation, code — everything. No decorative sans serif.
2. **Single column.** 640px centered max-width. Content scales down gracefully; never spreads to full-width.
3. **Color is information, not decoration.** No accent colors by default — text and background do the work. Hover/active states use brightness shifts (dim → text), never hue shifts.
4. **FOUC-free theme switching.** The theme is set on `<html>` *before* the body paints, via an inline `<script>` in `<head>`.
5. **Generous spacing.** Vertical rhythm comes from large section margins, not borders/dividers between every element.
6. **No client JS for static content.** Theme toggle and copy-to-clipboard are the only client-side scripts. Everything else is server-rendered/static HTML.

## Stack defaults

**Default to Astro + Tailwind 4 + Geist Mono** for new projects, especially anything content-heavy or static (marketplaces, docs, listings, portfolios). This is the stack the source site uses; the deepest reference is `references/stack-astro-tailwind.md`.

**Switch stacks only when justified:**
- **Next.js (App Router) + Tailwind 4** — when the site needs server actions, API routes, dynamic React components, or integrates with an existing Next.js app. See `references/stack-nextjs-tailwind.md`.
- **Plain HTML + CSS** — when zero JS / single file matters more than authoring ergonomics (single landing page, README-as-a-site, simple demo). See `references/stack-plain-html.md`.
- **Anything else** (SvelteKit, Vue, Remix, 11ty, Hugo, Jekyll) — use `references/stack-generic.md` for stack-agnostic tokens + class names + theme attribute pattern.

If the user is already in a project, **detect the stack from the existing `package.json` / file structure and pick the matching reference** rather than asking. Only ask if the stack is ambiguous or the project is greenfield.

## Tokens at a glance

The full design system is **7 CSS custom properties + 1 font stack**. Both themes share the same property names; only values differ.

**Dark (default):**
```css
--color-bg: #000000;
--color-surface: #0B0B0C;
--color-border: #1A1A1C;
--color-border-hi: #2A2A2D;
--color-text: #F4F4F5;
--color-muted: #8A8A91;
--color-dim: #5A5A60;
--font-mono: "Geist Mono", ui-monospace, SFMono-Regular, Menlo, monospace;
```

**Light overrides:**
```css
--color-bg: #FFFFFF;
--color-surface: #F7F7F8;
--color-border: #E4E4E7;
--color-border-hi: #D4D4D8;
--color-text: #0A0A0B;
--color-muted: #71717A;
--color-dim: #A8A8B0;
```

Full annotated token reference + self-host vs Google-Fonts trade-off: `references/tokens.md`.

## Theme system

- `data-theme="dark"` or `data-theme="light"` lives on `<html>`.
- An **inline `<script>` in `<head>`** reads `localStorage.theme` (or falls back to `prefers-color-scheme`) and sets `data-theme` *before* the body paints. This eliminates FOUC.
- A `light / dark` toggle component lets users override; choice persists in `localStorage`.
- When no explicit choice is stored, the page **listens for OS-level `prefers-color-scheme` changes live** and updates without a refresh.

Full init script + toggle markup + handler: `references/theme-system.md`.

## Components

All components are mono, monochrome, and adapt automatically via the CSS custom properties.

- **Install box** — `$ command [□]` row with two SVGs cross-fading (copy → tick) when the button is clicked.
- **Theme toggle** — `light / dark` text buttons with `aria-pressed` for active state. Active state uses `--color-muted` so it visually matches inline links.
- **Plugin-list grid** — `display: grid` on the parent + `display: contents` on each row, so columns auto-align across all rows even when rows have variable-width title content.
- **Section label** — small muted gray text marking section boundaries (e.g., `Install`, `Plugins`, `Source`).
- **Link with arrow** — text link with a dim `→` glyph that brightens on hover (alongside the link text itself).
- **Eyebrow tag** *(optional, currently unused on the source site)* — small uppercase label with a `●` dot prefix for hero-style section markers.

Full component markup + CSS for each: `references/components.md`.

## Layout primitives

- **Centered column**: `.col { width: 100%; max-width: 640px; margin-inline: auto; padding-inline: 1.5rem; }`
- **Section spacing**: `.section { margin-top: 2.75rem; }` (or `.section--tight { margin-top: 2rem; }` for closer pairs)
- **BASE_URL normalization** for subpath deployments — see the helper in `references/stack-astro-tailwind.md`. Critical when the site is mounted at e.g. `domain.com/<sub>/` instead of the root.

## Prose styling for rendered markdown

A `.prose-md` class styles markdown converted to HTML (via `marked`, `remark`, `markdown-it`, etc.) so README/blog content matches the rest of the design system. Headings use mono with `border-top` rules on H2; code/pre blocks have surface-tone backgrounds; tables use uppercase mono headers; lists, blockquotes, hr, img, strong all themed.

Full `.prose-md` CSS: `references/prose-md.md`.

## How to apply

When invoked, follow this sequence:

1. **Detect or confirm the stack.** Read the user's `package.json` or ask; pick the matching `references/stack-*.md`.
2. **Write the design tokens.** Copy `references/tokens.md` into the user's stylesheet (or framework-equivalent location specified in the chosen stack reference).
3. **Wire the theme system.** Add the FOUC-free init script + theme toggle component per `references/theme-system.md`, located per the chosen stack.
4. **Add the components the user actually needs.** Don't dump every component; pick from `references/components.md` based on what they're building. Install box for install commands; plugin-list grid for listings; etc.
5. **Add `.prose-md` if rendering markdown.** Skip if the site has no rendered-markdown surface.
6. **Stack-specific extras.** If using Astro/Next.js with subpath deployment, apply the BASE_URL normalization helper.

Keep the user's existing code intact — this is a design system to *layer on*, not a project to scaffold from scratch.

## When NOT to use

- The user wants **brand color in the design** (hue-based accents). This system is intentionally monochrome. Recommend a different design system or extending this one with a single accent variable (and warn that it changes the visual language).
- The user wants **dense data UIs** (tables with many columns, dashboards). This design is for content/listing sites. Different layout primitives needed.
- The user already has a **strong existing design system** (Material, Chakra, shadcn/ui). Tokens may conflict; suggest only extracting individual patterns (e.g., the install box) rather than wholesale adoption.

## References

| File | Read when |
|------|-----------|
| `references/tokens.md` | You need the exact CSS custom properties for both themes. |
| `references/theme-system.md` | Wiring the FOUC-free init script + light/dark toggle. |
| `references/components.md` | Building the install box, theme toggle, plugin-list grid, or other primitives. |
| `references/prose-md.md` | The site renders markdown content (READMEs, blog posts) and you need consistent prose styling. |
| `references/stack-astro-tailwind.md` | **Default.** Greenfield content-heavy site, or user is already on Astro. |
| `references/stack-nextjs-tailwind.md` | User is on Next.js (App Router). |
| `references/stack-plain-html.md` | Single-file site, zero-JS, demo, or README-as-a-site. |
| `references/stack-generic.md` | Any other framework (SvelteKit, Vue, Remix, 11ty, Hugo, Jekyll, plain CSS). |
