---
name: dependency-gate
description: Pre-install security analysis for external dependencies, model pulls, and downloads. Surfaces when Claude is about to install or download external content; defines the 11-item review structure, the research-delegation pattern, and the explicit-approval flow. Pairs with the dependency-security-gate plugin's PreToolUse hook.
---

# Dependency-security-gate — analysis structure (mode-agnostic, non-negotiable)

**Before initiating ANY action that brings external content into a repository or onto the development machine — package install, binary download, model weights pull, dataset fetch, asset/font download, git clone of an external repository, or fetch-and-execute commands like `npx` / `uvx` / `curl | sh` — Claude must STOP, inform the user, perform a full security analysis, and wait for explicit user approval before proceeding.** This rule applies in every Claude Code permission mode without exception (`default`, `acceptEdits`, `plan`, `auto`, `dontAsk`, `bypassPermissions` / `--dangerously-skip-permissions`). There is no mode, no autonomy state, no task-completion pressure, and no deadline proximity that exempts Claude from this rule.

## Triggering actions

The rule applies to (non-exhaustive — when in doubt, treat as triggering):

- **JavaScript / TypeScript:** `npm install`, `npm i`, `npm add`, `npm ci`, `npm update`, `npm exec`, `npx <pkg>`, `yarn add`, `yarn install`, `yarn upgrade`, `pnpm add`, `pnpm install`, `pnpm i`, `pnpm up`, `pnpm dlx`, `bun add`, `bun install`, `bun i`, `bun upgrade`, `bunx`
- **Python:** `pip install`, `pip3 install`, `python -m pip install`, `uv add`, `uv pip install`, `uv sync`, `uvx <pkg>`, `poetry add`, `poetry install`, `poetry sync`, `poetry update`, `pipx install`, `conda install`, `mamba install`
- **Rust / Go / Ruby / iOS / system:** `cargo add`, `cargo install`, `cargo update`, `gem install`, `gem update`, `bundle add`, `bundle install`, `bundle update`, `pod install`, `pod update`, `pod add`, `go get`, `go install`, `go mod download`, `brew install`, `brew upgrade`, `apt install`, `apt-get install`, `apt update && apt upgrade`, `dnf install`, `yum install`, `pacman -S`, `port install`
- **Direct downloads:** `curl -O`, `curl -o`, `curl ... | bash`, `curl ... | sh`, `wget`, `aria2c`, `git clone` of any repository not already owned by the user, `git submodule add`, `git submodule update --init`, fetching binary content via WebFetch / Read from external URLs
- **Model + dataset pulls:** `huggingface-cli download`, `hf_hub_download`, any Python that calls `from_pretrained(...)`, `AutoModel.from_pretrained`, `AutoTokenizer.from_pretrained`, `pipeline(...)`, `datasets.load_dataset`, `kaggle datasets download`, downloads from S3 / GCS / Azure Blob, GitHub Release tarballs, model registry pulls
- **Binary / asset fetches:** `.dmg` / `.pkg` / `.deb` / `.rpm` installers, `.tar.gz` / `.zip` / `.7z` archives from external sources, prebuilt iOS frameworks (`.framework`, `.xcframework`), native libraries (`.dylib`, `.so`, `.dll`), font files from external sources, any binary ML weights (`.safetensors`, `.bin`, `.gguf`, `.onnx`, `.mlmodel`, `.mlpackage`)

If a planned action does not appear above but moves bytes from an external source onto this machine, treat it as triggering.

## Required security analysis (every time, before the action)

**Research delegation rule (mandatory — context pollution control).** All research-heavy work for items 3–10 below MUST be performed by a subagent invocation via the Agent tool, NEVER inline in the main chat. The subagent returns a structured-markdown summary; Claude folds the summary into the analysis block in chat without the raw output (registry dumps, GitHub source pastes, Exa search result lists). Items 1, 2, and 11 are model-judgment items and stay in the main chat. For batch reviews of multiple distinct dependencies in one turn, spawn parallel agents (one per dependency) in a single Agent tool-call message so they run concurrently.

**Subagent invocation pattern:**

```
Agent({
  description: "Dependency security research: <pkg>@<version>",
  subagent_type: "dependency-research",
  prompt: <name the exact package + pinned version + the file or feature
          that needs it. The agent definition encodes the full research
          protocol (parallel Context7 + Exa code MCP + Exa search MCP +
          deep `/exa:search` skill — with WebFetch/WebSearch fallbacks
          when those MCPs/skills are not installed — registry inspection
          commands per package manager, postinstall audit via gh api /
          WebFetch, structured-markdown output with one heading per item
          3-10, ~600-word cap with override for genuinely suspicious
          findings, 72-hour package-cooldown check). The prompt here only
          needs to identify the target and any relevant project context
          the agent should weigh — the generic threat model is already
          in the agent's system prompt.>
})
```

If the subagent's findings contradict Claude's preliminary thinking on items 1, 2, or 11, those items must be updated before requesting approval — do not paper over disagreements.

**Required items in the analysis block** (assembled from subagent summary + main-chat judgment, surfaced as a single structured block in chat — every item must be addressed explicitly, none may be skipped, abbreviated, or summarised away):

1. **Exact identifier** — pinned version (`<pkg>@<x.y.z>`) or full URL with declared file size and expected SHA-256 (or other documented checksum). No floating ranges, no `latest` tags, no unspecified URLs.
2. **Purpose** — which file, feature, notebook, or workflow needs this; what alternatives were considered; why no existing dependency in the project's manifest files already satisfies the need.
3. **Provenance** — registry or host (npm / PyPI / crates.io / RubyGems / HuggingFace / GitHub Releases / S3 / etc.), publisher or maintainer identity, project age, total version count, age of the specific version being requested, last-update timestamp. (Subagent gathers; Claude folds in.)
4. **Inspection findings** — the research subagent runs the relevant inspection commands and reports the salient fields in its summary. Reference commands the subagent uses:
   - npm: `npm view <pkg> time versions maintainers scripts repository.url license dependencies`
   - PyPI: `pip index versions <pkg>` plus `curl -s https://pypi.org/pypi/<pkg>/json | jq '.info | {author, home_page, license, project_urls, requires_python, requires_dist}'`
   - crates.io: `cargo search <pkg>` plus a fetch of `crates.io/api/v1/crates/<pkg>` metadata
   - RubyGems: `gem info <pkg> --remote`
   - HuggingFace: model card link, last-modified timestamp, monthly downloads, author / organization, declared license, file format (require `.safetensors`; flag and refuse `.pickle` / `.pt` from untrusted authors)
   - Direct URL: `curl -I <url>` for HTTP headers, scheme (HTTPS required), declared content-type, content-length, server identity

   Claude folds the salient findings (last-update, maintainer identity, version count, content-type) into the analysis block as a concise paragraph. Do **not** paste raw command output verbatim into the main chat — that's exactly the pollution this rule prevents.
5. **Postinstall / preinstall script audit** — the research subagent fetches the GitHub source at the exact tag (or the published tarball) and audits any `postinstall` / `preinstall` / `prepublish` / `prepare` script. The subagent's summary states whether scripts exist and what they do in plain language; if a script touches the filesystem outside `node_modules`, makes network calls, reads environment variables, or writes to user directories, the subagent flags it explicitly. Claude folds the finding into the analysis block as a one-paragraph plain-language summary; raw script content appears in the main chat ONLY if the subagent specifically flagged it as suspicious and you'd want to inspect it before approving.
6. **Typosquat / slopsquat check** — the canonical project name, its GitHub URL, its star count, and confirmation that the requested package name matches exactly. Explicitly call out names that resemble popular packages (single-character substitutions, hyphenation differences, prefix / suffix variants, organisation-name lookalikes). For any package Claude itself proposed (rather than one the user named first), the subagent must explicitly verify the package exists on the registry and is the one Claude intended — do not assume hallucinated names map to real packages.
7. **Transitive dependency surface** — approximate count of indirect dependencies pulled in. Flag any indirect dep that has had a CVE or public security advisory in the last 90 days. (Subagent gathers; Claude folds the count + flags into the analysis.)
8. **License** — report the declared SPDX identifier verbatim; flag GPL/AGPL/SSPL/proprietary/unknown for explicit user decision before proceeding. This skill does not assess compatibility with the installer's project license — only reports the dependency's declared license and flags copyleft/proprietary for the user's decision.
9. **2025-2026 supply-chain attack overlap** — the subagent explicitly cross-references against known recent attack patterns:
   - Shai-Hulud npm worm (Nov 2025: 796 packages compromised, AWS / GCP / Azure credential exfil via preinstall scripts)
   - DevTap typosquat campaign (Apr-May 2026: bland infrastructure-sounding names — `centralogger`, `node-fetch-lite`, `node-gyp-runtime`, `connector-agent`, `node-env-resolve`)
   - Slopsquatting (attackers registering package names LLMs are known to hallucinate)
   - Post-install RCE campaigns

   State whether the candidate package shows any indicator overlap. "No overlap, reasoned as follows: …" is a valid conclusion; silence is not.
10. **Deep external research findings** — the research subagent runs both external-research channels IN PARALLEL within itself (single message, two concurrent tool calls) and reports the salient findings:
    - **Context7** (`mcp__plugin_context7_context7__resolve-library-id` + `mcp__plugin_context7_context7__query-docs`) — canonical docs, confirms the package exists at the claimed registry, surfaces version-specific behavior and recent migration breaks. Particularly important for slopsquat detection where Claude's prior may name a hallucinated package. **Fallback if MCP unavailable:** `WebFetch` the canonical registry URL directly (npm/PyPI/crates.io/RubyGems package page).
    - **Exa search** — run BOTH the single-search MCP `mcp__plugin_exa_exa__web_search_exa` AND the deep multi-pass `/exa:search` skill (`Skill(skill: "exa:search", ...)`). The MCP gives a fast first signal; the skill orchestrates multiple Exa queries across angles for thorough coverage. The two are complementary, not redundant — recent CVEs / GHSA / RUSTSEC / OSV advisories, supply-chain incident postmortems, maintainer reputation, 2025-2026 security news. Verifies item 9's overlap claim with **current** data rather than only training-data priors. **Fallback if MCP/skill unavailable:** `WebSearch` with the same query patterns + `WebFetch` on top results; the subagent's prompt documents a 3-5 query sequence covering CVE/advisories, maintainer change, typosquat, postinstall RCE, and unmaintained-fork patterns.

    The subagent must invoke both channels (or their native fallbacks); neither may be substituted for the other. The subagent's summary states the most relevant findings from each channel as concise prose, never as raw search-result dumps. Claude folds these findings into the analysis block as one short paragraph per channel (or a combined paragraph if findings align). If any channel returned evidence contradicting items 1–9, the subagent flags the contradiction in its summary and Claude updates the affected items before requesting approval.
11. **Recommended safe-execution path** — give the exact command the user should run. **Default recommendation: the user runs `! <command>` in chat** (the `!` prefix executes the command in the user's shell rather than via Claude's Bash tool, so postinstall scripts run under the user's full environment with `Ctrl-C` available at any moment of unexpected behavior). For downloads: include the `shasum -a 256 <file>` (or platform-equivalent) checksum-verification command the user should run after the fetch completes, with the expected hash for comparison.

## Explicit approval requirement

After surfacing the full analysis, Claude must wait for the user's explicit, unambiguous approval — e.g., the literal text `approve <pkg>@<version>` or `go ahead with <download URL>`. Implicit or generic signals ("ok", "yes", "sounds good", "continue") are insufficient; if the user's reply does not name the exact package or URL, re-prompt with the specific identifier and wait again.

## Mode-agnostic enforcement (read carefully)

This rule **overrides any permission-mode default** that would otherwise allow the action without a pause. Specifically:

- **`auto` mode:** manifest-declared installs are otherwise auto-approved by the classifier without prompting. This rule still applies — surface the full analysis and pause regardless of what the classifier would have decided.
- **`bypassPermissions` / `--dangerously-skip-permissions`:** permission prompts are skipped at the harness level. This rule still applies — Claude self-imposes the pause even though the harness would not require one.
- **`plan` mode:** this rule applies to every install or download the proposed plan would trigger once executed; flag each one in the plan as requiring this same review at execution time.
- **`acceptEdits`, `default`, `dontAsk`:** same rule, no exceptions.

There is no permission-mode loophole. If Claude finds itself reasoning "in this mode it's fine to skip the analysis because…", that reasoning is wrong and the rule still applies.

## Why this rule exists

Dependencies pulled onto a developer's machine can:

- Exfiltrate credentials (AWS, GCP, SSH, registry tokens, browser cookies, GitHub tokens) via postinstall scripts
- Backdoor application code that ships to production users
- Poison published artefacts (packages, datasets, model weights) and reach every downstream consumer
- Compromise CI/CD pipelines via build-time code execution

The cost of one missed review is unbounded. The cost of one full review is roughly sixty seconds plus the time to read both external research channels. Always pause; always run the full analysis (including both external research tools or their native fallbacks); always wait for explicit approval. This rule is non-negotiable and applies even when the rest of the work is racing against a deadline.
