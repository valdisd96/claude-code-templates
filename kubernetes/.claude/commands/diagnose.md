# Diagnose Kubernetes Cluster

Analyze cluster health and identify common issues.

## Arguments
- `$ARGUMENTS`: Optional - specific namespace or "all" for cluster-wide

## Execution Steps

### Phase 1: Cluster Overview

```bash
# Cluster info
kubectl cluster-info
kubectl version --short

# Node health
kubectl get nodes -o wide
kubectl top nodes 2>/dev/null || echo "Metrics server not available"

# Namespace overview
kubectl get namespaces
```

### Phase 2: Resource Health Check

```bash
# Unhealthy pods across cluster
kubectl get pods --all-namespaces --field-selector=status.phase!=Running,status.phase!=Succeeded | head -50

# Pods with restart counts
kubectl get pods --all-namespaces -o jsonpath='{range .items[?(@.status.containerStatuses[0].restartCount>3)]}{.metadata.namespace}{"\t"}{.metadata.name}{"\t"}{.status.containerStatuses[0].restartCount}{"\n"}{end}'

# Pending PVCs
kubectl get pvc --all-namespaces | grep -v Bound

# Recent events (warnings/errors)
kubectl get events --all-namespaces --sort-by='.lastTimestamp' --field-selector type!=Normal | tail -20
```

### Phase 3: Resource Utilization

```bash
# Resource quotas
kubectl get resourcequotas --all-namespaces

# Limit ranges
kubectl get limitranges --all-namespaces

# Pod resource requests vs limits
kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\t"}{.spec.containers[0].resources.requests.memory}{"\t"}{.spec.containers[0].resources.limits.memory}{"\n"}{end}' | head -30
```

### Phase 4: Generate Report

```
═══════════════════════════════════════════════════════════
KUBERNETES CLUSTER DIAGNOSIS
═══════════════════════════════════════════════════════════

Cluster Status:
  Nodes: [count] ([healthy]/[unhealthy])
  Namespaces: [count]

Health Summary:
  ✓/✗ All nodes Ready
  ✓/✗ No pods in CrashLoopBackOff
  ✓/✗ No pending PVCs
  ✓/✗ No recent warning events

Issues Found:
  - [Issue 1]: [description]
  - [Issue 2]: [description]

Recommendations:
  1. [Action item based on findings]
  2. [Action item based on findings]

Next Steps:
  - Run /troubleshoot [resource] for specific issues
  - Run /security-audit for security review
═══════════════════════════════════════════════════════════
```
