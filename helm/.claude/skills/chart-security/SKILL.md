---
description: "Activate when user asks about Kubernetes security, Pod Security Standards, RBAC, NetworkPolicy, or security best practices for Helm charts"
---

# Helm Chart Security

Help with security configuration when explicitly asked. Don't lecture - just help configure what's needed.

## Our Default Security Context

We use minimal security by default (allows most workloads to run without issues):

```yaml
# In values.yaml
podSecurityContext: {}

securityContext:
  privileged: false
  allowPrivilegeEscalation: false
  capabilities:
    drop: ["ALL"]

automountServiceAccountToken: true

serviceAccount:
  create: false
```

## When Stricter Security Is Needed

If deploying to a namespace with Pod Security Standards enforced, use:

```yaml
# Restricted PSS compliant
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
  seccompProfile:
    type: RuntimeDefault

securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop: ["ALL"]
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 1000

automountServiceAccountToken: false

serviceAccount:
  create: true
  automountServiceAccountToken: false
```

## Common Security Tradeoffs

| Setting | Strict Value | Why You Might Relax It |
|---------|--------------|------------------------|
| `runAsNonRoot: true` | Required | App writes to paths requiring root |
| `readOnlyRootFilesystem: true` | Required | App needs to write temp files |
| `automountServiceAccountToken: false` | Required | App needs K8s API access |
| `capabilities.drop: ALL` | Required | App needs specific caps (NET_BIND_SERVICE) |

## Adding Capabilities Back

If your app needs specific capabilities:

```yaml
securityContext:
  capabilities:
    drop: ["ALL"]
    add: ["NET_BIND_SERVICE"]  # Bind to ports < 1024
```

## Writable Directories with readOnlyRootFilesystem

If you need `readOnlyRootFilesystem: true` but app needs to write:

```yaml
# In deployment
volumes:
  - name: tmp
    emptyDir: {}
  - name: cache
    emptyDir: {}

volumeMounts:
  - name: tmp
    mountPath: /tmp
  - name: cache
    mountPath: /var/cache
```

## Service Account Token

```yaml
# Disable if app doesn't need K8s API access (most apps)
automountServiceAccountToken: false

# Enable if app needs to call K8s API
automountServiceAccountToken: true
```

## Quick Security Check

Before deploying, verify:

1. **No privileged containers** - `privileged: false`
2. **No privilege escalation** - `allowPrivilegeEscalation: false`
3. **Capabilities dropped** - `drop: ["ALL"]`
4. **No hardcoded secrets** - use ExternalSecrets or existingSecret references
