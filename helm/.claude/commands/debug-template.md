# Debug Helm Template

Render and debug a specific Helm template with custom values, showing detailed output and common issues.

## Arguments
- `$ARGUMENTS`: Template name or path (e.g., "deployment", "templates/deployment.yaml", or "all")

## Execution Steps

### Phase 1: Chart & Template Discovery

```bash
TEMPLATE_ARG="${ARGUMENTS:-all}"
CHART_PATH="."

echo "═══════════════════════════════════════════════════════════"
echo "HELM TEMPLATE DEBUGGER"
echo "═══════════════════════════════════════════════════════════"

# Find Chart.yaml
if [ ! -f "$CHART_PATH/Chart.yaml" ]; then
    # Maybe we're in a parent directory
    CHART_PATH=$(find . -name "Chart.yaml" -type f -exec dirname {} \; | head -1)
    if [ -z "$CHART_PATH" ]; then
        echo "❌ ERROR: No Chart.yaml found"
        exit 1
    fi
fi

echo "📦 Chart: $CHART_PATH"
grep -E "^name:|^version:" "$CHART_PATH/Chart.yaml" | sed 's/^/   /'

# List available templates
echo ""
echo "=== Available Templates ==="
ls -1 "$CHART_PATH/templates/"*.yaml "$CHART_PATH/templates/"*.yml 2>/dev/null | while read f; do
    kind=$(grep "^kind:" "$f" 2>/dev/null | head -1 | awk '{print $2}')
    echo "   📄 $(basename $f) → $kind"
done
```

### Phase 2: Template Selection & Rendering

```bash
TEMPLATE_ARG="${ARGUMENTS:-all}"
CHART_PATH="${CHART_PATH:-.}"

echo ""
echo "=== Rendering Template ==="

if [ "$TEMPLATE_ARG" = "all" ]; then
    echo "🔄 Rendering all templates..."
    helm template debug-release "$CHART_PATH" --debug 2>&1
else
    # Normalize template name
    if [[ "$TEMPLATE_ARG" != templates/* ]]; then
        TEMPLATE_ARG="templates/$TEMPLATE_ARG"
    fi
    if [[ "$TEMPLATE_ARG" != *.yaml ]] && [[ "$TEMPLATE_ARG" != *.yml ]]; then
        TEMPLATE_ARG="$TEMPLATE_ARG.yaml"
    fi

    echo "🔄 Rendering: $TEMPLATE_ARG"
    helm template debug-release "$CHART_PATH" -s "$TEMPLATE_ARG" --debug 2>&1
fi
```

### Phase 3: Values Resolution Analysis

```bash
CHART_PATH="${CHART_PATH:-.}"

echo ""
echo "=== Values Being Used ==="

# Show computed values
echo "📋 Effective values (merged):"
helm show values "$CHART_PATH" 2>/dev/null | head -50

# Check for values files
echo ""
echo "=== Values Files Available ==="
ls -la "$CHART_PATH"/values*.yaml "$CHART_PATH"/values*.yml 2>/dev/null

# Show value overrides if multiple files exist
if ls "$CHART_PATH"/values-*.yaml 1> /dev/null 2>&1; then
    echo ""
    echo "💡 Tip: Render with specific values file:"
    echo "   helm template release $CHART_PATH -f values-dev.yaml"
fi
```

### Phase 4: Error Detection & Analysis

```bash
TEMPLATE_ARG="${ARGUMENTS:-all}"
CHART_PATH="${CHART_PATH:-.}"

echo ""
echo "=== Error Detection ==="

# Capture template output for analysis
TEMPLATE_OUTPUT=$(helm template debug-release "$CHART_PATH" 2>&1)
TEMPLATE_EXIT=$?

if [ $TEMPLATE_EXIT -ne 0 ]; then
    echo "❌ Template rendering FAILED"
    echo ""
    echo "Error output:"
    echo "$TEMPLATE_OUTPUT" | grep -A 5 "Error:\|error:"

    echo ""
    echo "=== Common Fixes ==="

    # Detect specific error patterns
    if echo "$TEMPLATE_OUTPUT" | grep -q "nil pointer"; then
        echo "🔧 Nil pointer: A required value is missing"
        echo "   Check: Are all required values set in values.yaml?"
        echo "   Fix: Add default with: {{ .Values.key | default \"value\" }}"
    fi

    if echo "$TEMPLATE_OUTPUT" | grep -q "can't evaluate field"; then
        echo "🔧 Field evaluation error: Accessing non-existent field"
        echo "   Check: Verify the values path exists"
        echo "   Fix: Use {{ if .Values.parent }}{{ .Values.parent.child }}{{ end }}"
    fi

    if echo "$TEMPLATE_OUTPUT" | grep -q "expected.*got"; then
        echo "🔧 Type mismatch: Wrong value type"
        echo "   Check: Is the value a string when it should be int, or vice versa?"
        echo "   Fix: Use type conversion: {{ int .Values.port }}"
    fi
else
    echo "✓ Template rendering successful"

    # Check for potential issues in rendered output
    echo ""
    echo "=== Potential Issues Check ==="

    # Check for empty/null values
    if echo "$TEMPLATE_OUTPUT" | grep -qE ':\s*$|: null$|: ""$'; then
        echo "⚠️  Empty or null values detected:"
        echo "$TEMPLATE_OUTPUT" | grep -nE ':\s*$|: null$|: ""$' | head -10
    fi

    # Check for placeholder text
    if echo "$TEMPLATE_OUTPUT" | grep -qi "todo\|fixme\|changeme\|placeholder"; then
        echo "⚠️  Placeholder text found:"
        echo "$TEMPLATE_OUTPUT" | grep -ni "todo\|fixme\|changeme\|placeholder" | head -5
    fi

    # Check for hardcoded values that should be templated
    if echo "$TEMPLATE_OUTPUT" | grep -qE 'image:.*:latest'; then
        echo "⚠️  'latest' tag detected (not recommended for production)"
    fi
fi
```

### Phase 5: Dry-Run Validation

```bash
CHART_PATH="${CHART_PATH:-.}"

echo ""
echo "=== Kubernetes Dry-Run Validation ==="

# Check if we can do dry-run (needs kubectl configured)
if command -v kubectl &> /dev/null && kubectl cluster-info &> /dev/null 2>&1; then
    echo "🔄 Running server-side dry-run..."
    helm template debug-release "$CHART_PATH" | kubectl apply --dry-run=server -f - 2>&1 | head -30
else
    echo "○ Cluster not available - skipping server-side validation"
    echo "   To enable: configure kubectl to point to a cluster"
    echo ""
    echo "🔄 Running client-side validation..."
    helm template debug-release "$CHART_PATH" | kubectl apply --dry-run=client -f - 2>&1 | head -30
fi
```

### Phase 6: Generate Report

```
═══════════════════════════════════════════════════════════
TEMPLATE DEBUG REPORT
═══════════════════════════════════════════════════════════

Chart: [name] v[version]
Template: [template name or "all"]

Rendering Status:
  ✓/✗ Helm template: [PASSED/FAILED]
  ✓/✗ Syntax valid: [PASSED/FAILED]
  ✓/○ K8s dry-run: [PASSED/SKIPPED]

Values Used:
  📄 Base: values.yaml
  📄 Override: [if any]

Issues Found:
  [count] Errors
  [count] Warnings
  [count] Suggestions

Error Details (if any):
  - [Error 1]: [suggested fix]
  - [Error 2]: [suggested fix]

Warnings:
  ⚠️  [Warning 1]
  ⚠️  [Warning 2]

Debug Commands:
  # Render with verbose output
  helm template debug $CHART_PATH --debug

  # Render with custom values
  helm template debug $CHART_PATH -f values-custom.yaml

  # Render single template
  helm template debug $CHART_PATH -s templates/[name].yaml

  # Show computed values
  helm get values [release] --all

Next Steps:
  - Fix [error] in [file]
  - Run /validate-chart for full validation
  - Run /analyze-values to check values structure
═══════════════════════════════════════════════════════════
```
