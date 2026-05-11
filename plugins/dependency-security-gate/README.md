# Dependency Security Gate

A reusable Claude Code plugin that intercepts every external dependency install or download and forces a structured 11-item security review before allowing the action.

If Claude tries to `npm install`, `pip install`, `cargo install`, `gem install`, `brew install`, `pod install`, `go install`, `npx`/`uvx`/`pipx`, `curl`/`wget`/`huggingface-cli` an external archive, or `git clone` an external repo, this plugin's PreToolUse hook blocks the action. Claude is then required by the bundled skill to:

1. Identify the dependency precisely (item 1)
2. Justify why it's needed (item 2)
3. Delegate items 3–10 (provenance, postinstall audit, typosquat check, transitive surface, license, supply-chain attack overlap, deep external research) to the `dependency-research` subagent — which uses Context7 + Exa MCPs when available and falls back to `WebFetch`/`WebSearch` when not
4. Recommend the safe-execution path (item 11) — typically the user runs the install themselves via the `!` prefix
5. Wait for explicit `approve <pkg>@<version>` text from the user

## Features

- **Cross-package-manager coverage** — npm, yarn, pnpm, bun, pip, uv, poetry, cargo, gem, brew, apt, dnf, go, pod, npx, uvx, pipx (14 managers)
- **External-download coverage** — `curl`/`wget`/`aria2c` on binary archives, fonts, ML weights (`.safetensors` / `.gguf` / `.onnx` / `.mlpackage`), pipe-to-shell installers (`curl | bash`), `huggingface-cli download`, `git clone` of external repos
- **Wrapper-prefix-aware** — catches `sudo apt install`, `nice -n 19 npm install`, `nohup pip install`, `bundle exec pod install`
- **Chained-command-aware** — catches `cd app && npm install foo`, `pip install x ; pip install y`
- **Inspection allowlist** — read-only commands like `npm view`, `pip index`, `cargo search`, `gem info --remote`, `curl -I` pass through so the analysis itself can run
- **Subagent for parallel research** — `dependency-research` runs Context7 + Exa MCPs in parallel for sub-second supply-chain analysis when MCPs are installed
- **Native fallbacks when MCPs are missing** — the subagent automatically falls back to `WebFetch` (canonical registry pages) and `WebSearch` (advisory + GitHub-issue queries) when Context7 or Exa aren't installed; research is slower but still works
- **2025–2026 threat landscape awareness** — agent explicitly cross-references Shai-Hulud Nov 2025 worm (796 npm packages), DevTap Apr-May 2026 typosquats (`centralogger`, `node-fetch-lite`, etc.), slopsquatting, and 72-hour Package Cooldown Check

## How it works

```
Claude attempts:  npm install lodash
                          │
                          ▼
              ╔═══════════════════════╗
              ║  PreToolUse hook      ║  (this plugin)
              ║  blocks the Bash call ║
              ╚═══════════════════════╝
                          │
                          ▼
          Claude reads stderr → invokes dependency-gate skill
                          │
                          ▼
                  Claude surfaces 11-item analysis:
                          │
                  ┌───────┴───────┐
                  │               │
       items 1, 2, 11        items 3–10
       (in main chat)        (delegated to
                              dependency-research
                              subagent)
                          │
                          ▼
                  Claude folds findings into chat
                          │
                          ▼
                  Waits for: approve lodash@4.17.21
                          │
                          ▼
                  User runs:  ! npm install lodash
                  (! prefix bypasses Claude's Bash tool;
                  command runs in the user's real shell)
```

## Installation

```shell
/plugin marketplace add HP-00/Claude-Code-Plugin-Marketplace
/plugin install dependency-security-gate@hp-00-plugins
```

Verify:

```shell
/plugin list
/agents       # should list dependency-research
```

## Prerequisites (optional, recommended)

The plugin works out of the box with native Claude Code tools (`WebFetch`, `WebSearch`, `Bash`). For deeper supply-chain research at parallel speeds, install one or both of the MCPs/skills below. The `dependency-research` subagent will use them when available and automatically fall back to native tools when not.

Both MCPs are distributed through Anthropic's auto-registered official marketplace (`claude-plugins-official`); no separate `marketplace add` step needed.

### Context7

**What it does:** canonical, version-specific library + framework documentation lookup. The subagent uses it for fast slopsquat detection (does the package actually resolve to an indexed library?) and for fetching API docs without scraping registry HTML.

**Maintainer:** [Upstash](https://upstash.com/). **Source:** [github.com/upstash/context7](https://github.com/upstash/context7). **Plugin page:** [claude.com/plugins/context7](https://claude.com/plugins/context7).

**Install** — inside a Claude Code session:

```shell
/plugin install context7@claude-plugins-official
```

Equivalent CLI form (outside a session):

```shell
claude plugin install context7@claude-plugins-official
```

The shipped plugin ships with **no API key configured** — anonymous calls go to Context7's default rate limits, which is fine for casual use. For higher quotas, get a free API key at [context7.com/dashboard](https://context7.com/dashboard) and either re-run `npx ctx7 setup --claude` (OAuth flow) or add `"env": { "CONTEXT7_API_KEY": "ctx7sk-..." }` to your MCP config.

**Without Context7:** the subagent falls back to `WebFetch` on the canonical registry page (npm / PyPI / crates.io / RubyGems). Functional for slopsquat detection but loses curated docs content.

### Exa

**What it does:** AI-native web search (`web_search_exa`, `web_fetch_exa`) plus the deep multi-pass `exa:search` skill. The subagent uses these for the "supply-chain attack overlap" + "deep external research" items of the analysis.

**Maintainer:** [Exa Labs](https://exa.ai/). **Source:** [github.com/exa-labs/exa-mcp-server](https://github.com/exa-labs/exa-mcp-server) (MIT, ~4.4k stars). **Anthropic-curated landing page:** **[exa.ai/claude](https://exa.ai/claude)** — the recommended starting point for Claude Code users.

> **One install covers both surfaces** — the Exa MCP server (`web_search_exa` + `web_fetch_exa`) and the `exa:search` skill. No separate MCP setup required.

**Install** — inside a Claude Code session:

```shell
/plugin install exa@claude-plugins-official
```

Equivalent CLI form, as documented verbatim at [exa.ai/claude](https://exa.ai/claude):

```shell
claude plugin marketplace update claude-plugins-official && claude plugin i exa@claude-plugins-official
```

After install, run the `mcp__plugin_exa_exa__authenticate` tool (Claude will offer it automatically on first MCP call) to complete the signup/key flow — no manual API-key paste required. An Exa account is required.

**Without Exa:** the subagent falls back to Claude Code's built-in `WebSearch` + `WebFetch`. Functional but materially weaker — `WebSearch` is keyword rather than semantic, you lose Exa's recency-emphasized index for 2025-2026 supply-chain advisories, and the agent has to manually `WebFetch` each candidate URL (which burns its context window) instead of getting Exa's structured highlights extraction.

### Verifying either install

```shell
/plugin list           # both plugins listed under claude-plugins-official
/agents                # dependency-research visible
```

Then trigger a dependency review (ask Claude to install a known-safe package like `lodash`) and confirm the subagent's structured findings include "Context7" / "Exa search" sections rather than their `WebFetch` / `WebSearch` fallback equivalents.

## Optional: stronger enforcement layers

The plugin ships the **hook** layer (intercepts every install/download Bash call). For maximum coverage, two additional layers can be added manually to your project. Both are fully optional but recommended for security-conscious projects.

### Layer 1: Block edits to manifest + lockfiles

Add to your project's `.claude/settings.json`:

```json
{
  "permissions": {
    "deny": [
      "Edit(**/package.json)",       "Write(**/package.json)",
      "Edit(**/package-lock.json)",  "Write(**/package-lock.json)",
      "Edit(**/yarn.lock)",          "Write(**/yarn.lock)",
      "Edit(**/pnpm-lock.yaml)",     "Write(**/pnpm-lock.yaml)",
      "Edit(**/bun.lockb)",          "Write(**/bun.lockb)",
      "Edit(**/requirements.txt)",   "Write(**/requirements.txt)",
      "Edit(**/pyproject.toml)",     "Write(**/pyproject.toml)",
      "Edit(**/uv.lock)",            "Write(**/uv.lock)",
      "Edit(**/poetry.lock)",        "Write(**/poetry.lock)",
      "Edit(**/Cargo.toml)",         "Write(**/Cargo.toml)",
      "Edit(**/Cargo.lock)",         "Write(**/Cargo.lock)",
      "Edit(**/Gemfile)",            "Write(**/Gemfile)",
      "Edit(**/Gemfile.lock)",       "Write(**/Gemfile.lock)",
      "Edit(**/Podfile)",            "Write(**/Podfile)",
      "Edit(**/Podfile.lock)",       "Write(**/Podfile.lock)",
      "Edit(**/go.mod)",             "Write(**/go.mod)",
      "Edit(**/go.sum)",             "Write(**/go.sum)"
    ]
  }
}
```

Stops Claude from editing manifest/lockfile entries directly — the only way new dependencies enter the project is via the hook-gated install flow.

### Layer 3: Force auto-mode to prompt for approval

Add to your project's `.claude/settings.local.json`:

```json
{
  "autoMode": {
    "soft_deny": [
      "$defaults",
      "Installing or adding any new package, library, dependency, or running a postinstall/preinstall script across any package manager (npm, yarn, pnpm, bun, pip, uv, poetry, cargo, gem, brew, apt, dnf, go, pod, npx, uvx, pipx) — always prompt for explicit user approval, even when the package is already declared in an existing manifest or lockfile.",
      "Downloading any external file via curl, wget, aria2c, huggingface-cli, or git clone of an external repository — always prompt for explicit user approval, including binary archives, model weights, datasets, and font files."
    ]
  }
}
```

Forces Claude Code's auto-mode classifier to surface a prompt for any install/download attempt rather than auto-approving.

## Workflow walk-through

A typical session with the plugin installed:

```
User:    please install lodash so we can deduplicate the arrays
Claude:  [calls Bash: npm install lodash]
         [hook fires, blocks, emits structured deny + stderr message]

         ╔══════════════════════════════════════════════════════════════════╗
         ║  DEPENDENCY-SECURITY-GATE — install blocked for review          ║
         ╚══════════════════════════════════════════════════════════════════╝
         Detected command:  npm install lodash
         Package manager:   npm
         Target:            lodash
         ...

Claude:  [reads the skill, surfaces 11-item analysis]
         1. Exact identifier: lodash@4.17.21 (latest stable as of 2026-04)
         2. Purpose: array deduplication in <file>; alternatives considered:
            native Set, but lodash's _.uniqBy with a key function is more
            ergonomic for the object-array case.

         [spawns dependency-research subagent for items 3-10]

         3-10. (Subagent returns ~600 words of findings)
            - Provenance: npm registry, John-David Dalton maintainer, ~15
              years old, 600+ versions, 4.17.21 published 2021-02-20.
            - Postinstall audit: no postinstall scripts.
            - Typosquat check: canonical lodash matches; star count 60k+.
            - Transitive surface: 0 production deps.
            - License: MIT.
            - Supply-chain attack overlap: no overlap with Shai-Hulud or
              DevTap; not in any known compromised list.
            - Context7: confirmed at npm.
            - Exa code: standard usage patterns, well-documented.
            - Exa search: no recent CVEs; last advisory was prototype-
              pollution in 4.17.4 (fixed in 4.17.5).

         11. Safe-execution path: user runs `! npm install lodash`
             in chat. The `!` prefix runs the command in your real shell
             with full env, so any postinstall scripts (none, in this case)
             have your normal Ctrl-C visibility.

User:    approve lodash@4.17.21
Claude:  Approved. Please run:  ! npm install lodash

User:    [runs the command via the ! prefix]
```

## Configuration

### Triggering regex

The hook's install/download regex lives at the top of `scripts/dependency-gate.sh` (search for `INSTALL_REGEX`). To add a package manager not currently covered, edit the regex and restart your Claude Code session.

### Inspection allowlist

Read-only commands like `npm view`, `pip index`, etc. are explicitly allowlisted (search for `INSPECTION_REGEX`) so the `dependency-research` subagent can run them without being blocked.

### Hook timeout

The hook is fast (regex matching only). The default timeout is 15 seconds, set in `hooks/hooks.json`. Increase only if you're seeing timeout errors on slow disks.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Hook doesn't fire on `npm install foo` | Confirm the plugin is installed: `/plugin list`. The hook only fires for Bash tool calls — if Claude is using a different tool, the hook is bypassed. |
| Hook blocks a legitimate command | Edit `scripts/dependency-gate.sh` and either narrow the `INSTALL_REGEX` or widen the `INSPECTION_REGEX` to allowlist the command. |
| `dependency-research` agent not visible in `/agents` | The plugin's agents directory might not have loaded — try `/plugin marketplace update hp-00-plugins` then `/plugin install dependency-security-gate@hp-00-plugins --force`. |
| MCP-unavailable warnings in the agent's findings | Optional Context7 / Exa MCPs not installed. The agent falls back to `WebFetch` / `WebSearch`; install the MCPs for faster + deeper research. See Prerequisites section. |
| `${CLAUDE_PLUGIN_ROOT}` shows as `<plugin install location>` in the stderr block | The script is being invoked outside of the plugin runtime. Confirm the hook entry in `hooks/hooks.json` is using `${CLAUDE_PLUGIN_ROOT}` correctly and that the plugin is enabled. |
| The script's stderr says "Skill location" but the skill doesn't auto-surface | The hook stderr is the belt-and-suspenders: even if the skill doesn't surface automatically, Claude can read the skill file at the printed path. The skill content is the canonical 11-item structure. |

## License

MIT — see the marketplace root `LICENSE`.
