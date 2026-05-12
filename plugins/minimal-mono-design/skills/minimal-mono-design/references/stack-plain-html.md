# Stack: Plain HTML + CSS (no framework)

Use when the project is a single page, when zero JS / single file shipping matters more than authoring ergonomics, or when the user wants a README-as-a-site with no build step.

**Examples**: profile page, project landing page, single-doc microsite, status page, demo, README rendered as a site.

## A complete single-file site

This works as `index.html`. Drop it on any static host (GitHub Pages, Cloudflare Pages, S3 + CloudFront, etc.) and it renders.

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Your Site</title>
  <meta name="description" content="One-line description" />
  <meta name="theme-color" content="#000000" />
  <link rel="icon" type="image/svg+xml" href="favicon.svg" />

  <!-- Geist Mono -->
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
  <link href="https://fonts.googleapis.com/css2?family=Geist+Mono:wght@400;500;600&display=swap" rel="stylesheet" />

  <!-- FOUC-free theme init -->
  <script>
    (function () {
      try {
        var stored = localStorage.getItem("theme");
        if (stored === "light" || stored === "dark") {
          document.documentElement.dataset.theme = stored;
          return;
        }
        var prefersLight = window.matchMedia && window.matchMedia("(prefers-color-scheme: light)").matches;
        document.documentElement.dataset.theme = prefersLight ? "light" : "dark";
      } catch (e) {
        document.documentElement.dataset.theme = "dark";
      }
    })();
  </script>

  <style>
    /* === DESIGN TOKENS === */
    :root {
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

    /* === BASE === */
    *, *::before, *::after { box-sizing: border-box; }
    html {
      background: var(--color-bg);
      color: var(--color-text);
      font-family: var(--font-mono);
      font-size: 14.5px;
      line-height: 1.6;
      -webkit-font-smoothing: antialiased;
      color-scheme: dark;
    }
    [data-theme="light"] html { color-scheme: light; }
    body { margin: 0; min-height: 100dvh; background: var(--color-bg); }
    a { color: inherit; text-decoration: none; }

    /* === LAYOUT === */
    .col {
      width: 100%;
      max-width: 640px;
      margin-inline: auto;
      padding: 4rem 1.5rem 2.5rem;
    }

    /* === COMPONENTS — pick the ones you need === */
    .label {
      color: var(--color-muted);
      font-size: 0.8125rem;
      margin: 0 0 1rem;
    }

    .install {
      display: flex;
      align-items: center;
      gap: 0.625rem;
      padding: 0.625rem 0.875rem;
      border: 1px solid var(--color-border);
      border-radius: 4px;
      font-family: var(--font-mono);
      font-size: 0.8125rem;
      color: var(--color-text);
      background: var(--color-surface);
      transition: border-color 200ms ease;
    }
    .install:hover { border-color: var(--color-border-hi); }
    .install__prompt { color: var(--color-dim); user-select: none; flex: none; }
    .install__cmd {
      flex: 1;
      overflow-x: auto;
      white-space: nowrap;
      scrollbar-width: none;
      min-width: 0;
    }
    .install__cmd::-webkit-scrollbar { display: none; }

    .copy-btn {
      flex: none;
      display: grid;
      place-items: center;
      width: 24px;
      height: 24px;
      border: 1px solid var(--color-border);
      background: transparent;
      color: var(--color-muted);
      border-radius: 3px;
      cursor: pointer;
      transition: color 150ms ease;
    }
    .copy-btn:hover, .copy-btn[data-copied="true"] { color: var(--color-text); }
    .copy-icon { grid-area: 1 / 1; transition: opacity 350ms ease; }
    .copy-icon--check { opacity: 0; }
    .copy-btn[data-copied="true"] .copy-icon--copy { opacity: 0; }
    .copy-btn[data-copied="true"] .copy-icon--check { opacity: 1; }

    .theme-toggle {
      display: inline-flex;
      align-items: center;
      gap: 0.375rem;
      font-family: var(--font-mono);
    }
    .theme-toggle__sep { color: var(--color-dim); font-size: 0.6875rem; line-height: 1; }
    .theme-toggle__btn {
      appearance: none; background: none; border: 0; padding: 0;
      color: var(--color-dim);
      cursor: pointer;
      font-family: inherit;
      font-size: 0.6875rem;
      line-height: 1;
      transition: color 200ms ease;
    }
    .theme-toggle__btn:hover, .theme-toggle__btn[aria-pressed="true"] {
      color: var(--color-muted);
    }

    /* === Add prose-md.md content here if rendering markdown === */

    @media (prefers-reduced-motion: reduce) {
      * { animation: none !important; transition: none !important; }
    }
  </style>
</head>

<body>
  <main class="col">
    <p>Your Site Name</p>

    <section style="margin-top: 2.75rem">
      <p class="label">Install</p>
      <div class="install" role="group" aria-label="Install command">
        <span class="install__prompt" aria-hidden="true">$</span>
        <code class="install__cmd">npm install your-package</code>
        <button type="button" class="copy-btn" data-copy="npm install your-package" data-copied="false" aria-label="Copy">
          <svg class="copy-icon copy-icon--copy" viewBox="0 0 16 16" width="11" height="11" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <rect x="4.5" y="4.5" width="9" height="9" rx="1.5"></rect>
            <path d="M2.5 11V3a.5.5 0 0 1 .5-.5h8"></path>
          </svg>
          <svg class="copy-icon copy-icon--check" viewBox="0 0 16 16" width="11" height="11" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <path d="M3 8.25 6.5 11.5 13 5"></path>
          </svg>
        </button>
      </div>
    </section>

    <footer style="margin-top: 3.5rem; padding-top: 1rem; border-top: 1px solid var(--color-border); display: flex; justify-content: space-between; font-size: 0.6875rem; color: var(--color-dim);">
      <div class="theme-toggle" role="group" aria-label="Theme">
        <button type="button" class="theme-toggle__btn" data-theme-set="light" aria-pressed="false">light</button>
        <span class="theme-toggle__sep" aria-hidden="true">/</span>
        <button type="button" class="theme-toggle__btn" data-theme-set="dark" aria-pressed="false">dark</button>
      </div>
      <a href="https://github.com/you/repo" style="color: var(--color-muted); transition: color 150ms ease;"
         onmouseover="this.style.color='var(--color-text)'"
         onmouseout="this.style.color='var(--color-muted)'">github</a>
    </footer>
  </main>

  <script>
    // Copy buttons
    document.querySelectorAll("[data-copy]").forEach(function (btn) {
      btn.addEventListener("click", async function () {
        var text = btn.getAttribute("data-copy") || "";
        try {
          await navigator.clipboard.writeText(text);
          btn.dataset.copied = "true";
          setTimeout(function () { btn.dataset.copied = "false"; }, 1500);
        } catch (e) {
          console.error("Clipboard write failed", e);
        }
      });
    });

    // Theme toggle
    var lightMq = window.matchMedia("(prefers-color-scheme: light)");
    function setPressed(theme) {
      document.querySelectorAll("[data-theme-set]").forEach(function (btn) {
        btn.setAttribute("aria-pressed", btn.dataset.themeSet === theme ? "true" : "false");
      });
    }
    var initial = document.documentElement.dataset.theme || "dark";
    setPressed(initial);
    document.querySelectorAll("[data-theme-set]").forEach(function (btn) {
      btn.addEventListener("click", function () {
        var theme = btn.dataset.themeSet || "dark";
        document.documentElement.dataset.theme = theme;
        try { localStorage.setItem("theme", theme); } catch (e) {}
        setPressed(theme);
      });
    });
    function onSystemChange() {
      var stored;
      try { stored = localStorage.getItem("theme"); } catch (e) {}
      if (stored !== "light" && stored !== "dark") {
        var next = lightMq.matches ? "light" : "dark";
        document.documentElement.dataset.theme = next;
        setPressed(next);
      }
    }
    if (lightMq.addEventListener) lightMq.addEventListener("change", onSystemChange);
    else if (lightMq.addListener) lightMq.addListener(onSystemChange);
  </script>
</body>
</html>
```

## Notes

- **CSS uses `:root` instead of `@theme`.** No Tailwind dependency; works with any CSS pipeline (or none).
- **Inline `<style>` and `<script>`.** No build step. Can compress later with any minifier if size matters; the file as-shown is ~10KB before compression.
- **Self-host fonts** to drop the third-party Google Fonts request. Download Geist Mono from `vercel/geist-font`, drop the woff2 files next to the HTML, replace the `<link>` with `@font-face` rules in the `<style>` block.
- **For multiple pages**: copy this file as `about.html`, `contact.html`, etc. Or — if you have more than 3-4 pages — switch to Astro or another static-site generator; maintaining the duplicated HTML head per page becomes painful past that count.
- **No prose-md included** in this template by default. Add it only if you'll be rendering markdown content. See `prose-md.md`.

## Why no framework?

Trade-offs:

| Plain HTML | Framework |
|------------|-----------|
| Zero install, zero build, zero JS deps | Build step required |
| One file you can read top-to-bottom | Better authoring ergonomics for repeated patterns |
| Painful past ~3-4 pages | Scales to dozens of pages with shared layouts |
| Loads instantly, smallest possible bundle | Bundle includes framework runtime |
| Hard to add interactivity past simple click handlers | Component model + state management built-in |

Pick this only if your site is very small or you specifically value the no-build, single-file property.
