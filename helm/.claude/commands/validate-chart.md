# Validate Helm Chart

Lint and validate chart structure against best practices.

## Arguments
- `$ARGUMENTS`: Path to chart directory (default: current directory)

## Execution Steps

### Phase 1: Structure Validation

```bash
CHART_PATH="${ARGUMENTS:-.}"

# Check required files exist
echo "=== Checking Required Files ==="
[ -f "$CHART_PATH/Chart.yaml" ] && echo "✓ Chart.yaml" || echo "✗ Chart.yaml MISSING"
[ -f "$CHART_PATH/values.yaml" ] && echo "✓ values.yaml" || echo "✗ values.yaml MISSING"
[ -d "$CHART_PATH/templates" ] && echo "✓ templates/" || echo "✗ templates/ MISSING"

# Check recommended files
echo ""
echo "=== Checking Recommended Files ==="
[ -f "$CHART_PATH/README.md" ] && echo "✓ README.md" || echo "○ README.md (recommended)"
[ -f "$CHART_PATH/values.schema.json" ] && echo "✓ values.schema.json" || echo "○ values.schema.json (recommended)"
[ -f "$CHART_PATH/.helmignore" ] && echo "✓ .helmignore" || echo "○ .helmignore (recommended)"
[ -f "$CHART_PATH/templates/NOTES.txt" ] && echo "✓ NOTES.txt" || echo "○ NOTES.txt (recommended)"
[ -f "$CHART_PATH/templates/_helpers.tpl" ] && echo "✓ _helpers.tpl" || echo "○ _helpers.tpl (recommended)"
```

### Phase 2: Helm Lint

```bash
echo ""
echo "=== Helm Lint ==="
helm lint "$CHART_PATH" --strict 2>&1
LINT_EXIT=$?

echo ""
echo "=== Lint with Debug ==="
helm lint "$CHART_PATH" --debug 2>&1 | head -50
```

### Phase 3: Template Rendering Test

```bash
echo ""
echo "=== Template Rendering Test ==="
helm template test-release "$CHART_PATH" --debug 2>&1 | head -100

# Check for common issues
echo ""
echo "=== Common Issues Check ==="

# Hardcoded names
grep -r "name: [a-z]" "$CHART_PATH/templates/"*.yaml 2>/dev/null | grep -v "include\|define\|.Values\|.Release\|.Chart" && echo "⚠ Possible hardcoded names found"

# Missing quotes on string values
grep -rE "value: \{\{.*\}\}$" "$CHART_PATH/templates/"*.yaml 2>/dev/null | grep -v "quote\|toYaml" && echo "⚠ Possible unquoted string values"
```

### Phase 4: Generate Report

```
═══════════════════════════════════════════════════════════
HELM CHART VALIDATION REPORT
═══════════════════════════════════════════════════════════

Chart: [name from Chart.yaml]
Version: [version]
App Version: [appVersion]

Structure:
  Required Files: [X/3 present]
  Recommended Files: [X/5 present]

Lint Results:
  Status: [PASSED/FAILED]
  Warnings: [count]
  Errors: [count]

Template Rendering:
  Status: [SUCCESS/FAILED]

Issues Found:
  - [Issue 1]
  - [Issue 2]

Recommendations:
  1. [Improvement suggestion]
  2. [Improvement suggestion]

Next Steps:
  - Run /debug-template [name] for specific template issues
  - Run helm install --dry-run for cluster validation
═══════════════════════════════════════════════════════════
```
