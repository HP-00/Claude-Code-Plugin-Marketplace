# Stack: Astro + Tailwind 4 (default)

The deepest reference. This is the stack the source site uses; mirror it as the default for greenfield content-heavy sites.

## Why this stack

- **Astro** ships zero JS by default for static content; perfect for listing/docs/portfolio sites.
- **Tailwind 4** uses CSS-based config (`@theme {}`), which fits a small custom-property design system without the JS-config overhead of v3.
- **Geist Mono** loads via Google Fonts (or self-hosted) — both options shown.
- **`getStaticPaths()`** auto-generates per-item routes from a data source (JSON file, markdown collection, etc.).

## Pinned dependencies

These are the exact versions the source site uses:

```json
{
  "dependencies": {
    "astro": "6.3.1",
    "@tailwindcss/vite": "4.3.0",
    "tailwindcss": "4.3.0",
    "marked": "18.0.3"
  },
  "pnpm": {
    "onlyBuiltDependencies": ["esbuild", "sharp"]
  }
}
```

The `pnpm.onlyBuiltDependencies` block is required if installing with pnpm — `esbuild` and `sharp` (transitive deps of Astro) need their postinstall scripts to fetch platform binaries, and pnpm 11+ ignores them by default unless allowlisted.

`marked` is only needed if you're rendering markdown content (READMEs, blog posts) at build time — drop it otherwise.

## File structure

```
site/
├── astro.config.mjs
├── package.json
├── tsconfig.json
├── public/
│   └── favicon.svg
└── src/
    ├── styles/global.css      # design tokens + components + .prose-md
    ├── layouts/Base.astro     # head, theme init script, copy/toggle JS
    ├── components/
    │   ├── InstallBox.astro
    │   └── ThemeToggle.astro
    └── pages/
        ├── index.astro
        └── [slug].astro       # dynamic route per item
```

## astro.config.mjs

```js
import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  site: 'https://your-domain.com',
  // Optional: remove `base` if you mount at the domain root.
  // Keep it if your site is served under a subpath like /<sub>/.
  base: '/sub',
  trailingSlash: 'ignore',
  vite: {
    plugins: [tailwindcss()],
  },
  build: {
    inlineStylesheets: 'auto',
  },
});
```

## global.css (Tailwind 4 entry)

```css
@import "tailwindcss";

@theme {
  --color-bg: #000000;
  --color-surface: #0B0B0C;
  --color-border: #1A1A1C;
  --color-border-hi: #2A2A2D;
  --color-text: #F4F4F5;
  --color-muted: #8A8A91;
  --color-dim: #5A5A60;

  --font-mono: "Geist Mono", ui-monospace, SFMono-Regular, Menlo, monospace;
}

[data-theme="light"] {
  --color-bg: #FFFFFF;
  --color-surface: #F7F7F8;
  --color-border: #E4E4E7;
  --color-border-hi: #D4D4D8;
  --color-text: #0A0A0B;
  --color-muted: #71717A;
  --color-dim: #A8A8B0;
}

@layer base {
  html {
    background: var(--color-bg);
    color: var(--color-text);
    font-family: var(--font-mono);
    font-size: 14.5px;
    line-height: 1.6;
    -webkit-font-smoothing: antialiased;
    color-scheme: dark;
  }
  /* ... rest of base styles, scrollbar, etc. */
}

@layer components {
  /* All component classes from references/components.md and references/prose-md.md */
}
```

The full CSS file is ~420 lines on the source site. Build it up by copying:
1. `tokens.md` (the @theme block + light overrides)
2. `components.md` (the .install, .copy-btn, .plugin-list, .label, .link, .theme-toggle classes)
3. `prose-md.md` (the .prose-md class)

## Base.astro (head + theme init + global JS)

```astro
---
import "../styles/global.css";

interface Props {
  title: string;
  description?: string;
}

const { title, description = "Your tagline" } = Astro.props;
const fullTitle = title === "Site Name" ? title : `${title} — Site Name`;
const canonical = new URL(
  Astro.url.pathname,
  Astro.site ?? "https://your-domain.com"
).toString();

// BASE_URL is "/sub" (no trailing slash) when base is "/sub"; force trailing
// slash so callers can do `${base}favicon.svg` safely.
const baseRaw = import.meta.env.BASE_URL;
const base = baseRaw.endsWith("/") ? baseRaw : baseRaw + "/";
---

<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>{fullTitle}</title>
    <meta name="description" content={description} />
    <link rel="canonical" href={canonical} />
    <link rel="icon" type="image/svg+xml" href={`${base}favicon.svg`} />
    <meta name="theme-color" content="#000000" />
    <meta property="og:title" content={fullTitle} />
    <meta property="og:description" content={description} />
    <meta property="og:type" content="website" />
    <meta property="og:url" content={canonical} />
    <meta name="twitter:card" content="summary" />

    <!-- Geist Mono via Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link
      href="https://fonts.googleapis.com/css2?family=Geist+Mono:wght@400;500;600&display=swap"
      rel="stylesheet"
    />

    <!-- FOUC-free theme init: see theme-system.md -->
    <script is:inline>
      (function () {
        try {
          const stored = localStorage.getItem("theme");
          if (stored === "light" || stored === "dark") {
            document.documentElement.dataset.theme = stored;
            return;
          }
          const prefersLight =
            window.matchMedia &&
            window.matchMedia("(prefers-color-scheme: light)").matches;
          document.documentElement.dataset.theme = prefersLight ? "light" : "dark";
        } catch (e) {
          document.documentElement.dataset.theme = "dark";
        }
      })();
    </script>
  </head>
  <body>
    <slot />

    <!-- Copy buttons + theme toggle wiring: see components.md + theme-system.md -->
    <script>
      // (Inline the handlers from components.md "JS handler" + theme-system.md "Toggle handler")
    </script>
  </body>
</html>
```

## Subpath deployments

If serving under a subpath (`domain.com/sub/`), Astro generates asset paths with the base prefix automatically (CSS, JS, images imported via `import`). But **hardcoded `<a href="/...">` and `<link href="/...">` are NOT auto-prefixed** — you have to use `${base}`-prefixed paths.

Helper pattern in any `.astro` file:

```ts
const baseRaw = import.meta.env.BASE_URL;
const base = baseRaw.endsWith("/") ? baseRaw : baseRaw + "/";
```

Then write:
- `<a href={base}>` for the home link (instead of `href="/"`)
- `<a href={`${base}${slug}`}>` for internal page links (instead of `href={`/${slug}`}`)
- `<link href={`${base}favicon.svg`}>` (instead of `href="/favicon.svg"`)

If your site is at the root (no `base`), the helper still produces `/`, so the pattern is portable.

## Dynamic per-item routes

For a marketplace or listing, define `pages/[slug].astro` with `getStaticPaths()`:

```astro
---
import Base from "../layouts/Base.astro";
import { getItems, type Item } from "../data/items";

export async function getStaticPaths() {
  return getItems().map((item) => ({
    params: { slug: item.slug },
    props: { item },
  }));
}

interface Props { item: Item; }
const { item } = Astro.props;
---

<Base title={item.name} description={item.description}>
  <main class="col">
    <!-- Render the item using design-system components -->
  </main>
</Base>
```

The data source is yours to define — JSON file, content collection, external API, etc.

## Build + deploy

```bash
pnpm install
pnpm build      # → dist/
pnpm preview    # local preview at localhost:4321
```

Deploy `dist/` to any static host (Cloudflare Pages, Vercel, Netlify, GitHub Pages, here.now, etc.). The source site uses GitHub Actions + here.now — but the `dist/` output is host-agnostic.

## Common pitfalls (lessons from building the source site)

- **`pnpm install` ignoring esbuild/sharp builds**: add `pnpm.onlyBuiltDependencies` to package.json (above), then `pnpm install` again. Without this, `pnpm build` fails because Astro can't run Vite/Sharp.
- **`{` in markdown gets parsed as JSX**: in `.astro` files, single curly braces in markup are JS expressions. To render literal `{some, thing}` in HTML, escape as `&#123;some, thing&#125;` or wrap in a string template.
- **Long install commands push the page wider on narrow screens**: see the `min-width: 0` note in `components.md` for `.install__cmd`.
- **Plugin row alignment broken across rows**: the parent `.plugin-list` must be `display: grid` with `display: contents` on rows. See `components.md`.
- **Subpath deploy serves correctly at slug URL but not at handle/subdomain root**: this is a feature of using `base` in astro.config.mjs — assets are prefixed for the subpath. The bare slug URL won't have the assets at the right path. Treat the canonical URL (with subpath) as the only public URL.
