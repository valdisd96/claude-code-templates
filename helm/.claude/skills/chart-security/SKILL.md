---
description: "Activate when user asks about Kubernetes security, Pod Security Standards, RBAC, NetworkPolicy, or security best practices for Helm charts"
---

# Helm Chart Security Expert

You are an expert in Kubernetes security best practices for Helm charts. When this skill is activated, provide guidance on securing Helm charts following industry standards and Pod Security Standards.

## Pod Security Standards (PSS)

Kubernetes defines three Pod Security Standards levels:

### Privileged (Unrestricted)
- No restrictions
- Should only be used for system-level workloads

### Baseline (Minimally Restrictive)
- Prevents known privilege escalations
- Allows most workloads

### Restricted (Heavily Restrictive)
- Current best practices for hardening
- May require application changes

## Security Context Templates

### Restricted Security Context (Recommended)
```yaml
# values.yaml
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
    drop:
      - ALL
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 1000

# deployment.yaml
spec:
  template:
    spec:
      securityContext:
        {{- toYaml .Values.podSecurityContext | nindent 8 }}
      containers:
        - name: {{ .Chart.Name }}
          securityContext:
            {{- toYaml .Values.securityContext | nindent 12 }}
```

### Baseline Security Context
```yaml
podSecurityContext:
  runAsNonRoot: true
  seccompProfile:
    type: RuntimeDefault

securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
```

## ServiceAccount Best Practices

```yaml
# values.yaml
serviceAccount:
  create: true
  annotations: {}
  name: ""
  automountServiceAccountToken: false  # Important!

# serviceaccount.yaml
{{- if .Values.serviceAccount.create -}}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "mychart.serviceAccountName" . }}
  labels:
    {{- include "mychart.labels" . | nindent 4 }}
  {{- with .Values.serviceAccount.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
automountServiceAccountToken: {{ .Values.serviceAccount.automountServiceAccountToken }}
{{- end }}

# In deployment - only mount if needed
spec:
  template:
    spec:
      serviceAccountName: {{ include "mychart.serviceAccountName" . }}
      automountServiceAccountToken: {{ .Values.serviceAccount.automountServiceAccountToken }}
```

## RBAC Templates

### Minimal Role (Least Privilege)
```yaml
# role.yaml
{{- if .Values.rbac.create -}}
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ include "mychart.fullname" . }}
  labels:
    {{- include "mychart.labels" . | nindent 4 }}
rules:
  # Only grant what's absolutely necessary
  - apiGroups: [""]
    resources: ["configmaps"]
    resourceNames: ["{{ include "mychart.fullname" . }}-config"]
    verbs: ["get"]
  - apiGroups: [""]
    resources: ["secrets"]
    resourceNames: ["{{ include "mychart.fullname" . }}-secret"]
    verbs: ["get"]
{{- end }}
```

### RoleBinding
```yaml
# rolebinding.yaml
{{- if .Values.rbac.create -}}
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ include "mychart.fullname" . }}
  labels:
    {{- include "mychart.labels" . | nindent 4 }}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: {{ include "mychart.fullname" . }}
subjects:
  - kind: ServiceAccount
    name: {{ include "mychart.serviceAccountName" . }}
    namespace: {{ .Release.Namespace }}
{{- end }}
```

### RBAC Anti-Patterns
```yaml
# NEVER DO THIS
rules:
  - apiGroups: ["*"]       # Never use wildcards
    resources: ["*"]        # Never use wildcards
    verbs: ["*"]            # Never use wildcards

# AVOID - Too broad
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get", "list", "watch"]  # Can read ALL secrets

# BETTER - Specific resources
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    resourceNames: ["my-specific-secret"]
    verbs: ["get"]
```

## NetworkPolicy Templates

### Default Deny All
```yaml
# networkpolicy.yaml
{{- if .Values.networkPolicy.enabled -}}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ include "mychart.fullname" . }}-default-deny
  labels:
    {{- include "mychart.labels" . | nindent 4 }}
spec:
  podSelector:
    matchLabels:
      {{- include "mychart.selectorLabels" . | nindent 6 }}
  policyTypes:
    - Ingress
    - Egress
{{- end }}
```

### Allow Specific Traffic
```yaml
# networkpolicy.yaml
{{- if .Values.networkPolicy.enabled -}}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ include "mychart.fullname" . }}
  labels:
    {{- include "mychart.labels" . | nindent 4 }}
spec:
  podSelector:
    matchLabels:
      {{- include "mychart.selectorLabels" . | nindent 6 }}
  policyTypes:
    - Ingress
    - Egress
  ingress:
    # Allow from ingress controller
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: ingress-nginx
          podSelector:
            matchLabels:
              app.kubernetes.io/name: ingress-nginx
      ports:
        - protocol: TCP
          port: {{ .Values.service.port }}
    # Allow from same namespace
    - from:
        - podSelector: {}
      ports:
        - protocol: TCP
          port: {{ .Values.service.port }}
  egress:
    # Allow DNS
    - to:
        - namespaceSelector: {}
          podSelector:
            matchLabels:
              k8s-app: kube-dns
      ports:
        - protocol: UDP
          port: 53
    # Allow to database
    {{- if .Values.postgresql.enabled }}
    - to:
        - podSelector:
            matchLabels:
              app.kubernetes.io/name: postgresql
      ports:
        - protocol: TCP
          port: 5432
    {{- end }}
{{- end }}
```

## Secrets Management

### External Secrets Reference
```yaml
# values.yaml
existingSecret: ""  # Use existing secret instead of creating one

# secret.yaml
{{- if not .Values.existingSecret }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "mychart.fullname" . }}
  labels:
    {{- include "mychart.labels" . | nindent 4 }}
type: Opaque
data:
  # Reference values, never hardcode
  password: {{ .Values.auth.password | b64enc | quote }}
{{- end }}

# deployment.yaml - reference secret
env:
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ .Values.existingSecret | default (include "mychart.fullname" .) }}
        key: password
```

### Sealed Secrets Pattern
```yaml
# For GitOps with Sealed Secrets
{{- if .Values.sealedSecrets.enabled }}
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: {{ include "mychart.fullname" . }}
  labels:
    {{- include "mychart.labels" . | nindent 4 }}
spec:
  encryptedData:
    password: {{ .Values.sealedSecrets.encryptedPassword }}
{{- end }}
```

## Resource Limits (Security Aspect)

```yaml
# Prevent resource exhaustion attacks
resources:
  limits:
    cpu: 500m
    memory: 512Mi
    ephemeral-storage: 1Gi  # Prevent disk filling
  requests:
    cpu: 100m
    memory: 128Mi
    ephemeral-storage: 100Mi

# In deployment
resources:
  {{- toYaml .Values.resources | nindent 12 }}
```

## Image Security

```yaml
# values.yaml
image:
  repository: myregistry.io/myapp
  tag: ""  # Defaults to appVersion
  pullPolicy: IfNotPresent
  # Digest for immutable reference
  # digest: sha256:abc123...

# deployment.yaml
image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
{{- if .Values.image.digest }}
image: "{{ .Values.image.repository }}@{{ .Values.image.digest }}"
{{- end }}
imagePullPolicy: {{ .Values.image.pullPolicy }}
```

## Security Checklist Template

```yaml
# values.yaml - Security-focused template
# =============================================================================
# SECURITY CONFIGURATION
# =============================================================================

# Pod Security Context
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
  seccompProfile:
    type: RuntimeDefault

# Container Security Context
securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
    # Add only if required:
    # add:
    #   - NET_BIND_SERVICE
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 1000

# Service Account
serviceAccount:
  create: true
  automountServiceAccountToken: false
  annotations: {}

# RBAC
rbac:
  create: true
  rules: []  # Least privilege - add only what's needed

# Network Policy
networkPolicy:
  enabled: true
  # Configure allowed ingress/egress

# Pod Disruption Budget
podDisruptionBudget:
  enabled: true
  minAvailable: 1
  # maxUnavailable: 1

# Resource Limits (prevents DoS)
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

## Security Scanning Integration

### Trivy Scan
```bash
# Scan chart for misconfigurations
trivy config ./chart

# Scan rendered manifests
helm template release ./chart | trivy config -
```

### Checkov Scan
```bash
# Scan chart directory
checkov -d ./chart

# Scan rendered manifests
helm template release ./chart > manifests.yaml
checkov -f manifests.yaml
```

### kubesec Scan
```bash
# Scan rendered manifests
helm template release ./chart | kubesec scan -
```

## When Helping Users

1. **Default to Restricted PSS** - Start secure, loosen only if needed
2. **Never use wildcards in RBAC** - Always be specific
3. **Disable service account token mounting** - Unless explicitly needed
4. **Use NetworkPolicy** - Defense in depth
5. **No hardcoded secrets** - Use external secret management
6. **Set resource limits** - Prevent resource exhaustion
7. **Run as non-root** - Always, unless technically impossible
8. **Read-only filesystem** - Use emptyDir for write needs
9. **Drop all capabilities** - Add back only what's needed
10. **Pin image versions** - Never use 'latest' tag
