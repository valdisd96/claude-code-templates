# Kubernetes Claude Code Configuration

A Claude Code configuration for Kubernetes cluster management, diagnostics, and troubleshooting.

## Features

- **Cluster Diagnostics**: Comprehensive health checks and issue detection
- **Safe Permissions**: Read-heavy permissions, dangerous operations denied by default
- **Troubleshooting Commands**: Structured debugging workflows
- **Best Practices**: Security-focused manifest patterns

## Installation

### Via Script
```bash
./apply-config.sh kubernetes /path/to/your/k8s-project
```

### Via Plugin
```bash
/plugin marketplace add uvauchok/claude-code-templates
/plugin install kubernetes@claude-code-templates
```

## Available Commands

| Command | Description |
|---------|-------------|
| `/diagnose` | Analyze cluster health, find unhealthy resources |
| `/troubleshoot [resource]` | Debug specific pod/service/deployment |
| `/security-audit` | Review RBAC, network policies, security contexts |

## Permissions

### Allowed (Read-Only)
- `kubectl get`, `describe`, `logs`, `top`
- `kubectl config`, `explain`, `api-resources`
- `helm list`, `status`, `get`

### Denied (Destructive)
- `kubectl delete namespace`
- `kubectl delete --all`
- `kubectl drain --force`

## Requirements

- `kubectl` configured with cluster access
- Optional: `helm` for Helm-related operations
- Optional: Metrics server for `kubectl top`

## Customization

Edit `.claude/settings.json` to:
- Add namespaces to permission patterns
- Enable specific write operations
- Configure custom environment variables
