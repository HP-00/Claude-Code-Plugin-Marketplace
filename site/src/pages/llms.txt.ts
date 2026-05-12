import type { APIRoute } from "astro";
import { getPlugins, getMarketplaceMeta } from "../data/plugins";

// Generated at build time — kept in sync with marketplace.json automatically.
// Format follows the llmstxt.org convention: H1, blockquote tagline,
// section headings (## …) with bulleted link lists.
export const GET: APIRoute = ({ site }) => {
  const meta = getMarketplaceMeta();
  const plugins = getPlugins();

  const baseRaw = import.meta.env.BASE_URL;
  const base = baseRaw.endsWith("/") ? baseRaw : baseRaw + "/";
  const origin = site ? site.toString().replace(/\/$/, "") : "";
  const fullBase = `${origin}${base}`; // e.g. https://huzayfah.here.now/plugins/

  const lines: string[] = [
    `# HP-00 / Plugins`,
    ``,
    `> ${meta.description}. Each plugin is shipped as source in a single GitHub repository, installable through Claude Code's built-in /plugin command. This site is regenerated from .claude-plugin/marketplace.json on every push.`,
    ``,
    `## Install`,
    ``,
    `Inside a Claude Code session:`,
    ``,
    `\`\`\``,
    meta.installCommand,
    `/plugin install <plugin>@${meta.name}`,
    `\`\`\``,
    ``,
    `## Plugins`,
    ``,
    ...plugins.map(
      (p) =>
        `- [${p.name}](${fullBase}${p.slug}) — ${p.description.replace(/\n+/g, " ")}`,
    ),
    ``,
    `## Source`,
    ``,
    `- [GitHub repository](${meta.githubUrl})`,
    `- [Canonical plugin manifest](${meta.githubUrl}/raw/main/.claude-plugin/marketplace.json) — machine-readable JSON; the source of truth for this site.`,
    `- [Per-plugin source directories](${meta.githubUrl}/tree/main/plugins) — each plugin's commands, agents, hooks, skills, and README.`,
    ``,
    `## Optional`,
    ``,
    `- [README](${meta.githubUrl}#readme) — repo overview and contribution guide.`,
    ``,
  ];

  return new Response(lines.join("\n"), {
    headers: {
      "Content-Type": "text/plain; charset=utf-8",
      "Cache-Control": "public, max-age=300",
    },
  });
};
