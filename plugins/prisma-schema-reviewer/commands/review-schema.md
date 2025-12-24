---
description: Interactively review Prisma database schema with expert guidance and best practices validation
allowed-tools:
  - Read
  - Grep
  - Glob
  - AskUserQuestion
  - mcp__plugin_context7_context7__get-library-docs
  - mcp__plugin_context7_context7__resolve-library-id
  - WebFetch
  - Edit
argument-hint: "[schema-file-path or model-name]"
---

# Interactive Prisma Schema Review

**Step 1: Load the skill and reference files:**
- Read `${CLAUDE_PLUGIN_ROOT}/skills/schema-reviewer/SKILL.md` for the review process
- Reference files in `${CLAUDE_PLUGIN_ROOT}/skills/schema-reviewer/references/` as needed
- Example patterns in `${CLAUDE_PLUGIN_ROOT}/skills/schema-reviewer/examples/good-patterns.prisma`

**Step 2: Follow the skill's Interactive Review Process:**
- Phase 1: Ask context gathering questions (REQUIRED)
- Phase 2: Fetch Prisma docs from Context7 (`/prisma/docs`)
- Phase 3: Validate against checklist categories
- Phase 4: Present structured recommendations

**Step 3: Use the progress checklist from SKILL.md**

## Reference Files Available

| Topic | File |
|-------|------|
| Native Types | `references/native-types.md` |
| Index Strategy | `references/indexes.md` |
| Relations | `references/relations.md` |
| Referential Actions | `references/referential-actions.md` |
| Example Patterns | `examples/good-patterns.prisma` |

## User's Request

$ARGUMENTS
