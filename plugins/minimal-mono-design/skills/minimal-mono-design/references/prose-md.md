# `.prose-md` — rendered-markdown styling

Apply this class to any container holding HTML produced from markdown (e.g. via `marked`, `remark-html`, `markdown-it`, server-side renderers, or framework MDX output). It themes headings, code, pre, lists, tables, blockquotes, and images consistently with the rest of the design system.

```html
<div class="prose-md">
  <!-- HTML output from your markdown processor -->
</div>
```

## CSS

```css
.prose-md {
  font-family: var(--font-mono);
  color: var(--color-text);
  line-height: 1.7;
  font-size: 0.875rem;
}
.prose-md > *:first-child { margin-top: 0; }

/* Headings — mono, the same family as body text */
.prose-md h1,
.prose-md h2,
.prose-md h3,
.prose-md h4 {
  font-family: var(--font-mono);
  color: var(--color-text);
  font-weight: 500;
  letter-spacing: -0.005em;
  line-height: 1.3;
}
.prose-md h1 { font-size: 1.375rem; margin: 3rem 0 1rem; }
.prose-md h2 {
  font-size: 1.0625rem;
  margin: 2.75rem 0 0.875rem;
  padding-top: 1.25rem;
  border-top: 1px solid var(--color-border);
}
.prose-md h3 { font-size: 0.9375rem; margin: 2rem 0 0.625rem; }
.prose-md h4 {
  font-size: 0.8125rem;
  margin: 1.5rem 0 0.5rem;
  color: var(--color-muted);
  text-transform: uppercase;
  letter-spacing: 0.08em;
}

/* Body */
.prose-md p { margin: 0.875rem 0; color: var(--color-text); }

/* Links */
.prose-md a {
  color: var(--color-text);
  text-decoration: underline;
  text-decoration-color: var(--color-border-hi);
  text-underline-offset: 3px;
}
.prose-md a:hover { text-decoration-color: var(--color-text); }

/* Lists */
.prose-md ul,
.prose-md ol { margin: 0.875rem 0; padding-left: 1.5rem; }
.prose-md li { margin: 0.25rem 0; }
.prose-md ul > li::marker { color: var(--color-dim); }
.prose-md ol > li::marker { color: var(--color-muted); }

/* Inline code */
.prose-md code {
  font-family: var(--font-mono);
  font-size: 0.92em;
  color: var(--color-text);
  background: var(--color-surface);
  padding: 0.05em 0.35em;
  border-radius: 3px;
  border: 1px solid var(--color-border);
}

/* Code blocks */
.prose-md pre {
  font-family: var(--font-mono);
  font-size: 0.8125rem;
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: 6px;
  padding: 0.875rem 1rem;
  overflow-x: auto;
  margin: 1rem 0;
  line-height: 1.55;
  color: var(--color-text);
}
.prose-md pre code {
  background: transparent;
  border: 0;
  padding: 0;
  color: inherit;
  font-size: inherit;
}

/* Quotes */
.prose-md blockquote {
  border-left: 1px solid var(--color-border-hi);
  padding-left: 1rem;
  margin: 1rem 0;
  color: var(--color-muted);
}

/* Tables */
.prose-md table {
  width: 100%;
  border-collapse: collapse;
  margin: 1rem 0;
  font-size: 0.875rem;
}
.prose-md th,
.prose-md td {
  text-align: left;
  padding: 0.5rem 0.75rem;
  border-bottom: 1px solid var(--color-border);
  vertical-align: top;
}
.prose-md th {
  font-weight: 500;
  color: var(--color-muted);
  border-bottom-color: var(--color-border-hi);
}

/* Misc */
.prose-md hr { margin: 1.75rem 0; }
.prose-md img {
  max-width: 100%;
  border-radius: 4px;
  margin: 1rem 0;
}
.prose-md strong { color: var(--color-text); font-weight: 600; }
```

## Choices worth knowing

- **All-mono including headings.** Most prose styling pairs a serif/sans display font with a mono inline-code. This system uses mono everywhere — visually quieter, more "developer documentation" feel. Swap headings to a sans display font (Inter, Söhne, etc.) if your content is more editorial.
- **H2 has a `border-top`.** This carves the page into clear sections without needing decorative dividers. Skips for H1, H3, H4.
- **Code blocks use `--color-surface`**, not a third tone. Inline `<code>` and block `<pre>` share the same background — distinguishes them from body text but doesn't introduce a new palette entry.
- **Tables use uppercase mono headers** (`color: var(--color-muted)`, `font-weight: 500`). Cells use normal body styling. Borders only between rows, not between columns — keeps it scannable.
- **Long-string handling.** The source site adds `overflow-wrap: anywhere` on plugin description paragraphs to handle long slash-separated identifiers. Apply to specific elements as needed; not added globally to `.prose-md p` because it changes natural prose breaking.

## Use with markdown processors

**marked (Node):**
```js
import { marked } from "marked";
const html = marked.parse(markdownString, { async: false });
// Render in your template:
// <div class="prose-md">{html}</div>
```

**remark-html / unified:**
```js
import { unified } from "unified";
import remarkParse from "remark-parse";
import remarkRehype from "remark-rehype";
import rehypeStringify from "rehype-stringify";

const html = String(
  await unified()
    .use(remarkParse)
    .use(remarkRehype)
    .use(rehypeStringify)
    .process(markdownString)
);
```

**MDX (Astro / Next.js):** the rendered HTML naturally inherits styling from the surrounding `.prose-md` wrapper. No special config needed — just wrap your `<MDXProvider>` output in the class.

**Astro Content Collections:** render via `entry.render()`, which returns a `Content` component. Wrap usage in `<div class="prose-md"><Content /></div>`.
