# Theme system — `light / dark` with FOUC-free init

The theme is set on `<html>` via a `data-theme` attribute (`"light"` or `"dark"`). All CSS variables react to it via the `[data-theme="light"]` selector defined in tokens.md.

## Why `data-theme` (not the `class` attribute)

- Two states only, both string-named — `data-*` reads more semantic than a `dark`/`light` class.
- No conflict with utility-class systems (Tailwind, etc.) that use the `class` attribute heavily.
- Easy to query in JS: `document.documentElement.dataset.theme`.

## FOUC-free init script

The init script **must** run before `<body>` paints, otherwise users in light mode see a flash of dark before the script applies their preference. Inline `<script>` in `<head>`, executed synchronously:

```html
<script is:inline>
  // FOUC-free theme init: must run before <body> paints.
  // Default = system preference. Stored 'light'/'dark' overrides.
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
```

**Astro:** the `is:inline` directive bypasses the bundler, ensuring the script ships inline as written. Required.

**Next.js (App Router):** put this inside `<head>` in `app/layout.tsx` using `<Script strategy="beforeInteractive">` or a raw `<script dangerouslySetInnerHTML>`. The latter is more reliable for blocking-execution scripts — see `stack-nextjs-tailwind.md`.

**Plain HTML:** drop the `is:inline` attribute, otherwise identical.

**Generic frameworks:** the constraint is "run before paint." Most SSR frameworks support an inline-head escape hatch.

## Toggle component

Two `<button>` elements: `light`, `dark`. Active state via `aria-pressed`.

```html
<div class="theme-toggle" role="group" aria-label="Theme">
  <button type="button" class="theme-toggle__btn" data-theme-set="light" aria-pressed="false">light</button>
  <span class="theme-toggle__sep" aria-hidden="true">/</span>
  <button type="button" class="theme-toggle__btn" data-theme-set="dark" aria-pressed="false">dark</button>
</div>
```

```css
.theme-toggle {
  display: inline-flex;
  align-items: center;
  gap: 0.375rem;
  font-family: var(--font-mono);
}
.theme-toggle__sep {
  color: var(--color-dim);
  font-size: 0.6875rem;
  line-height: 1;
}
.theme-toggle__btn {
  appearance: none;
  background: none;
  border: 0;
  padding: 0;
  color: var(--color-dim);
  cursor: pointer;
  font-family: inherit;
  font-size: 0.6875rem;
  line-height: 1;
  transition: color 200ms ease;
}
.theme-toggle__btn:hover {
  color: var(--color-muted);
}
.theme-toggle__btn[aria-pressed="true"] {
  color: var(--color-muted);
}
.theme-toggle__btn:focus-visible {
  outline: 1px solid var(--color-border-hi);
  outline-offset: 2px;
  border-radius: 2px;
}
```

## Toggle handler

Lives in a regular (non-inline) module script in the body or a separate file. Wires up clicks, persists choice, and tracks system changes when no explicit choice is stored.

```js
// 'light' | 'dark'. No stored value = follow system.
const lightMq = window.matchMedia("(prefers-color-scheme: light)");

const setPressed = (theme) => {
  document.querySelectorAll("[data-theme-set]").forEach((btn) => {
    btn.setAttribute(
      "aria-pressed",
      btn.dataset.themeSet === theme ? "true" : "false",
    );
  });
};

const initialTheme =
  document.documentElement.dataset.theme || "dark";
setPressed(initialTheme);

document.querySelectorAll("[data-theme-set]").forEach((btn) => {
  btn.addEventListener("click", () => {
    const theme = btn.dataset.themeSet || "dark";
    document.documentElement.dataset.theme = theme;
    try {
      localStorage.setItem("theme", theme);
    } catch (e) {
      /* storage may be unavailable */
    }
    setPressed(theme);
  });
});

// If the user hasn't picked an explicit theme, track system changes live.
const onSystemChange = () => {
  let stored = null;
  try {
    stored = localStorage.getItem("theme");
  } catch (e) { /* storage unavailable */ }
  if (stored !== "light" && stored !== "dark") {
    const next = lightMq.matches ? "light" : "dark";
    document.documentElement.dataset.theme = next;
    setPressed(next);
  }
};
if (typeof lightMq.addEventListener === "function") {
  lightMq.addEventListener("change", onSystemChange);
} else if (typeof lightMq.addListener === "function") {
  lightMq.addListener(onSystemChange); // Safari < 14
}
```

## Behavior contract

- **First visit, no stored choice** → matches `prefers-color-scheme`. Listens for OS theme changes live.
- **User clicks `light` or `dark`** → stored in `localStorage`. System changes ignored from then on.
- **To "reset to system tracking"** → user can `localStorage.removeItem('theme')` in devtools, or you can ship an `auto` button that does this. The source site doesn't expose `auto` in the UI, but you can add one if it fits your product.

## Why no `auto` button by default

Tested both. Verdict: a plain `light / dark` toggle is more legible to non-technical users (they understand "switch to light"); the `auto` mode is implicit (pre-click) and most users never need to reset it. Adding `auto` as a third button increases UI surface without adding clarity.

If you do want it, add a third button (`data-theme-set="auto"`), have its click handler `localStorage.removeItem("theme")` and re-apply the system preference. Update `setPressed` to read both `data-theme` and a separate `data-theme-mode` attribute so you can show the `auto` button as pressed even when the resolved theme is `light` or `dark`.

## Caveats

- **`color-scheme` CSS property**: pair with the data-theme switching to make native form controls and scrollbars match. See `tokens.md`.
- **`prefers-reduced-motion`**: the source site's CSS includes a global `* { animation: none !important; transition: none !important; }` under `@media (prefers-reduced-motion: reduce)`. The theme transition (200ms ease on `.theme-toggle__btn`) is still respected by users with reduced-motion preference; only larger CSS animations get killed. Adjust per your UX standards.
- **Server rendering**: with SSR, the `<html data-theme="...">` attribute is set client-side by the inline script. The initial server-rendered HTML can omit `data-theme` entirely; the script populates it before paint. Avoid trying to set `data-theme` on the server based on cookies — adds complexity, and users in private mode without a stored preference still hit the prefers-color-scheme check.
