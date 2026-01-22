# Security Scan Helm Chart

Analyze Helm chart templates for Kubernetes security best practices and common vulnerabilities.

## Arguments
- `$ARGUMENTS`: Optional - path to chart directory (default: current directory)

## Execution Steps

### Phase 1: Chart Discovery

```bash
CHART_PATH="${ARGUMENTS:-.}"

echo "═══════════════════════════════════════════════════════════"
echo "HELM SECURITY SCANNER"
echo "═══════════════════════════════════════════════════════════"

# Find Chart.yaml
if [ ! -f "$CHART_PATH/Chart.yaml" ]; then
    CHART_PATH=$(find . -name "Chart.yaml" -type f -exec dirname {} \; | head -1)
fi

if [ -z "$CHART_PATH" ] || [ ! -f "$CHART_PATH/Chart.yaml" ]; then
    echo "❌ ERROR: No Chart.yaml found"
    exit 1
fi

echo "📦 Scanning: $CHART_PATH"
grep -E "^name:|^version:" "$CHART_PATH/Chart.yaml" | sed 's/^/   /'

# Render templates for analysis
echo ""
echo "🔄 Rendering templates for security analysis..."
RENDERED=$(helm template security-scan "$CHART_PATH" 2>/dev/null)
if [ -z "$RENDERED" ]; then
    echo "⚠️  Warning: Could not render templates, analyzing raw files"
fi
```

### Phase 2: Pod Security Standards Check

```bash
CHART_PATH="${ARGUMENTS:-.}"
TEMPLATES_DIR="$CHART_PATH/templates"

echo ""
echo "=== Pod Security Standards ==="

# Check for runAsNonRoot
echo ""
echo "🔐 runAsNonRoot:"
if grep -rq "runAsNonRoot: true" "$TEMPLATES_DIR" 2>/dev/null; then
    echo "   ✓ runAsNonRoot: true found"
    grep -rn "runAsNonRoot:" "$TEMPLATES_DIR" 2>/dev/null | head -5 | sed 's/^/   /'
elif grep -rq "runAsNonRoot" "$CHART_PATH/values.yaml" 2>/dev/null; then
    echo "   ○ runAsNonRoot configurable via values"
else
    echo "   ❌ runAsNonRoot not set (containers may run as root)"
fi

# Check for readOnlyRootFilesystem
echo ""
echo "🔐 readOnlyRootFilesystem:"
if grep -rq "readOnlyRootFilesystem: true" "$TEMPLATES_DIR" 2>/dev/null; then
    echo "   ✓ readOnlyRootFilesystem: true found"
else
    echo "   ⚠️  readOnlyRootFilesystem not enforced"
fi

# Check for allowPrivilegeEscalation
echo ""
echo "🔐 allowPrivilegeEscalation:"
if grep -rq "allowPrivilegeEscalation: false" "$TEMPLATES_DIR" 2>/dev/null; then
    echo "   ✓ allowPrivilegeEscalation: false found"
else
    echo "   ⚠️  allowPrivilegeEscalation not explicitly disabled"
fi

# Check for privileged containers
echo ""
echo "🔐 Privileged mode:"
if grep -rq "privileged: true" "$TEMPLATES_DIR" 2>/dev/null; then
    echo "   ❌ CRITICAL: privileged: true found!"
    grep -rn "privileged: true" "$TEMPLATES_DIR" 2>/dev/null | sed 's/^/   /'
else
    echo "   ✓ No privileged containers"
fi

# Check for capabilities
echo ""
echo "🔐 Capabilities:"
if grep -rq "drop:" "$TEMPLATES_DIR" 2>/dev/null && grep -rq "ALL" "$TEMPLATES_DIR" 2>/dev/null; then
    echo "   ✓ Capabilities dropped"
else
    echo "   ⚠️  Consider dropping ALL capabilities and adding only required ones"
fi
```

### Phase 3: Resource Security

```bash
CHART_PATH="${ARGUMENTS:-.}"
TEMPLATES_DIR="$CHART_PATH/templates"

echo ""
echo "=== Resource Security ==="

# Check for resource limits
echo ""
echo "💾 Resource Limits:"
if grep -rq "resources:" "$TEMPLATES_DIR" 2>/dev/null; then
    if grep -rq "limits:" "$TEMPLATES_DIR" 2>/dev/null; then
        echo "   ✓ Resource limits defined"
    else
        echo "   ⚠️  resources defined but no limits"
    fi
    if grep -rq "requests:" "$TEMPLATES_DIR" 2>/dev/null; then
        echo "   ✓ Resource requests defined"
    else
        echo "   ⚠️  resources defined but no requests"
    fi
else
    echo "   ❌ No resource limits (DoS risk)"
fi

# Check for hostNetwork
echo ""
echo "🌐 Host Network:"
if grep -rq "hostNetwork: true" "$TEMPLATES_DIR" 2>/dev/null; then
    echo "   ⚠️  hostNetwork: true found (security risk)"
    grep -rn "hostNetwork: true" "$TEMPLATES_DIR" 2>/dev/null | sed 's/^/   /'
else
    echo "   ✓ hostNetwork not used"
fi

# Check for hostPID/hostIPC
echo ""
echo "🔗 Host PID/IPC:"
if grep -rqE "hostPID: true|hostIPC: true" "$TEMPLATES_DIR" 2>/dev/null; then
    echo "   ⚠️  hostPID or hostIPC enabled (security risk)"
else
    echo "   ✓ hostPID/hostIPC not used"
fi

# Check for hostPath volumes
echo ""
echo "📁 Host Path Volumes:"
if grep -rq "hostPath:" "$TEMPLATES_DIR" 2>/dev/null; then
    echo "   ⚠️  hostPath volumes found (review carefully)"
    grep -rn "hostPath:" "$TEMPLATES_DIR" 2>/dev/null | head -5 | sed 's/^/   /'
else
    echo "   ✓ No hostPath volumes"
fi
```

### Phase 4: RBAC & Service Account Check

```bash
CHART_PATH="${ARGUMENTS:-.}"
TEMPLATES_DIR="$CHART_PATH/templates"

echo ""
echo "=== RBAC & Service Accounts ==="

# Check for ServiceAccount creation
echo ""
echo "👤 ServiceAccount:"
if ls "$TEMPLATES_DIR"/serviceaccount* 2>/dev/null | head -1 > /dev/null; then
    echo "   ✓ ServiceAccount template exists"

    # Check if automountServiceAccountToken is disabled
    if grep -rq "automountServiceAccountToken: false" "$TEMPLATES_DIR" 2>/dev/null; then
        echo "   ✓ automountServiceAccountToken: false"
    else
        echo "   ⚠️  Consider setting automountServiceAccountToken: false"
    fi
else
    echo "   ○ No dedicated ServiceAccount (using default)"
fi

# Check for RBAC resources
echo ""
echo "🔑 RBAC:"
RBAC_FILES=$(ls "$TEMPLATES_DIR"/*role* "$TEMPLATES_DIR"/*rolebinding* 2>/dev/null)
if [ -n "$RBAC_FILES" ]; then
    echo "   ✓ RBAC resources defined"

    # Check for cluster-wide permissions
    if grep -rq "ClusterRole" "$TEMPLATES_DIR" 2>/dev/null; then
        echo "   ⚠️  ClusterRole found (review scope carefully)"

        # Check for dangerous permissions
        if grep -rqE '"*"\s*#|"\*"' "$TEMPLATES_DIR" 2>/dev/null; then
            echo "   ❌ CRITICAL: Wildcard (*) permissions found!"
        fi
    fi

    # List verbs used
    echo "   📋 Verbs used:"
    grep -roh "verbs:.*" "$TEMPLATES_DIR" 2>/dev/null | head -5 | sed 's/^/      /'
else
    echo "   ○ No RBAC resources"
fi
```

### Phase 5: Network Security

```bash
CHART_PATH="${ARGUMENTS:-.}"
TEMPLATES_DIR="$CHART_PATH/templates"

echo ""
echo "=== Network Security ==="

# Check for NetworkPolicy
echo ""
echo "🌐 NetworkPolicy:"
if ls "$TEMPLATES_DIR"/networkpolicy* 2>/dev/null | head -1 > /dev/null; then
    echo "   ✓ NetworkPolicy template exists"
else
    echo "   ⚠️  No NetworkPolicy (consider adding for network segmentation)"
fi

# Check for Ingress TLS
echo ""
echo "🔒 Ingress TLS:"
if grep -rq "tls:" "$TEMPLATES_DIR" 2>/dev/null; then
    echo "   ✓ TLS configuration found"
else
    if grep -rq "Ingress" "$TEMPLATES_DIR" 2>/dev/null; then
        echo "   ⚠️  Ingress without TLS configuration"
    else
        echo "   ○ No Ingress resources"
    fi
fi

# Check for service exposure
echo ""
echo "📡 Service Types:"
grep -rh "type:" "$TEMPLATES_DIR"/*service* 2>/dev/null | while read line; do
    if echo "$line" | grep -q "LoadBalancer"; then
        echo "   ⚠️  LoadBalancer service (publicly exposed)"
    elif echo "$line" | grep -q "NodePort"; then
        echo "   ⚠️  NodePort service (exposed on all nodes)"
    elif echo "$line" | grep -q "ClusterIP"; then
        echo "   ✓ ClusterIP service (internal only)"
    fi
done
```

### Phase 6: Secrets & Sensitive Data

```bash
CHART_PATH="${ARGUMENTS:-.}"
TEMPLATES_DIR="$CHART_PATH/templates"

echo ""
echo "=== Secrets & Sensitive Data ==="

# Check for hardcoded secrets
echo ""
echo "🔑 Hardcoded Secrets Check:"
PATTERNS="password|secret|api[_-]?key|token|credential|private[_-]?key"
if grep -riE "$PATTERNS" "$TEMPLATES_DIR" 2>/dev/null | grep -v ".Values" | grep -v "secretKeyRef" | head -5; then
    echo "   ⚠️  Potential hardcoded secrets found above"
else
    echo "   ✓ No obvious hardcoded secrets"
fi

# Check for external secrets
echo ""
echo "🔐 Secret Management:"
if grep -rq "external-secrets\|sealed-secrets\|vault" "$TEMPLATES_DIR" 2>/dev/null; then
    echo "   ✓ External secret management detected"
else
    if ls "$TEMPLATES_DIR"/secret* 2>/dev/null | head -1 > /dev/null; then
        echo "   ○ Standard K8s Secrets (consider external secret management)"
    fi
fi

# Check values.yaml for sensitive defaults
echo ""
echo "📄 Values.yaml Sensitive Defaults:"
if grep -iE "password:|secret:|apiKey:|token:" "$CHART_PATH/values.yaml" 2>/dev/null | grep -v '""' | grep -v "null" | head -5; then
    echo "   ⚠️  Sensitive values with defaults found"
else
    echo "   ✓ No sensitive defaults in values.yaml"
fi
```

### Phase 7: Image Security

```bash
CHART_PATH="${ARGUMENTS:-.}"
TEMPLATES_DIR="$CHART_PATH/templates"

echo ""
echo "=== Image Security ==="

# Check for latest tag
echo ""
echo "🐳 Image Tags:"
if grep -rqE 'tag:.*latest|:latest' "$TEMPLATES_DIR" "$CHART_PATH/values.yaml" 2>/dev/null; then
    echo "   ⚠️  'latest' tag found (not recommended for production)"
else
    echo "   ✓ No 'latest' tags"
fi

# Check for image pull policy
echo ""
echo "📥 Image Pull Policy:"
if grep -rq "imagePullPolicy: Always" "$TEMPLATES_DIR" 2>/dev/null; then
    echo "   ✓ imagePullPolicy: Always found"
elif grep -rq "imagePullPolicy:" "$TEMPLATES_DIR" 2>/dev/null; then
    grep -rh "imagePullPolicy:" "$TEMPLATES_DIR" 2>/dev/null | head -3 | sed 's/^/   /'
else
    echo "   ○ imagePullPolicy not set (defaults to IfNotPresent)"
fi

# Check for private registry
echo ""
echo "🔐 Private Registry:"
if grep -rq "imagePullSecrets" "$TEMPLATES_DIR" 2>/dev/null; then
    echo "   ✓ imagePullSecrets configured"
else
    echo "   ○ No imagePullSecrets (using public images or node credentials)"
fi
```

### Phase 8: Generate Security Report

```
═══════════════════════════════════════════════════════════
SECURITY SCAN REPORT
═══════════════════════════════════════════════════════════

Chart: [name] v[version]
Scan Date: [date]

Overall Security Score: [X/10]

Critical Issues: [count]
High Issues: [count]
Medium Issues: [count]
Low Issues: [count]

═══════════════════════════════════════════════════════════
POD SECURITY
═══════════════════════════════════════════════════════════
| Check | Status | Severity |
|-------|--------|----------|
| runAsNonRoot | [✓/❌] | High |
| readOnlyRootFilesystem | [✓/⚠️] | Medium |
| allowPrivilegeEscalation | [✓/⚠️] | High |
| privileged | [✓/❌] | Critical |
| capabilities dropped | [✓/⚠️] | Medium |

═══════════════════════════════════════════════════════════
RESOURCE SECURITY
═══════════════════════════════════════════════════════════
| Check | Status | Severity |
|-------|--------|----------|
| Resource limits | [✓/❌] | Medium |
| hostNetwork | [✓/⚠️] | High |
| hostPID/hostIPC | [✓/⚠️] | High |
| hostPath volumes | [✓/⚠️] | Medium |

═══════════════════════════════════════════════════════════
RBAC & IDENTITY
═══════════════════════════════════════════════════════════
| Check | Status | Severity |
|-------|--------|----------|
| ServiceAccount | [✓/○] | Low |
| automountServiceAccountToken | [✓/⚠️] | Medium |
| RBAC scope | [✓/⚠️] | High |

═══════════════════════════════════════════════════════════
NETWORK SECURITY
═══════════════════════════════════════════════════════════
| Check | Status | Severity |
|-------|--------|----------|
| NetworkPolicy | [✓/⚠️] | Medium |
| Ingress TLS | [✓/⚠️] | High |
| Service exposure | [✓/⚠️] | Medium |

═══════════════════════════════════════════════════════════
SECRETS
═══════════════════════════════════════════════════════════
| Check | Status | Severity |
|-------|--------|----------|
| Hardcoded secrets | [✓/❌] | Critical |
| External secrets | [✓/○] | Low |
| Sensitive defaults | [✓/⚠️] | High |

═══════════════════════════════════════════════════════════
IMAGES
═══════════════════════════════════════════════════════════
| Check | Status | Severity |
|-------|--------|----------|
| No 'latest' tag | [✓/⚠️] | Medium |
| Pull policy | [✓/○] | Low |
| Private registry | [✓/○] | Low |

═══════════════════════════════════════════════════════════
RECOMMENDATIONS
═══════════════════════════════════════════════════════════

Critical (fix immediately):
  1. [Critical issue and fix]

High Priority:
  1. [High priority fix]
  2. [High priority fix]

Medium Priority:
  1. [Medium priority improvement]

Best Practices:
  1. Add NetworkPolicy for network segmentation
  2. Use external secrets management (Vault, External Secrets)
  3. Pin image versions, never use 'latest'
  4. Set resource limits on all containers

═══════════════════════════════════════════════════════════
COMPLIANCE
═══════════════════════════════════════════════════════════
Pod Security Standards:
  Privileged: [PASS/FAIL]
  Baseline: [PASS/FAIL]
  Restricted: [PASS/FAIL]

Next Steps:
  - Fix critical issues before deployment
  - Run /validate-chart after security fixes
  - Consider using policy enforcement (OPA Gatekeeper, Kyverno)
═══════════════════════════════════════════════════════════
```
