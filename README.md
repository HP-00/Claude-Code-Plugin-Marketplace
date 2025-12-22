# HP-00 Claude Code Plugin Marketplace

A collection of Claude Code plugins by HP-00.

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

| Plugin | Description |
|--------|-------------|
| *Coming soon* | |

## Managing the Marketplace

```shell
# Update marketplace to get latest plugins
/plugin marketplace update hp-00-plugins

# List installed plugins
/plugin list

# Remove marketplace
/plugin marketplace remove hp-00-plugins
```

## Adding Your Own Plugins

Each plugin should be in the `plugins/` directory with the following structure:

```
plugins/
└── your-plugin/
    ├── .claude-plugin/
    │   └── plugin.json
    ├── commands/        # Optional: slash commands
    ├── agents/          # Optional: subagents
    ├── skills/          # Optional: agent skills
    └── hooks/           # Optional: event hooks
```

Then add it to `.claude-plugin/marketplace.json`:

```json
{
  "plugins": [
    {
      "name": "your-plugin",
      "source": "./plugins/your-plugin",
      "description": "What your plugin does",
      "version": "1.0.0"
    }
  ]
}
```

## License

MIT
