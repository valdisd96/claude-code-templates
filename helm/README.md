# Helm Charts Claude Code Configuration

A Claude Code configuration for Helm chart development, validation, and debugging.

## Features

- **Chart Validation**: Comprehensive linting and structure checks
- **Template Debugging**: Render and debug specific templates
- **Best Practices**: Enforced patterns for production-ready charts
- **Safe Permissions**: Dry-run by default for install/upgrade

## Installation

### Via Script
```bash
./apply-config.sh helm /path/to/your/charts-project
```

### Via Plugin
```bash
/plugin marketplace add uvauchok/claude-code-templates
/plugin install helm@claude-code-templates
```

## Available Commands

| Command | Description |
|---------|-------------|
| `/validate-chart` | Lint and validate chart structure |
| `/debug-template [template]` | Render and debug specific template |
| `/analyze-values` | Document values.yaml with schema |

## Permissions

### Allowed
- `helm lint`, `template`, `show`, `search`
- `helm dependency`, `repo`, `list`, `status`
- `helm install --dry-run`, `helm upgrade --dry-run`

### Denied
- `helm uninstall --no-hooks`
- `helm rollback` (requires explicit approval)

## Requirements

- `helm` v3.x installed
- Optional: `kubectl` for cluster-targeted dry-runs

## Customization

Edit `.claude/settings.json` to:
- Enable actual install/upgrade operations
- Add custom repository configurations
- Configure namespace defaults
