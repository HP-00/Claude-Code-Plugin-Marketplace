# Stack: Next.js (App Router) + Tailwind 4

Use this stack when the user is on Next.js, or needs server-side dynamism (API routes, server actions, dynamic React components, auth, real-time, etc.) that Astro doesn't fit.

## Pinned dependencies (suggested)

```json
{
  "dependencies": {
    "next": "16.0.0",
    "react": "19.2.0",
    "react-dom": "19.2.0",
    "@tailwindcss/postcss": "4.3.0",
    "tailwindcss": "4.3.0"
  }
}
```

Adjust to match the user's existing project. Tailwind 4 with Next.js uses the `@tailwindcss/postcss` adapter (not `@tailwindcss/vite`).

## File structure (additions to a default Next.js app)

```
app/
├── layout.tsx          # head, theme init, font, global CSS import
├── page.tsx            # home (listing)
├── [slug]/page.tsx     # dynamic per-item route
├── globals.css         # design tokens + components + .prose-md
└── components/
    ├── InstallBox.tsx
    └── ThemeToggle.tsx
```

## globals.css

Same content as `references/tokens.md` + `references/components.md` + `references/prose-md.md`. Tailwind 4 with Next.js's PostCSS pipeline supports the same `@import "tailwindcss"` + `@theme {}` pattern.

```css
@import "tailwindcss";

@theme {
  --color-bg: #000000;
  /* ... rest of tokens.md ... */
}

[data-theme="light"] {
  --color-bg: #FFFFFF;
  /* ... */
}

@layer base { /* ... */ }
@layer components { /* paste components.md + prose-md.md */ }
```

## app/layout.tsx

```tsx
import "./globals.css";
import { GeistMono } from "geist/font/mono"; // or next/font/google

export const metadata = {
  title: "Site Name",
  description: "Your tagline",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={GeistMono.className}>
      <head>
        {/* FOUC-free theme init: must run before <body> paints */}
        <script
          dangerouslySetInnerHTML={{
            __html: `
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
            `,
          }}
        />
      </head>
      <body>{children}</body>
    </html>
  );
}
```

**Geist Mono via `next/font`**: prefer `import { GeistMono } from "geist/font/mono"` (the official Geist package). It handles preloading, CSS variable wiring, and layout-shift prevention. If you use it, set `--font-mono: var(--font-geist-mono)` in globals.css instead of the Google-Fonts string, and apply `GeistMono.className` to `<html>`.

Fall back to `import { Geist_Mono } from "next/font/google"` if the `geist` package isn't installed.

## Components

Convert `.astro` to `.tsx`:

**components/InstallBox.tsx:**
```tsx
"use client";

import { useState } from "react";

export function InstallBox({ command }: { command: string }) {
  const [copied, setCopied] = useState(false);

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(command);
      setCopied(true);
      setTimeout(() => setCopied(false), 1500);
    } catch (e) {
      console.error("Clipboard write failed", e);
    }
  };

  return (
    <div className="install" role="group" aria-label="Install command">
      <span className="install__prompt" aria-hidden>$</span>
      <code className="install__cmd">{command}</code>
      <button
        type="button"
        className="copy-btn"
        data-copied={copied ? "true" : "false"}
        onClick={copy}
        aria-label={`Copy ${command} to clipboard`}
      >
        {/* paste the two SVGs from components.md */}
      </button>
    </div>
  );
}
```

**components/ThemeToggle.tsx:**
```tsx
"use client";

import { useEffect, useState } from "react";

export function ThemeToggle() {
  const [theme, setTheme] = useState<"light" | "dark" | null>(null);

  useEffect(() => {
    setTheme((document.documentElement.dataset.theme as "light" | "dark") ?? "dark");

    const mq = window.matchMedia("(prefers-color-scheme: light)");
    const onChange = () => {
      const stored = localStorage.getItem("theme");
      if (stored !== "light" && stored !== "dark") {
        const next = mq.matches ? "light" : "dark";
        document.documentElement.dataset.theme = next;
        setTheme(next);
      }
    };
    mq.addEventListener("change", onChange);
    return () => mq.removeEventListener("change", onChange);
  }, []);

  const apply = (next: "light" | "dark") => {
    document.documentElement.dataset.theme = next;
    try { localStorage.setItem("theme", next); } catch {}
    setTheme(next);
  };

  return (
    <div className="theme-toggle" role="group" aria-label="Theme">
      <button
        type="button"
        className="theme-toggle__btn"
        aria-pressed={theme === "light"}
        onClick={() => apply("light")}
      >light</button>
      <span className="theme-toggle__sep" aria-hidden>/</span>
      <button
        type="button"
        className="theme-toggle__btn"
        aria-pressed={theme === "dark"}
        onClick={() => apply("dark")}
      >dark</button>
    </div>
  );
}
```

Both components must be `"use client"` because they use React state, browser APIs (`localStorage`, `matchMedia`, `navigator.clipboard`), and event handlers.

## Conversion notes from Astro

| Astro pattern | Next.js equivalent |
|---------------|--------------------|
| `<script is:inline>` in `<head>` | `<script dangerouslySetInnerHTML={{__html: "..."}} />` in `app/layout.tsx`'s `<head>` |
| `import "../styles/global.css"` in `Base.astro` | `import "./globals.css"` in `app/layout.tsx` |
| `Astro.url.pathname` | `usePathname()` from `next/navigation` (client) or `headers().get('x-pathname')` middleware-pattern (server) |
| `Astro.site` | `process.env.NEXT_PUBLIC_SITE_URL` or hardcoded |
| `import.meta.env.BASE_URL` | `basePath` in `next.config.js`; reference via `process.env.NEXT_PUBLIC_BASE_PATH` if you need to construct URLs |
| `getStaticPaths()` | `generateStaticParams()` in dynamic-route page files |
| `set:html` directive | `dangerouslySetInnerHTML={{__html: ...}}` |

## Per-item dynamic routes

```tsx
// app/[slug]/page.tsx
import { getItems, getItem } from "@/data/items";

export async function generateStaticParams() {
  return getItems().map((item) => ({ slug: item.slug }));
}

export default async function Page({ params }: { params: { slug: string } }) {
  const item = getItem(params.slug);
  if (!item) return <div>Not found</div>;
  return (
    <main className="col">
      <h1>{item.name}</h1>
      <div className="prose-md" dangerouslySetInnerHTML={{ __html: item.readmeHtml }} />
    </main>
  );
}
```

## Notes

- **Font loading**: prefer `next/font` over Google Fonts `<link>` tags. Avoids CLS, ships only the weights you use, no third-party request at runtime.
- **App Router vs Pages Router**: this reference assumes App Router. For Pages Router, the inline script goes in `pages/_document.tsx`'s `<Head>` via `dangerouslySetInnerHTML`. Same content; different file.
- **Server vs Client**: layout.tsx is a Server Component by default. The InstallBox and ThemeToggle must be Client Components (`"use client"`) for interactivity. The page-level layout doesn't need to be — only the interactive bits.
- **CSS variables in JSX**: same pattern as Astro. `style={{ color: "var(--color-text)" }}` works, but using class names + CSS vars in stylesheets is preferred.
