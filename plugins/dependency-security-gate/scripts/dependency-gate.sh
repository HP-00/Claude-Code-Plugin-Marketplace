#!/usr/bin/env bash
# scripts/dependency-gate.sh
# PreToolUse hook: blocks dependency installs and external downloads at the
# harness layer. Triggered for every Bash tool call; pass-through for non-
# install commands. Output protocol per Claude Code hooks spec:
#   - stdout: structured JSON with hookSpecificOutput.permissionDecision="deny"
#   - stderr: human-readable block message (visible to model + user)
#   - exit 2: belt-and-suspenders block signal for older Claude Code versions
#
# Pairs with the dependency-security-gate skill (the instructional layer that
# defines the 11-item review structure + the research-delegation rule). Two
# optional companion layers documented in the plugin README:
#   - permissions.deny on manifests/lockfiles in .claude/settings.json
#   - autoMode.soft_deny on install/download attempts in .claude/settings.local.json

set -uo pipefail

# Read tool-call event JSON from stdin and extract the proposed command.
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# Empty / unparseable command: pass through (let Claude Code surface real errors).
[ -z "$COMMAND" ] && exit 0

# ---------------------------------------------------------------------------
# Inspection allowlist: anchored at line start only (no &&, no ||, no ;).
# These are the read-only commands the dependency-security-gate skill itself
# requires Claude (and the dependency-research subagent) to run as part of
# the security analysis. Without this allowlist, the install regex below
# would block the analysis from completing.
# ---------------------------------------------------------------------------
INSPECTION_REGEX='^[[:space:]]*('\
'npm[[:space:]]+(view|search|outdated|audit|ls|list|info)\b|'\
'(pip|pip3)[[:space:]]+(index|show|list|search)\b|'\
'cargo[[:space:]]+(search|info)\b|'\
'gem[[:space:]]+info[[:space:]]+.*--remote\b|'\
'curl[[:space:]]+-I\b'\
')'

if echo "$COMMAND" | grep -qE "$INSPECTION_REGEX"; then
  exit 0
fi

# ---------------------------------------------------------------------------
# Install / download trigger regex: anchored at command boundaries (^, &&,
# ||, ;, |) so chained commands like `cd app && npm install foo` are caught
# even when the install isn't at the start of the line.
#
# After the boundary, optionally consume a "transparent prefix" — a wrapper
# command that passes its arguments through to the real command. This catches
# `sudo apt install`, `nice -n 19 npm install`, `nohup pip install`,
# `bundle exec pod install`, `bundler exec rake gem-install`. Limited to a
# closed whitelist of single-word wrapper words PLUS the multi-word
# `bundle exec` / `bundler exec` form, plus 0-3 flag-like tokens, so we don't
# accidentally match echoed strings like `echo "sudo apt install"`.
# ---------------------------------------------------------------------------
INSTALL_REGEX='(^|&&|\|\||;|\|)[[:space:]]*(((sudo|nice|nohup|timeout|time|env)|((bundle|bundler)[[:space:]]+exec))([[:space:]]+[^[:space:]]+){0,3}[[:space:]]+)?('\
'(npm|yarn|pnpm|bun)[[:space:]]+(install|i|add|ci|update|upgrade)\b|'\
'(npx|bunx)[[:space:]]+|'\
'(pnpm|yarn)[[:space:]]+dlx[[:space:]]+|'\
'(pip|pip3)[[:space:]]+install\b|'\
'python[[:space:]]+-m[[:space:]]+pip[[:space:]]+install\b|'\
'(uv|poetry)[[:space:]]+(add|sync|install|update)\b|'\
'(uvx|pipx)[[:space:]]+|'\
'cargo[[:space:]]+(add|install|update)\b|'\
'gem[[:space:]]+(install|update)\b|'\
'bundle[[:space:]]+(add|install|update)\b|'\
'(brew|apt|apt-get|dnf|yum|pacman|port)[[:space:]]+(install|upgrade|-S)\b|'\
'go[[:space:]]+(get|install)\b|'\
'pod[[:space:]]+(install|update|add)\b|'\
'(curl|wget|aria2c)[[:space:]]+[^|]*(\.tar\.|\.tgz|\.zip|\.7z|\.dmg|\.pkg|\.deb|\.rpm|\.iso|\.bin|\.exe|\.msi|\.run|\.ttf|\.otf|\.woff2?|releases?/download|raw\.githubusercontent\.com|gist\.githubusercontent\.com|github\.com/[^/]+/[^/]+/raw/|\.safetensors|\.gguf|\.onnx|\.mlpackage)|'\
'curl[[:space:]]+[^;]*\|[[:space:]]*(bash|sh|zsh)|'\
'huggingface-cli[[:space:]]+download\b|'\
'git[[:space:]]+clone\b|'\
'git[[:space:]]+submodule[[:space:]]+(add|update)'\
')'

# Non-triggering command: pass through.
if ! echo "$COMMAND" | grep -qE "$INSTALL_REGEX"; then
  exit 0
fi

# ---------------------------------------------------------------------------
# We've matched a triggering command. Block.
# ---------------------------------------------------------------------------
PM=$(echo "$COMMAND" | grep -oE '(npm|yarn|pnpm|bun|pip|pip3|uv|poetry|uvx|pipx|cargo|gem|bundle|brew|apt|apt-get|dnf|yum|pacman|port|go|pod|npx|bunx|curl|wget|aria2c|huggingface-cli|git)' | head -1)
PKG=$(echo "$COMMAND" | sed -E 's/^[[:space:]]*[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+([^[:space:]]*).*/\1/' | head -1)
REASON="Dependency-security-gate: ${PM:-unknown} ${PKG:-(no target parsed)} requires review per the dependency-security-gate skill."

# Stdout: structured JSON deny (canonical, version-stable signal).
# Build via jq so any special chars in $REASON are properly JSON-escaped.
jq -n --arg reason "$REASON" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $reason
  }
}'

# Stderr: human-readable block message for both Claude and the user.
SKILL_PATH="${CLAUDE_PLUGIN_ROOT:-<plugin install location>}/skills/dependency-gate/SKILL.md"

cat >&2 <<EOF

╔══════════════════════════════════════════════════════════════════╗
║  DEPENDENCY-SECURITY-GATE — install blocked for review          ║
╚══════════════════════════════════════════════════════════════════╝

Detected command:  $COMMAND
Package manager:   ${PM:-unknown}
Target:            ${PKG:-(none parsed)}

Before this can proceed, Claude must surface a full security review
(11 items) per the dependency-security-gate skill's analysis structure.
Invoke the skill or read its SKILL.md if you haven't yet.

  Skill location:  $SKILL_PATH
  Required flow:   items 1-2 + 11 in main chat;
                   items 3-10 delegated to the dependency-research subagent.

Then wait for explicit "approve <pkg>@<version>" from the user.

To proceed after approval: user runs the command with the ! prefix in
chat. The ! prefix bypasses Claude's Bash tool, executing in the user's
shell with full environment + Ctrl-C visibility — postinstall scripts
run under the user's real env, not under Claude's tool sandbox.

This plugin's enforcement layer is the hook (this script). Optional
companion layers documented in the plugin README:
  Layer 1 (opt-in)  permissions.deny       blocks Edit/Write to manifests + lockfiles
  Layer 2 (active)  this hook              blocks install/download Bash invocations
  Layer 3 (opt-in)  autoMode.soft_deny     classifier prompt for any auto-mode escape

Reference: 2025-2026 supply-chain attacks (Shai-Hulud worm, DevTap
typosquats, slopsquatting against AI coding agents).

EOF

exit 2
