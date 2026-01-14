# Claude Code Templates

Pre-built Claude Code configurations for domain-specific workflows.

## Available Configurations

| Domain | Description |
|--------|-------------|
| `tfx` | TensorFlow Extended & ML pipelines |
| `data-science` | Jupyter notebooks & EDA workflows |
| `kubernetes` | Cluster management & diagnostics |
| `helm` | Helm charts development |

## Quick Start

```bash
# Apply a configuration to your project
./apply-config.sh <domain> <target-path>

# Examples
./apply-config.sh tfx /path/to/ml-project
./apply-config.sh kubernetes .

# List available configurations
./apply-config.sh --list
```

## What Gets Installed

Each configuration includes:
- `CLAUDE.md` - Agent instructions and domain expertise
- `.claude/settings.json` - Permissions and environment
- `.claude/commands/` - Domain-specific slash commands
- `.mcp.json` - MCP server integrations (where applicable)

## License

MIT
