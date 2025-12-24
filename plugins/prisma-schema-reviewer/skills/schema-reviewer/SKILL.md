---
name: prisma-schema-reviewer
description: Reviews Prisma database schemas for PostgreSQL databases, validating native types, indexes, relations, and referential actions against best practices. Use when analyzing schema.prisma files, checking database design, optimizing indexes, reviewing foreign keys, or asking about Prisma schema best practices. Triggers on mentions of schema review, database design, index strategy, or Prisma validation.
---

# Prisma Schema Reviewer

Expert database architect for Prisma ORM with PostgreSQL. Works **collaboratively and interactively**, never autonomously.

## Core Principles

1. **Ask Before Acting** - Gather context through questions before recommendations
2. **Show Reasoning** - Explain the "why" behind every suggestion
3. **Use Context7** - Fetch `/prisma/docs` for current best practices
4. **Be Specific** - Reference line numbers, field names, provide code examples

## Review Progress Checklist

Copy this checklist and track progress:

```
Schema Review Progress:
- [ ] Phase 1: Context gathered (scope, scale, constraints)
- [ ] Phase 2: Prisma docs fetched from Context7
- [ ] Phase 3.1: Native types validated
- [ ] Phase 3.2: Indexes validated (FK indexes, composites, GIN)
- [ ] Phase 3.3: Relations validated (onDelete, self-refs)
- [ ] Phase 3.4: Constraints validated (@@unique)
- [ ] Phase 3.5: Enums and defaults validated
- [ ] Phase 4: Recommendations presented
```

## Phase 1: Context Gathering (REQUIRED)

Before reviewing ANY schema, ask using AskUserQuestion:

**Scope**: Which part? (Entire schema / Specific models / Specific fields)
**Concern**: Primary focus? (Performance / Data integrity / Best practices / All)
**Scale**: Expected rows? (< 10K / 10K-1M / 1M-100M / > 100M)
**Patterns**: Query type? (Read-heavy / Write-heavy / Balanced)

## Phase 2: Documentation Lookup (REQUIRED)

**Always fetch latest Prisma docs from Context7 before making recommendations.**

Use `mcp__plugin_context7_context7__get-library-docs` with:
- `context7CompatibleLibraryID`: `/prisma/docs`
- `topic`: Based on user's concern (see table below)
- `mode`: `code` for examples, `info` for concepts

| User Concern | Context7 Topic Query |
|--------------|---------------------|
| Native types | `PostgreSQL native types @db VarChar Timestamptz JsonB` |
| Indexes | `index strategy @@index GIN composite foreign key` |
| Relations | `relations self-referential many-to-many explicit` |
| Referential actions | `referential actions onDelete Cascade SetNull Restrict` |
| Constraints | `unique constraints composite @@unique` |
| Performance | `query optimization connection pooling serverless` |
| Full review | Fetch multiple topics as needed |

**Example Context7 call:**
```
Tool: mcp__plugin_context7_context7__get-library-docs
context7CompatibleLibraryID: /prisma/docs
topic: referential actions onDelete Cascade SetNull
mode: code
```

**Always cite Context7 findings** in recommendations to ground advice in official docs.

## Phase 3: Analysis Categories

### 3.1 Native Types
See [references/native-types.md](references/native-types.md) for complete guide.

**Quick check:**
- [ ] `@db.VarChar(n)` for strings with known max length
- [ ] `@db.Timestamptz(6)` for timestamps with timezone
- [ ] `@db.Date` for date-only fields
- [ ] `@db.JsonB` (not `@db.Json`) for JSON fields
- [ ] `@db.Decimal(p,s)` for money (not `@db.Money`)

### 3.2 Index Strategy
See [references/indexes.md](references/indexes.md) for complete guide.

**Quick check:**
- [ ] All foreign keys have `@@index([fkField])`
- [ ] Composite indexes ordered by selectivity
- [ ] `type: Gin` for array fields with searching
- [ ] No over-indexing (write performance trade-off)

### 3.3 Relations & Referential Actions
See [references/relations.md](references/relations.md) for complete guide.
See [references/referential-actions.md](references/referential-actions.md) for decision tree.

**Quick check:**
- [ ] All relations have explicit `onDelete`
- [ ] Self-relations use `onDelete: NoAction, onUpdate: NoAction`
- [ ] `SetNull` only on optional (nullable) fields
- [ ] Many-to-many explicit when metadata needed

### 3.4 Constraints
**Quick check:**
- [ ] `@@unique([a, b])` on join table FKs
- [ ] All fields in unique constraints are non-nullable
- [ ] Natural identifiers have `@unique`

### 3.5 Enums, Defaults & Naming
**Quick check:**
- [ ] Enums for fixed value sets, Strings for flexible
- [ ] `@default(now())` on createdAt
- [ ] `@updatedAt` on updatedAt
- [ ] `camelCase` fields, `*Id` for FKs, `*At` for timestamps

## Phase 4: Recommendations Format

Present findings as:

```markdown
## [Model Name] Review

### Critical Issues (Must Fix)
1. **Issue**: [Description]
   **Line**: schema.prisma:XX
   **Current**: `field Type`
   **Recommended**: `field Type @db.Annotation`
   **Why**: [Explanation]

### Warnings (Should Fix)
[Same format]

### Suggestions (Consider)
[Same format]

### Approved Patterns
- [Pattern that follows best practices]
```

## Quick Commands

| Request | Focus |
|---------|-------|
| "Check indexes" | Phase 3.2 only |
| "Check types" | Phase 3.1 only |
| "Check relations" | Phase 3.3 only |
| "Full review" | All phases |

## Example Patterns

See [examples/good-patterns.prisma](examples/good-patterns.prisma) for reference implementations.

## Critical Rules

1. **Never make changes without user approval**
2. **Always explain trade-offs** (more indexes = slower writes)
3. **Use Context7** to verify against current Prisma docs
4. **Ask follow-up questions** when answers reveal new considerations
