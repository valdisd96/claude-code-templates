---
description: "Activate when user is working with values.yaml, asking about values structure, defaults, overrides, or how to organize Helm values effectively"
---

# Helm Values Patterns

Help users structure values.yaml correctly. Focus on our actual patterns, not generic best practices.

## Our Standard Structure

```yaml
# Image - split into repository + name + tag
image:
  repository: "registry.example.com/container-registry"
  name: myapp
  tag: ""
  pullPolicy: Always

# Overrides
nameOverride: ""
fullnameOverride: ""

# Pull secrets (list of secret names)
imagePullSecrets:
  - harbor-pull-secret

# Deployment strategy
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 0
    maxUnavailable: 1

# Scheduling
nodeSelector: {}
tolerations: []

# Affinity as template string (rendered with tpl)
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

# Security (minimal by default)
podSecurityContext: {}
securityContext:
  privileged: false
  allowPrivilegeEscalation: false
  capabilities:
    drop: ["ALL"]

automountServiceAccountToken: true

# Service Account
serviceAccount:
  create: false
  annotations: {}
  name: ""

# Service
service:
  type: ClusterIP
  port: 80
  annotations: {}

# Ports configuration
ports:
  containerPort: 8080
  nameContainerPort: http
  healthCheckPort: 8082
  nameHealthCheckPort: healthcheck

# Feature flags - always use .enabled pattern
ingress:
  enabled: false
  configurations:
    - className: "nginx"
      hosts:
        - host: ""
          paths:
            - path: "/"

datadog:
  enabled: false
  javaLibVersion: "v1.54.0"
  env: "dev"
  service: "myapp"

# Extra environment variables
extraEnvs: []

# Annotations and labels
annotations: {}
podLabels: {}

# Monitoring label
moniringEnable: "false"
```

## Feature Flags Pattern

Always use `.enabled` for optional features:

```yaml
# In values.yaml
ingress:
  enabled: false
  # other ingress config...

datadog:
  enabled: false
  # other datadog config...

externalSecrets:
  enabled: false
  # other config...

# In templates
{{- if .Values.ingress.enabled }}
# ingress resources
{{- end }}

{{- if .Values.datadog.enabled }}
# datadog annotations
{{- end }}
```

## Template-Rendered Values

For complex values that need access to chart context (like affinity):

```yaml
# In values.yaml - use multiline string with templates
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

# In deployment.yaml - render with tpl
{{- if .Values.affinity }}
affinity:
  {{- tpl .Values.affinity . | nindent 8 }}
{{- end }}
```

## Environment-Specific Values

Structure for multiple environments:

```
chart/
├── values.yaml              # Base defaults
├── values-envtype/
│   └── values-common.yaml   # Shared overrides
└── secrets-helm/
    └── secrets.common.notprod.yaml
```

Deploy with:
```bash
helm upgrade release ./chart \
  -f values-envtype/values-common.yaml \
  -f secrets-helm/secrets.common.notprod.yaml
```

## Database Configuration Pattern

For apps with database dependencies:

```yaml
database:
  main:
    dbDev: "false"           # Use dev cluster
    user: ""                 # Auto-generated if empty
    name: ""                 # Auto-generated if empty
    adminSecretsVersion: ""  # External secrets version
  clickhouse:
    dbDev: "false"
    user: ""
    name: ""
```

## Optional Blocks Pattern

Use `{{- with }}` for optional configuration blocks:

```yaml
# In templates
{{- with .Values.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 8 }}
{{- end }}

{{- with .Values.tolerations }}
tolerations:
  {{- toYaml . | nindent 8 }}
{{- end }}

{{- with .Values.resources }}
resources:
  {{- toYaml . | nindent 12 }}
{{- end }}
```

This pattern:
- Skips the block entirely if value is empty/nil
- No need for explicit `if` checks
- Cleaner than `{{- if .Values.X }}`

## Anti-Patterns

```yaml
# Bad - hardcoded environment values
database_host: "prod-db.example.com"  # Should be empty or set per-env

# Bad - secrets in values
password: "supersecret"  # Use external secrets instead

# Bad - inconsistent structure
metricsEnabled: true    # Should be metrics.enabled

# Bad - using 'latest' tag
image:
  tag: latest           # Pin specific versions
```
