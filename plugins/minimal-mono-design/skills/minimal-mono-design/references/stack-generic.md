# Stack: any other framework (SvelteKit / Vue / Remix / 11ty / Hugo / Jekyll / etc.)

Use when the user is on a framework not covered by the explicit references. The patterns are stack-agnostic — only the implementation glue changes.

## What's stack-agnostic vs framework-specific

**Stack-agnostic (copy verbatim):**
- All design tokens (`tokens.md`) — pure CSS custom properties.
- All component CSS (`components.md`) — class-based, no framework hooks.
- Theme attribute pattern — `data-theme="light"` / `data-theme="dark"` on `<html>`, switching by toggling that attribute.
- Behavior contract (`theme-system.md`) — first-visit follows system pref, click stores explicit choice, system changes tracked when no explicit choice.

**Framework-specific (translate to your stack):**
- Where the FOUC-free init `<script>` lives in `<head>` (depends on framework's head/layout escape hatch).
- Where the global stylesheet imports go.
- How components get their state + click handlers (React state, Svelte stores, Vue refs, vanilla DOM, etc.).
- Static asset paths and URL helpers for subpath deployments.

## Translating the FOUC-free init script

The constraint: must run **before** the first paint of `<body>`. Inline `<script>` in `<head>` is the universal pattern; how it's authored differs:

| Framework | Pattern |
|-----------|---------|
| **SvelteKit** | `<script>` block in `src/app.html` `<head>`. Same JS as the source site. |
| **Vue (Nuxt)** | `app.head.script` array in `nuxt.config.ts` with `innerHTML` set; or use `<Script>` in `default.vue` layout — but only `useHead` placement before paint will work. The cleanest is editing `app.html` if Nuxt exposes one. |
| **Remix** | `<script>` block inside `<Meta />` / `<Links />` siblings in `app/root.tsx`'s `<head>`. Use `dangerouslySetInnerHTML`. |
| **11ty** | Static HTML — paste the `<script>` directly in `_includes/base.html` `<head>`. |
| **Hugo** | Same — paste in `layouts/_default/baseof.html` `<head>` block. |
| **Jekyll** | Same — paste in `_includes/head.html`. |
| **Astro** | `<script is:inline>` in `Base.astro` (the `is:inline` is critical). |
| **Next.js** | `dangerouslySetInnerHTML` on a `<script>` in `app/layout.tsx` `<head>`. |

The script body itself is identical across all of these — see `theme-system.md`.

## Translating the toggle handler

Same JS works in any framework. Two integration shapes:

**Shape A — vanilla DOM** (works everywhere)
- Mount a regular `<script>` after the body. The script queries `[data-theme-set]` buttons and wires up listeners.
- Pros: zero framework dependency. Same script in every framework.
- Cons: doesn't track component lifecycle (e.g., if Svelte/React re-renders the toggle, the listener becomes orphaned).

**Shape B — framework-native component**
- React/Vue/Svelte: a Client Component owns its `aria-pressed` state via the framework's reactivity. The handler updates `data-theme` on `<html>` + `localStorage`.
- Pros: clean component lifecycle.
- Cons: rewrite per framework.

For SvelteKit/Vue/Remix, prefer Shape B. For 11ty/Hugo/Jekyll, Shape A (since they don't have a component model). React-flavored example is in `stack-nextjs-tailwind.md`; Svelte and Vue port directly.

## Stylesheet placement

| Framework | Where the global CSS lives |
|-----------|---------------------------|
| SvelteKit | `src/app.css`, imported in `src/routes/+layout.svelte`. |
| Vue (Nuxt) | `assets/css/main.css`, registered in `nuxt.config.ts` `css: []`. |
| Remix | `app/styles/global.css`, imported in `app/root.tsx` via `links()` export. |
| 11ty | `src/_includes/styles.css` and reference via `<link>` in `base.html`. |
| Hugo | `assets/css/main.css`, processed via `resources.Get` + `toCSS` if using PostCSS, or just `<link>` from static. |
| Jekyll | `assets/css/main.scss` (or `.css`), reference via `<link>`. |

## Subpath deployments

If the site lives at `domain.com/sub/`:

- **All framework `<a>` href values** must be prefixed with the subpath. Use the framework's URL helper (Astro `Astro.url`, Next.js `Link` with `basePath`, SvelteKit `base` from `$app/paths`, etc.).
- **Static asset references** in `<head>` (favicon, fonts) — must include the subpath manually unless the framework auto-prefixes.
- **CSS asset URLs** (`url('/path/to.png')`) — most build pipelines auto-prefix when `base` is configured. Test.

## Checklist for any framework

When applying this design system to a new stack:

1. ☐ Drop the design-tokens CSS into the global stylesheet.
2. ☐ Wire the FOUC-free init script in `<head>`. Verify by hard-refreshing in light-mode-OS — the page should render light immediately, no dark flash.
3. ☐ Add the toggle component using the framework's component model + the `data-theme-set` attribute pattern.
4. ☐ Add only the components you need (`InstallBox`, `ThemeToggle`, plugin-list grid, etc.). Skip the rest.
5. ☐ Confirm `prefers-color-scheme` is honored on first visit (no stored choice) and that switching OS dark/light updates the page live.
6. ☐ Confirm `localStorage.theme` persists across reloads.
7. ☐ Confirm clicking the toggle updates both the page AND the `aria-pressed` state on the buttons.
8. ☐ If your site has rendered markdown anywhere, add `.prose-md` styling.

## When this generic guidance falls short

Most modern frameworks have a head escape hatch and a CSS import path — these patterns translate cleanly. The hairy cases are:

- **Frameworks with strict CSP** (Content Security Policy disallowing inline scripts) — you'll need to ship the FOUC-free init as a built asset with a hash and reference it via `<script src="...">` instead of inline. The script must still load before paint, which means you can't use `defer`/`async`. Performance-test this — it can introduce a tiny render-blocking phase.
- **Server-only rendering with no client JS** (some Hugo / Jekyll setups) — you can ship the toggle as a UI component but it won't actually work without JS. In those cases, skip the toggle entirely and rely on `prefers-color-scheme` purely (no opt-in for users to override). Document this trade-off in your README.
- **Frameworks with rigid head ordering** (some Nuxt configurations) — you may need to use a workaround like `useHead` with `tagPriority` to ensure the init script runs before any other CSS/JS in `<head>`.
