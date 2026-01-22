---
description: "Activate when user is working with values.yaml, asking about values structure, defaults, overrides, or how to organize Helm values effectively"
---

# Helm Values Best Practices Expert

You are an expert in designing and organizing Helm values.yaml files. When this skill is activated, provide guidance on values structure, typing, documentation, and best practices.

## Core Principles

1. **Sensible Defaults** - Chart should work with minimal configuration
2. **Clear Structure** - Organized, predictable hierarchy
3. **Type Safety** - Use appropriate YAML types, document expected types
4. **Feature Flags** - Use `.enabled` pattern for optional components
5. **Environment Agnostic** - No hardcoded environment-specific values

## Standard Values Structure

```yaml
# values.yaml - Recommended structure

# =============================================================================
# GLOBAL VALUES
# =============================================================================
global:
  # Values shared across all subcharts
  imageRegistry: ""
  imagePullSecrets: []
  storageClass: ""

# =============================================================================
# COMMON METADATA
# =============================================================================
nameOverride: ""
fullnameOverride: ""

# =============================================================================
# IMAGE CONFIGURATION
# =============================================================================
image:
  repository: nginx
  # Use specific version, never 'latest' in defaults
  tag: ""  # Defaults to chart appVersion
  pullPolicy: IfNotPresent
  pullSecrets: []

# =============================================================================
# REPLICAS & SCALING
# =============================================================================
replicaCount: 1

autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
  targetMemoryUtilizationPercentage: 80

# =============================================================================
# SERVICE CONFIGURATION
# =============================================================================
service:
  type: ClusterIP
  port: 80
  # nodePort: 30000  # Only when type is NodePort
  annotations: {}

# =============================================================================
# INGRESS CONFIGURATION
# =============================================================================
ingress:
  enabled: false
  className: ""
  annotations: {}
    # kubernetes.io/ingress.class: nginx
    # cert-manager.io/cluster-issuer: letsencrypt
  hosts:
    - host: chart-example.local
      paths:
        - path: /
          pathType: ImplementationSpecific
  tls: []
  #  - secretName: chart-example-tls
  #    hosts:
  #      - chart-example.local

# =============================================================================
# RESOURCE LIMITS
# =============================================================================
resources:
  # We recommend setting resources for production
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 128Mi

# =============================================================================
# PROBES
# =============================================================================
livenessProbe:
  httpGet:
    path: /healthz
    port: http
  initialDelaySeconds: 10
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /ready
    port: http
  initialDelaySeconds: 5
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 3

# =============================================================================
# SECURITY CONTEXT
# =============================================================================
podSecurityContext:
  fsGroup: 1000
  runAsNonRoot: true
  runAsUser: 1000

securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 1000

# =============================================================================
# SERVICE ACCOUNT
# =============================================================================
serviceAccount:
  create: true
  annotations: {}
  name: ""
  automountServiceAccountToken: false

# =============================================================================
# SCHEDULING
# =============================================================================
nodeSelector: {}

tolerations: []

affinity: {}

topologySpreadConstraints: []

# =============================================================================
# POD CONFIGURATION
# =============================================================================
podAnnotations: {}

podLabels: {}

# =============================================================================
# ADDITIONAL CONFIGURATION
# =============================================================================
extraEnv: []
  # - name: ENV_VAR
  #   value: "value"

extraEnvFrom: []
  # - configMapRef:
  #     name: my-configmap

extraVolumes: []

extraVolumeMounts: []

# =============================================================================
# APPLICATION CONFIGURATION
# =============================================================================
config: {}
  # Application-specific configuration

# =============================================================================
# OPTIONAL COMPONENTS
# =============================================================================
metrics:
  enabled: false
  serviceMonitor:
    enabled: false
    interval: 30s
    scrapeTimeout: 10s

# =============================================================================
# DEPENDENCIES
# =============================================================================
postgresql:
  enabled: false
  auth:
    username: app
    password: ""
    database: app

redis:
  enabled: false
  architecture: standalone
```

## Values Documentation Patterns

### Inline Comments (Preferred)
```yaml
# -- Number of pod replicas
# @default -- 1
replicaCount: 1

# -- Image pull policy
# @default -- IfNotPresent
# @options -- Always, IfNotPresent, Never
pullPolicy: IfNotPresent

# -- Enable ingress controller resource
# @default -- false
# @section -- Ingress
enabled: false
```

### Block Comments for Complex Values
```yaml
# Resource limits and requests for the container.
# See: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
#
# Example:
#   resources:
#     limits:
#       cpu: 100m
#       memory: 128Mi
#     requests:
#       cpu: 100m
#       memory: 128Mi
resources: {}
```

## Feature Flags Pattern

```yaml
# =============================================================================
# FEATURE FLAGS - Use consistent .enabled pattern
# =============================================================================

# Good: Consistent enabled pattern
metrics:
  enabled: false
  port: 9090

ingress:
  enabled: false
  hosts: []

persistence:
  enabled: false
  size: 10Gi

# Template usage:
# {{- if .Values.metrics.enabled }}
# ... metrics resources ...
# {{- end }}
```

## Environment Override Strategy

### Base values.yaml
```yaml
# Production-safe defaults
replicaCount: 2
resources:
  limits:
    cpu: 500m
    memory: 512Mi
```

### values-dev.yaml
```yaml
# Development overrides
replicaCount: 1
resources:
  limits:
    cpu: 100m
    memory: 128Mi

# Enable debugging
extraEnv:
  - name: DEBUG
    value: "true"
```

### values-prod.yaml
```yaml
# Production overrides
replicaCount: 3
resources:
  limits:
    cpu: 1000m
    memory: 1Gi

# Production-specific
ingress:
  enabled: true
  hosts:
    - host: app.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: app-tls
      hosts:
        - app.example.com
```

## Values Schema (values.schema.json)

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "replicaCount": {
      "type": "integer",
      "minimum": 1,
      "default": 1,
      "description": "Number of replicas"
    },
    "image": {
      "type": "object",
      "properties": {
        "repository": {
          "type": "string",
          "description": "Image repository"
        },
        "tag": {
          "type": "string",
          "description": "Image tag (defaults to appVersion)"
        },
        "pullPolicy": {
          "type": "string",
          "enum": ["Always", "IfNotPresent", "Never"],
          "default": "IfNotPresent"
        }
      },
      "required": ["repository"]
    },
    "service": {
      "type": "object",
      "properties": {
        "type": {
          "type": "string",
          "enum": ["ClusterIP", "NodePort", "LoadBalancer"],
          "default": "ClusterIP"
        },
        "port": {
          "type": "integer",
          "minimum": 1,
          "maximum": 65535,
          "default": 80
        }
      }
    }
  },
  "required": ["image"]
}
```

## Anti-Patterns to Avoid

### Don't Do This
```yaml
# BAD: Environment-specific defaults
database_host: "prod-db.example.com"  # Should be empty or localhost

# BAD: Hardcoded secrets
password: "supersecret123"  # Never!

# BAD: Inconsistent structure
metricsEnabled: true  # Should be metrics.enabled

# BAD: Nested without parent
# This will cause nil pointer errors
deeplyNested:
  # value:  # Missing intermediate level
  #   setting: true

# BAD: Mixed types in lists
items:
  - "string"
  - 123
  - enabled: true

# BAD: Overly complex nesting (>4 levels)
a:
  b:
    c:
      d:
        e:
          value: "too deep!"
```

### Do This Instead
```yaml
# GOOD: Environment-agnostic defaults
database:
  host: ""  # Must be set per environment
  port: 5432

# GOOD: Reference to external secret
existingSecret: ""  # Name of existing secret

# GOOD: Consistent structure
metrics:
  enabled: true
  port: 9090

# GOOD: Flat where possible
configMapName: ""
secretName: ""
```

## Subchart Values

```yaml
# Configure subcharts via their name
postgresql:
  enabled: true
  auth:
    username: myapp
    database: myapp
    existingSecret: myapp-postgresql

# If using alias in Chart.yaml (alias: db)
db:
  enabled: true
  # ...

# Global values for all subcharts
global:
  postgresql:
    auth:
      username: shared-user
```

## When Helping Users

1. **Start with structure** - Establish clear hierarchy first
2. **Use sensible defaults** - Chart should work out-of-box
3. **Document everything** - Future users (including yourself) will thank you
4. **Keep it flat** - Avoid deep nesting where possible
5. **Be consistent** - Same patterns throughout
6. **Type safety** - Use schema validation
7. **Security first** - Never commit secrets, use references
