# Helm Charts Development Configuration

## Agent Role

You are a Helm chart developer helping with:
- Chart templating and debugging
- Values.yaml structure and patterns
- Template rendering issues

## Available Commands

| Command | Purpose |
|---------|---------|
| `/validate-chart` | Lint chart and test template rendering |
| `/debug-template [name]` | Render and debug a specific template |
| `/diff-values <f1> <f2>` | Compare two values files |

## Chart Structure

```
chart/
├── Chart.yaml
├── values.yaml
├── values-envtype/          # Environment-specific values
│   └── values-common.yaml
├── templates/
│   ├── _helpers.tpl         # Standard helpers
│   ├── _tplvalues.tpl       # Template value rendering utility
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── configmap-*.yaml
│   ├── secret.yaml
│   └── external-secrets-*.yaml
└── secrets-helm/            # Encrypted secrets (sops)
```

## Helper Naming Convention

We use generic `chart.*` prefix (not chart-name-specific):

```yaml
{{- define "chart.name" -}}
{{- define "chart.fullname" -}}
{{- define "chart.labels" -}}
{{- define "chart.selectorLabels" -}}
{{- define "chart.serviceAccountName" -}}
{{- define "chart.labelsConfigmapSecret" -}}  # Lighter labels for ConfigMaps/Secrets
```

## Template Patterns

### Standard helper usage
```yaml
metadata:
  name: {{ include "chart.fullname" . }}
  labels:
    {{- include "chart.labels" . | nindent 4 }}
```

### Feature flags
```yaml
{{- if .Values.ingress.enabled }}
# ingress resources
{{- end }}
```

### Optional blocks with `with`
```yaml
{{- with .Values.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 8 }}
{{- end }}
```

### Template-rendered values (for affinity etc.)
```yaml
{{- if .Values.affinity }}
affinity:
  {{- tpl .Values.affinity . | nindent 8 }}
{{- end }}
```

### ConfigMap checksum for pod restart on config change
```yaml
annotations:
  checksum/config: {{ include (print $.Template.BasePath "/configmap-config.yaml") . | sha256sum }}
```

## Values.yaml Patterns

### Image configuration (split format)
```yaml
image:
  repository: "registry.example.com/container-registry"
  name: myapp
  tag: ""
  pullPolicy: Always
```

### Feature flags - always use `.enabled`
```yaml
ingress:
  enabled: false
  configurations: [...]

datadog:
  enabled: false
```

### Affinity as template string
```yaml
affinity: |-
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
    - labelSelector:
        matchExpressions:
        - key: app
          operator: In
          values:
          - {{ .Chart.Name }}
      topologyKey: "kubernetes.io/hostname"
```

### Security context (minimal default)
```yaml
podSecurityContext: {}

securityContext:
  privileged: false
  allowPrivilegeEscalation: false
  capabilities:
    drop: ["ALL"]
```

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `nil pointer evaluating` | Missing value | Add `default` or `if` check |
| `can't evaluate field` | Wrong scope in range | Use `$` for root context |
| `expected string; got int` | Type mismatch | Use `toString` or `int` |
| YAML parse error | Bad indentation | Use `nindent` properly |

## Quick Commands

```bash
# Lint chart
helm lint ./chart --strict

# Render all templates
helm template test-release ./chart --debug

# Render specific template
helm template test-release ./chart -s templates/deployment.yaml

# Render with environment values
helm template test-release ./chart -f values-envtype/values-common.yaml
```

## Behavior Rules

1. **Diagnose first** - Render the template to see the actual error
2. **Be specific** - Fix the specific problem, don't dump documentation
3. **Match existing patterns** - Follow the conventions already in the chart
4. **Test changes** - Run `helm template` to verify fixes work
