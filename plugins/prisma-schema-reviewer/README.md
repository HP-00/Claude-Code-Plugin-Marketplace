# Prisma Schema Reviewer

Interactive Prisma schema review with expert guidance on native types, indexes, relations, and referential actions for PostgreSQL.

## Features

- **Interactive Review Process**: Asks clarifying questions before making recommendations
- **Context7 Integration**: Fetches latest Prisma documentation for accurate advice
- **Comprehensive Validation**: Checks native types, indexes, relations, constraints, and naming
- **Structured Output**: Presents findings as Critical/Warning/Suggestion with code examples

## Requirements: Context7 MCP Server

This plugin uses **Context7** to fetch up-to-date Prisma documentation. Context7 works without an API key (with rate limits), or you can get a free API key for higher limits.

### Option 1: Quick Setup (No API Key)

Works immediately with lower rate limits:

```bash
claude mcp add context7 -- npx -y @upstash/context7-mcp
```

### Option 2: With Free API Key (Recommended)

1. **Get a free API key** at [context7.com/dashboard](https://context7.com/dashboard)
2. Run one of these commands:

**Local Server (stdio):**
```bash
claude mcp add context7 -- npx -y @upstash/context7-mcp --api-key YOUR_API_KEY
```

**Remote Server (HTTP):**
```bash
claude mcp add --transport http context7 https://mcp.context7.com/mcp --header "CONTEXT7_API_KEY: YOUR_API_KEY"
```

### Option 3: Manual JSON Configuration

Add to your Claude Code settings (`~/.claude/settings.json` or project `.claude/settings.json`):

```json
{
  "mcpServers": {
    "context7": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp", "--api-key", "YOUR_API_KEY"]
    }
  }
}
```

Or without API key:
```json
{
  "mcpServers": {
    "context7": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    }
  }
}
```

### Option 4: Environment Variable

Store your API key securely:
```bash
export CONTEXT7_API_KEY=ctx7sk_your_key_here
claude mcp add context7 -- npx -y @upstash/context7-mcp --api-key $CONTEXT7_API_KEY
```

### Verify Context7 is Working

After setup, run:
```bash
claude mcp list
```

You should see `context7` in the list.

## Plugin Installation

### Option 1: Clone Repository
```bash
git clone https://github.com/HP-00/Claude-Code-Plugin-Marketplace
cd Claude-Code-Plugin-Marketplace/plugins/prisma-schema-reviewer
```

### Option 2: Copy to Project
```bash
cp -r prisma-schema-reviewer /path/to/your/project/.claude-plugin/
```

### Option 3: Test Locally
```bash
claude --plugin-dir /path/to/prisma-schema-reviewer
```

## Usage

### Command

```
/prisma-schema-reviewer:review-schema [schema-file-path or model-name]
```

Examples:
- `/prisma-schema-reviewer:review-schema` - Review entire schema
- `/prisma-schema-reviewer:review-schema prisma/schema.prisma` - Review specific file
- `/prisma-schema-reviewer:review-schema User` - Review specific model

### Skill Triggers

The skill activates when you mention:
- "review my schema"
- "check my Prisma schema"
- "database design review"
- "index strategy"
- "Prisma best practices"

## Review Categories

| Category | What It Checks |
|----------|----------------|
| Native Types | `@db.VarChar`, `@db.Timestamptz`, `@db.JsonB`, `@db.Decimal` |
| Indexes | FK indexes, composite ordering, GIN for arrays |
| Relations | `onDelete` actions, self-references, many-to-many |
| Constraints | `@@unique`, nullable fields in constraints |
| Naming | camelCase fields, `*Id` for FKs, `*At` for timestamps |

## Reference Files

The plugin includes detailed reference documentation:

- `references/native-types.md` - PostgreSQL native type mappings
- `references/indexes.md` - Index strategy and GIN indexes
- `references/relations.md` - Relation patterns and self-references
- `references/referential-actions.md` - onDelete/onUpdate decision tree
- `examples/good-patterns.prisma` - Complete e-commerce schema example

## Troubleshooting

### Context7 Rate Limiting

If you see rate limit errors:
1. Get a free API key at [context7.com/dashboard](https://context7.com/dashboard)
2. Update your MCP configuration with the key

### Context7 Not Found

Ensure you have Node.js installed (required for `npx`):
```bash
node --version  # Should be v18+
```

## License

MIT
