# Helm Charts Claude Code Configuration

A comprehensive Claude Code configuration for Helm chart development, validation, debugging, and security analysis.

## Features

- **Memory Bank System** - Persistent context about charts, values, and decisions across sessions
- **Chart Validation** - Comprehensive linting and structure checks
- **Template Debugging** - Render and debug templates with custom values
- **Values Analysis** - Deep analysis of values.yaml structure and types
- **Dependency Management** - Subchart analysis, version checks, lock file status
- **Security Scanning** - Pod Security Standards, RBAC, NetworkPolicy checks
- **Auto-Triggered Skills** - Expert guidance on templates, values, and security
- **Safe Permissions** - Dry-run by default, destructive commands blocked

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

### Memory Bank
| Command | Description |
|---------|-------------|
| `/init-memory-bank` | Analyze chart repository, create persistent documentation |
| `/update-memory-bank` | Update docs based on recent changes |

### Chart Development
| Command | Description |
|---------|-------------|
| `/validate-chart [path]` | Lint and validate chart structure |
| `/debug-template [name]` | Render and debug specific template |
| `/analyze-values [file]` | Deep analysis of values.yaml structure |
| `/analyze-dependencies [path]` | Subchart analysis, version checks |
| `/diff-values <f1> <f2>` | Compare two values files |
| `/security-scan [path]` | Security best practices check |

## Skills (Auto-Triggered)

| Skill | Triggered When |
|-------|----------------|
| `template-debugging` | Go template errors, `{{` syntax issues |
| `values-patterns` | Working with values.yaml, structure questions |
| `chart-security` | SecurityContext, RBAC, NetworkPolicy |

## Memory Bank Structure

After running `/init-memory-bank`, your chart repository will have:

```
docs/memory-bank/
├── chartbrief.md       # Chart overview, maintainers
├── valuesContext.md    # Values hierarchy, types, flags
├── templatePatterns.md # Named templates, helpers
├── releaseContext.md   # Environments, dependencies
├── activeContext.md    # Current session notes
└── progress.md         # Work tracking
```

## Permissions

### Allowed (Safe Operations)
- `helm lint`, `template`, `show`, `search`
- `helm dependency`, `repo`, `list`, `status`, `history`
- `helm install --dry-run`, `helm upgrade --dry-run`
- `helm package`, `verify`, `pull`, `create`
- `kubectl apply --dry-run`, `kubectl diff`, `kubectl explain`
- `yq`, `jq` for YAML/JSON processing

### Denied (Destructive Operations)
- `helm install` (without --dry-run)
- `helm upgrade` (without --dry-run)
- `helm uninstall`, `helm delete`
- `helm rollback`
- `kubectl apply`, `create`, `delete`, `patch`

## MCP Servers

This configuration includes MCP servers for enhanced capabilities:

| Server | Purpose |
|--------|---------|
| `filesystem` | Navigate chart structures, read templates |
| `memory` | Maintain context across sessions |

## Requirements

- `helm` v3.x installed
- Optional: `kubectl` for cluster-targeted dry-runs
- Optional: `yq` for YAML processing
- Optional: `jq` for JSON processing

## Customization

### Enable Actual Deployments
Edit `.claude/settings.json` to allow install/upgrade:
```json
{
  "permissions": {
    "allow": [
      "Bash(helm install*)",
      "Bash(helm upgrade*)"
    ]
  }
}
```

### Add Custom Repositories
```json
{
  "env": {
    "HELM_REPO_BITNAMI": "https://charts.bitnami.com/bitnami"
  }
}
```

## Quick Start

1. **Apply configuration** to your charts project
2. **Run `/init-memory-bank`** to analyze and document your charts
3. **Use `/validate-chart`** to check chart health
4. **Use `/debug-template`** when templates don't render correctly
5. **Run `/security-scan`** before deploying to production

## Example Workflow

```bash
# Start session - Claude will read Memory Bank automatically

# Validate chart
/validate-chart ./my-chart

# Debug a specific template
/debug-template deployment

# Analyze values structure
/analyze-values

# Compare dev vs prod values
/diff-values values.yaml values-prod.yaml

# Security check before release
/security-scan

# End session - update Memory Bank
/update-memory-bank
```

## Troubleshooting

### Template Errors
- Use `/debug-template [name]` for detailed rendering output
- Check for nil pointer errors (missing values)
- Verify whitespace control with `{{-` and `-}}`

### Values Issues
- Run `/analyze-values` to understand structure
- Check for type mismatches (string vs int)
- Use `/diff-values` to compare environments

### Dependency Problems
- Run `/analyze-dependencies` to check status
- Verify Chart.lock is in sync
- Check repository availability

## License

MIT
