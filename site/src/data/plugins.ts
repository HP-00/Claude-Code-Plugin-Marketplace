import { readFileSync, existsSync } from 'node:fs';
import { resolve } from 'node:path';
import { execSync } from 'node:child_process';
import { marked } from 'marked';

// Astro runs `astro build` with cwd === the site/ project root, so the
// marketplace repo root is one level up. We avoid `import.meta.url` because
// after bundling it points to the rolled-up chunk, not the source file.
const REPO_ROOT = resolve(process.cwd(), '..');
const GITHUB_REPO = 'HP-00/Claude-Code-Plugin-Marketplace';
const GITHUB_BASE = `https://github.com/${GITHUB_REPO}`;

export interface Plugin {
  name: string;
  slug: string;
  description: string;
  version: string;
  category: string;
  keywords: string[];
  author: { name: string; url?: string };
  sourcePath: string;
  readmeHtml: string | null;
  updated: string;
  githubUrl: string;
}

export interface MarketplaceMeta {
  name: string;
  ownerName: string;
  description: string;
  version: string;
  githubUrl: string;
  installCommand: string;
}

interface MarketplaceManifest {
  name: string;
  owner: { name: string };
  metadata: { description: string; version: string };
  plugins: Array<{
    name: string;
    source: string;
    description: string;
    version: string;
    category: string;
    keywords: string[];
  }>;
}

interface PluginManifest {
  name: string;
  version: string;
  description: string;
  author?: { name: string; url?: string };
  repository?: { type: string; url: string };
  keywords?: string[];
}

function readManifest(): MarketplaceManifest {
  const path = resolve(REPO_ROOT, '.claude-plugin/marketplace.json');
  return JSON.parse(readFileSync(path, 'utf-8'));
}

function gitUpdated(relativePath: string): string {
  try {
    return execSync(`git log -1 --format=%cs -- ${relativePath}`, {
      cwd: REPO_ROOT,
      encoding: 'utf-8',
    }).trim();
  } catch {
    return '';
  }
}

export function getMarketplaceMeta(): MarketplaceMeta {
  const m = readManifest();
  return {
    name: m.name,
    ownerName: m.owner.name,
    description: m.metadata.description,
    version: m.metadata.version,
    githubUrl: GITHUB_BASE,
    installCommand: `/plugin marketplace add ${GITHUB_REPO}`,
  };
}

export function getPlugins(): Plugin[] {
  const manifest = readManifest();

  const built = manifest.plugins.map((entry) => {
    const sourceRelative = entry.source.replace(/^\.\//, '');
    const pluginDir = resolve(REPO_ROOT, sourceRelative);

    let pluginManifest: PluginManifest | null = null;
    const pluginManifestPath = resolve(pluginDir, '.claude-plugin/plugin.json');
    if (existsSync(pluginManifestPath)) {
      pluginManifest = JSON.parse(readFileSync(pluginManifestPath, 'utf-8'));
    }

    let readmeHtml: string | null = null;
    const readmePath = resolve(pluginDir, 'README.md');
    if (existsSync(readmePath)) {
      const md = readFileSync(readmePath, 'utf-8');
      readmeHtml = marked.parse(md, { async: false }) as string;
    }

    const author =
      pluginManifest?.author ?? { name: manifest.owner.name };

    return {
      name: entry.name,
      slug: entry.name,
      description: entry.description,
      version: entry.version,
      category: entry.category,
      keywords: entry.keywords,
      author,
      sourcePath: entry.source,
      readmeHtml,
      updated: gitUpdated(sourceRelative),
      githubUrl: `${GITHUB_BASE}/tree/main/${sourceRelative}`,
    };
  });

  // Most-recently-updated first; entries missing a date sink to the bottom.
  return built.sort((a, b) => {
    if (!a.updated && !b.updated) return a.name.localeCompare(b.name);
    if (!a.updated) return 1;
    if (!b.updated) return -1;
    return b.updated.localeCompare(a.updated);
  });
}

export function getPlugin(slug: string): Plugin | undefined {
  return getPlugins().find((p) => p.slug === slug);
}
