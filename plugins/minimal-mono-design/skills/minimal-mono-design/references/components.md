# Components

Each component is a copy-paste markup + CSS block. They depend only on the design tokens (`tokens.md`) — no JS framework required (but two have a small JS handler that lives globally; see `theme-system.md` for the toggle and below for the copy button).

---

## Install box

A terminal-styled command line with a copy button. The button cross-fades between a copy icon and a checkmark when clicked.

**Markup**

```html
<div class="install" role="group" aria-label="Install command">
  <span class="install__prompt" aria-hidden="true">$</span>
  <code class="install__cmd">npm install your-package</code>
  <button
    type="button"
    class="copy-btn"
    data-copy="npm install your-package"
    data-copied="false"
    aria-label="Copy to clipboard"
  >
    <svg class="copy-icon copy-icon--copy" viewBox="0 0 16 16" width="11" height="11"
         fill="none" stroke="currentColor" stroke-width="1.5"
         stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <rect x="4.5" y="4.5" width="9" height="9" rx="1.5"></rect>
      <path d="M2.5 11V3a.5.5 0 0 1 .5-.5h8"></path>
    </svg>
    <svg class="copy-icon copy-icon--check" viewBox="0 0 16 16" width="11" height="11"
         fill="none" stroke="currentColor" stroke-width="1.6"
         stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M3 8.25 6.5 11.5 13 5"></path>
    </svg>
  </button>
</div>
```

**CSS**

```css
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

.install__prompt {
  color: var(--color-dim);
  user-select: none;
  flex: none;
}
.install__cmd {
  flex: 1;
  overflow-x: auto;
  white-space: nowrap;
  scrollbar-width: none;
  /* min-width: 0 is critical — without it, long commands force the page wider
     than the viewport because flex items default to min-width: auto (= content). */
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
.copy-btn:hover { color: var(--color-text); }
.copy-btn[data-copied="true"] { color: var(--color-text); }

/* Stack both icons in the same grid cell so we can cross-fade */
.copy-icon {
  grid-area: 1 / 1;
  transition: opacity 350ms ease;
}
.copy-icon--check { opacity: 0; }
.copy-btn[data-copied="true"] .copy-icon--copy { opacity: 0; }
.copy-btn[data-copied="true"] .copy-icon--check { opacity: 1; }
```

**JS handler** (global, attached once)

```js
document.querySelectorAll("[data-copy]").forEach((btn) => {
  btn.addEventListener("click", async () => {
    const text = btn.getAttribute("data-copy") ?? "";
    try {
      await navigator.clipboard.writeText(text);
      btn.dataset.copied = "true";
      setTimeout(() => { btn.dataset.copied = "false"; }, 1500);
    } catch (e) {
      console.error("Clipboard write failed", e);
    }
  });
});
```

**Notes**

- The `min-width: 0` on `.install__cmd` is a known flexbox gotcha — flex items default to `min-width: auto`, which equals their intrinsic content width when `white-space: nowrap` is set. Without overriding this, a long command pushes the page horizontally wider than the viewport.
- The 350ms cross-fade duration was tuned by feel — quick enough to feel responsive, slow enough to read as intentional. Adjust if you have a different tempo target.

---

## Theme toggle

See `theme-system.md` — the toggle's markup, CSS, and handler all live there.

---

## Plugin-list grid (cross-row column alignment)

Used for any list where each row has a title + 1-2 metadata columns and you want the columns to align across rows even when title widths vary.

**The trick**: `display: grid` lives on the *parent* of all rows; each row uses `display: contents` so its children become direct grid children of the parent, sharing the parent's column tracks.

**Markup**

```html
<div class="plugin-list">
  <article class="entry">
    <h2 class="entry__title">
      <a href="/plugins/foo">foo <span class="link__arrow" aria-hidden="true">→</span></a>
    </h2>
    <p class="entry__category">[security]</p>
    <p class="entry__date">[2026-05-11]</p>
  </article>
  <article class="entry">
    <h2 class="entry__title">
      <a href="/plugins/bar-baz-quux">bar-baz-quux <span class="link__arrow" aria-hidden="true">→</span></a>
    </h2>
    <p class="entry__category">[database]</p>
    <p class="entry__date">[2025-12-24]</p>
  </article>
</div>
```

**CSS**

```css
.plugin-list {
  display: grid;
  grid-template-columns: auto 1fr auto;
  column-gap: 0.5rem;
  row-gap: 0.625rem;
  align-items: baseline;
}
.entry { display: contents; }

.entry__title {
  margin: 0;
  font-size: 0.8125rem;
  font-weight: 400;
  color: var(--color-text);
}
.entry__title a { text-decoration: none; color: inherit; }

.entry__category {
  margin: 0;
  text-align: center;
  color: var(--color-dim);
  font-size: 0.8125rem;
  transition: color 200ms ease;
}
.entry__date {
  margin: 0;
  color: var(--color-dim);
  font-size: 0.8125rem;
  font-variant-numeric: tabular-nums;
  transition: color 200ms ease;
}

/* Hovering the title brightens the whole row's category + date + arrow.
   Hovering the [tag] or [date] does NOT trigger this — the :has() match
   is scoped to the title's <a>. */
.entry:has(.entry__title a:hover) .link__arrow,
.entry:has(.entry__title a:hover) .entry__category,
.entry:has(.entry__title a:hover) .entry__date {
  color: var(--color-text);
}

/* Mobile: stack vertically. The display: contents on .entry has to revert
   to display: block for the stacked layout to work. */
@media (max-width: 640px) {
  .plugin-list { display: block; }
  .entry { display: block; margin-bottom: 1rem; }
  .entry__category, .entry__date {
    text-align: left;
    color: var(--color-dim);
    margin-top: 0.125rem;
  }
}
```

**Notes**

- **`:has()` browser support**: all modern browsers since 2023 (Chrome 105+, Safari 15.4+, Firefox 121+). Don't rely on this if you need to support evergreen-but-not-recent browsers; fall back to a JS hover handler that toggles a `.row-hover` class.
- **`display: contents` accessibility**: in some screen readers, `display: contents` can flatten the article element from the accessibility tree. The semantic `<article>` is still in the DOM; assistive tech behavior varies. If accessibility-critical, use a real `<table>` semantic instead.
- **Tabular numerals** (`font-variant-numeric: tabular-nums`) on the date is what makes dates align column-perfectly across rows even when characters have different widths in proportional fonts. Geist Mono is already monospaced, so this is belt-and-suspenders, but it doesn't hurt.

---

## Section label

A small muted text marker above section content. Used for "Install", "Plugins", "Source", etc.

```html
<p class="label">Plugins</p>
```

```css
.label {
  color: var(--color-muted);
  font-size: 0.8125rem;
  font-weight: 400;
  letter-spacing: 0;
  margin: 0 0 1rem;
}
```

---

## Link with arrow

```html
<a href="/somewhere" class="link">
  github
  <span class="link__arrow" aria-hidden="true">→</span>
</a>
```

```css
.link {
  color: var(--color-text);
  text-decoration: none;
  transition: color 150ms ease;
}
.link__arrow {
  color: var(--color-dim);
  margin-left: 0.25em;
  font-size: 0.85em;
  transition: color 150ms ease;
}
.link:hover .link__arrow { color: var(--color-text); }
```

The arrow at rest is dim; on hover, it brightens to text color along with the link itself. Combined with the cross-row hover via `:has()` (above), the same arrow can also indicate "this whole row is clickable" in a list context.

---

## Eyebrow tag (optional, currently unused on the source site)

A small uppercase label with a colored dot prefix, suitable for "● MARKETPLACE" or "● PRINCIPLES" style hero markers. Included here because some users want a stronger section-marker affordance than `.label`.

```html
<div class="eyebrow">PRODUCT</div>
```

```css
.eyebrow {
  display: inline-flex;
  align-items: center;
  gap: 0.625rem;
  font-family: var(--font-mono);
  font-size: 0.6875rem;
  font-weight: 500;
  letter-spacing: 0.18em;
  text-transform: uppercase;
  color: var(--color-text);
}
.eyebrow::before {
  content: "";
  display: inline-block;
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: var(--color-text);
  /* Or swap to var(--color-accent) if you've extended the design with one */
}
```

By default the dot uses `--color-text` to stay monochrome; substitute an accent color if you've intentionally added one. The source site doesn't use this component on any page (it was iterated out), but it composes cleanly with the rest if you want it.

---

## Centered column wrapper

Used as the outer wrapper of every page or section.

```html
<div class="col">
  <!-- content -->
</div>
```

```css
.col {
  width: 100%;
  max-width: 640px;
  margin-inline: auto;
  padding-inline: 1.5rem;
}
```

640px is the source site's max width. Adjust if your content shape needs a wider column (e.g. 720px for prose-heavier sites, 800px for two-column meta sections).
