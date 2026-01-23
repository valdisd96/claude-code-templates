---
description: "Activate when user encounters Go template errors, asks about Helm templating, or has issues with {{ }} syntax, sprig functions, or template rendering failures"
---

# Helm Template Debugging

When a user has a template error, help them fix it. Don't dump documentation - diagnose the specific problem.

## Quick Diagnosis

Run this first to see the actual error:
```bash
helm template test-release ./chart --debug 2>&1
```

For a specific template:
```bash
helm template test-release ./chart -s templates/deployment.yaml --debug
```

## Common Errors & Fixes

### "nil pointer evaluating"
The value path doesn't exist.

```yaml
# Bad - fails if .Values.optional doesn't exist
value: {{ .Values.optional.field }}

# Fix 1 - Check parent exists
{{- if .Values.optional }}
value: {{ .Values.optional.field }}
{{- end }}

# Fix 2 - Use default
value: {{ .Values.optional.field | default "fallback" }}

# Fix 3 - Use dig for deep paths
value: {{ dig "optional" "field" "fallback" .Values }}
```

### "can't evaluate field X in type interface"
Lost context inside `range` - use `$` or save root context.

```yaml
# Bad - inside range, . is the loop item
{{- range .Values.items }}
name: {{ .Release.Name }}  # FAILS
{{- end }}

# Fix - use $ for root context
{{- range .Values.items }}
name: {{ $.Release.Name }}  # WORKS
{{- end }}
```

### YAML indentation broken
Use `nindent` not `indent` when starting a new line.

```yaml
# Bad
labels:
  {{ include "chart.labels" . }}

# Good - nindent for new line
labels:
  {{- include "chart.labels" . | nindent 2 }}

# For inline content use indent
data: |
  {{ .Values.config | indent 2 }}
```

### Type mismatch (expected string, got int)
Convert types explicitly.

```yaml
# String to int
replicas: {{ .Values.count | int }}

# Int to string
annotation: {{ .Values.port | toString }}

# Quote strings in YAML context
value: {{ .Values.name | quote }}
```

### Extra whitespace/blank lines
Use `{{-` and `-}}` to trim whitespace.

```yaml
# Bad - leaves blank lines
{{ if .Values.enabled }}
key: value
{{ end }}

# Good - trims whitespace
{{- if .Values.enabled }}
key: value
{{- end }}
```

## Our Helper Conventions

We use generic `chart.*` naming (not chart-name-specific):

```yaml
# Standard helpers
{{ include "chart.name" . }}
{{ include "chart.fullname" . }}
{{ include "chart.labels" . | nindent 4 }}
{{ include "chart.selectorLabels" . | nindent 6 }}
{{ include "chart.serviceAccountName" . }}

# For ConfigMaps/Secrets (lighter labels)
{{ include "chart.labelsConfigmapSecret" . | nindent 4 }}
```

## Template value rendering

For values that contain template expressions (like affinity):

```yaml
# In _tplvalues.tpl
{{- define "chart.tplvalues.render" -}}
    {{- if typeIs "string" .value }}
        {{- tpl .value .context }}
    {{- else }}
        {{- tpl (.value | toYaml) .context }}
    {{- end }}
{{- end -}}

# Usage in templates
{{- if .Values.affinity }}
affinity:
  {{- tpl .Values.affinity . | nindent 8 }}
{{- end }}
```
