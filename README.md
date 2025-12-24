# HP-00 Claude Code Plugin Marketplace

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Plugin%20Marketplace-blueviolet)](https://code.claude.com/docs/en/plugin-marketplaces)

A collection of Claude Code plugins by HP-00.

## Overview

This marketplace provides plugins for [Claude Code](https://www.anthropic.com/news/claude-code-plugins), Anthropic's agentic coding tool. Plugins can include slash commands, subagents, agent skills, hooks, and MCP server integrations.

> **Note**: Claude Code plugins are in public beta. Features and best practices may evolve.

## Installation

Add this marketplace to Claude Code:

```shell
/plugin marketplace add HP-00/Claude-Code-Plugin-Marketplace
```

Or using the full URL:

```shell
/plugin marketplace add https://github.com/HP-00/Claude-Code-Plugin-Marketplace.git
```

## Installing Plugins

Once the marketplace is added, install any plugin:

```shell
/plugin install <plugin-name>@hp-00-plugins
```

## Available Plugins

| Plugin | Version | Description | Category |
|--------|---------|-------------|----------|
| [prisma-schema-reviewer](plugins/prisma-schema-reviewer) | 1.0.0 | Interactive Prisma schema review with expert guidance on native types, indexes, relations, and referential actions | Database |

## Managing the Marketplace

```shell
# Update marketplace to get latest plugins
/plugin marketplace update hp-00-plugins

# List installed plugins
/plugin list

# Remove marketplace
/plugin marketplace remove hp-00-plugins
```

## Validation

Validate the marketplace structure:

```shell
/plugin validate .
```

## Plugin Structure

Each plugin should be in the `plugins/` directory with the following structure:

```
plugins/
└── your-plugin/
    ├── .claude-plugin/
    │   └── plugin.json     # Required: plugin metadata
    ├── commands/           # Optional: slash commands
    ├── agents/             # Optional: subagents
    ├── skills/             # Optional: agent skills
    ├── hooks/              # Optional: event hooks
    └── README.md           # Recommended: plugin documentation
```

### Plugin Manifest (plugin.json)

```json
{
  "name": "your-plugin",
  "version": "1.0.0",
  "description": "What your plugin does",
  "author": {
    "name": "Your Name"
  },
  "license": "MIT",
  "keywords": ["keyword1", "keyword2"]
}
```

### Adding to Marketplace

Add your plugin to `.claude-plugin/marketplace.json`:

```json
{
  "plugins": [
    {
      "name": "your-plugin",
      "source": "./plugins/your-plugin",
      "description": "What your plugin does",
      "version": "1.0.0",
      "category": "productivity",
      "keywords": ["keyword1", "keyword2"]
    }
  ]
}
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Marketplace not found | Ensure the repository is public and URL is correct |
| Plugin not loading | Run `/plugin validate .` to check structure |
| Commands not appearing | Verify command files have `.md` extension and valid frontmatter |

## Documentation

- [Claude Code Plugins](https://www.anthropic.com/news/claude-code-plugins)
- [Plugin Marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)
- [Plugins Reference](https://code.claude.com/docs/en/plugins-reference)
- [Creating Plugins](https://code.claude.com/docs/en/plugins)

## Contributing

1. Fork this repository
2. Create your plugin in `plugins/your-plugin/`
3. Add the plugin entry to `.claude-plugin/marketplace.json`
4. Submit a pull request

## License

MIT

---

**Maintainer**: HP-00
**Repository**: [GitHub](https://github.com/HP-00/Claude-Code-Plugin-Marketplace)
