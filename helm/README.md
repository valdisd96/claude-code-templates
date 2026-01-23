# Helm Charts Claude Code Configuration

A focused Claude Code configuration for Helm chart development and debugging.

## Features

- **Chart Validation** - Lint and template rendering checks
- **Template Debugging** - Diagnose rendering errors with specific fixes
- **Values Comparison** - Diff values files across environments
- **Auto-Triggered Skills** - Context-aware help for templates, values, security
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

| Command | Description |
|---------|-------------|
| `/validate-chart [path]` | Lint and test template rendering |
| `/debug-template [name]` | Render and debug a specific template |
| `/diff-values <f1> <f2>` | Compare two values files |

## Skills (Auto-Triggered)

| Skill | Triggered When |
|-------|----------------|
| `template-debugging` | Go template errors, `{{` syntax issues |
| `values-patterns` | Working with values.yaml, structure questions |
| `chart-security` | SecurityContext, RBAC questions |

## Permissions

### Allowed (Safe Operations)
- `helm lint`, `template`, `show`, `search`
- `helm dependency`, `repo`, `list`, `status`
- `helm install --dry-run`, `helm upgrade --dry-run`
- `kubectl apply --dry-run`, `kubectl diff`
- `yq`, `jq` for YAML/JSON processing

### Denied (Destructive Operations)
- `helm install/upgrade` (without --dry-run)
- `helm uninstall`, `helm delete`, `helm rollback`
- `kubectl apply/create/delete` (without --dry-run)

## Quick Start

```bash
# Validate chart
/validate-chart ./my-chart

# Debug a specific template
/debug-template deployment

# Compare values
/diff-values values.yaml values-prod.yaml
```

## Chart Conventions

This configuration follows these conventions (based on production charts):

- Helper names use `chart.*` prefix (e.g., `chart.fullname`, `chart.labels`)
- Image config split: `image.repository`, `image.name`, `image.tag`
- Feature flags use `.enabled` pattern
- Affinity defined as template strings (rendered with `tpl`)
- Minimal security context by default

## Requirements

- `helm` v3.x installed
- Optional: `kubectl` for cluster-targeted dry-runs
- Optional: `yq` for YAML processing

## Troubleshooting

### Template Errors
Run `/debug-template [name]` - it will:
1. Render the template with `--debug`
2. Identify the specific error type
3. Suggest the fix

### Common Fixes
- `nil pointer` → Add `{{- if .Values.X }}` check or `| default`
- `can't evaluate field` → Use `$` instead of `.` inside `range`
- Type mismatch → Use `| toString` or `| int`
- Bad YAML → Check `nindent` vs `indent` usage

## License

MIT
