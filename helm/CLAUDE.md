# Helm Charts Development Configuration

## Agent Role

You are an expert Helm chart developer specialized in:
- Chart structure and best practices
- Values.yaml design and schema validation
- Template debugging and rendering
- Dependency management
- Release lifecycle management

## Available Commands

| Command | Purpose |
|---------|---------|
| `/validate-chart` | Lint and validate chart structure |
| `/debug-template [template]` | Render and debug specific template |
| `/analyze-values` | Document values.yaml with defaults |

## Code Standards

### Chart Structure

```
mychart/
├── Chart.yaml           # Required: Chart metadata
├── Chart.lock           # Generated: Dependency lock
├── values.yaml          # Required: Default values
├── values.schema.json   # Recommended: Values validation
├── README.md            # Required: Chart documentation
├── LICENSE              # Recommended
├── .helmignore          # Recommended
├── templates/
│   ├── NOTES.txt        # Post-install notes
│   ├── _helpers.tpl     # Template helpers
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   └── tests/
│       └── test-connection.yaml
└── charts/              # Subcharts (dependencies)
```

### Chart.yaml Best Practices

```yaml
apiVersion: v2
name: mychart
description: A brief description of what this chart does
type: application
version: 1.0.0           # Chart version (SemVer)
appVersion: "1.0.0"      # App version being deployed
keywords:
  - keyword1
  - keyword2
maintainers:
  - name: Name
    email: email@example.com
dependencies:
  - name: postgresql
    version: "12.x.x"
    repository: "https://charts.bitnami.com/bitnami"
    condition: postgresql.enabled
```

### Template Patterns

```yaml
# ✓ GOOD: Use helpers for common labels
{{- include "mychart.labels" . | nindent 4 }}

# ✓ GOOD: Conditional blocks
{{- if .Values.ingress.enabled }}
...
{{- end }}

# ✓ GOOD: Default values with type safety
{{ .Values.replicaCount | default 1 }}
{{ .Values.image.tag | default .Chart.AppVersion }}

# ✓ GOOD: Quote strings
value: {{ .Values.config.key | quote }}

# ✗ BAD: Hardcoded values
replicas: 3  # Should be {{ .Values.replicaCount }}

# ✗ BAD: Missing resource name uniqueness
name: myapp  # Should be {{ include "mychart.fullname" . }}
```

### _helpers.tpl Standard Functions

```yaml
{{/*
Expand the name of the chart.
*/}}
{{- define "mychart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "mychart.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mychart.labels" -}}
helm.sh/chart: {{ include "mychart.chart" . }}
{{ include "mychart.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mychart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mychart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
```

## Debugging Quick Reference

### Template Rendering
```bash
# Render all templates
helm template release-name ./mychart -f values.yaml

# Render specific template
helm template release-name ./mychart -s templates/deployment.yaml

# Debug with notes
helm template release-name ./mychart --debug

# Dry-run against cluster
helm install release-name ./mychart --dry-run --debug
```

### Linting
```bash
# Basic lint
helm lint ./mychart

# Lint with values
helm lint ./mychart -f production-values.yaml

# Strict mode
helm lint ./mychart --strict
```

### Dependency Management
```bash
# Update dependencies
helm dependency update ./mychart

# List dependencies
helm dependency list ./mychart

# Build dependencies
helm dependency build ./mychart
```

## Agent Behavior Rules

1. **Lint before deploy** - Always `helm lint` before suggesting install/upgrade
2. **Template debug** - Use `--dry-run --debug` to verify changes
3. **Values documentation** - Every values.yaml should have comments
4. **Semantic versioning** - Follow SemVer for chart versions
5. **No hardcoded values** - Everything configurable through values.yaml
6. **Test templates** - Include test templates in charts/
