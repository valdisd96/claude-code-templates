# Analyze Helm Values

Deep analysis of values.yaml structure, types, defaults, and documentation coverage.

## Arguments
- `$ARGUMENTS`: Optional - path to specific values file (default: values.yaml in current chart)

## Execution Steps

### Phase 1: Values Discovery

```bash
VALUES_FILE="${ARGUMENTS:-values.yaml}"
CHART_PATH="."

echo "═══════════════════════════════════════════════════════════"
echo "HELM VALUES ANALYZER"
echo "═══════════════════════════════════════════════════════════"

# Find the values file
if [ ! -f "$VALUES_FILE" ]; then
    # Try to find it
    VALUES_FILE=$(find . -name "values.yaml" -type f | head -1)
    if [ -z "$VALUES_FILE" ]; then
        echo "❌ ERROR: No values.yaml found"
        exit 1
    fi
fi

CHART_PATH=$(dirname "$VALUES_FILE")

echo "📄 Analyzing: $VALUES_FILE"
echo "📦 Chart: $CHART_PATH"

# Basic stats
TOTAL_LINES=$(wc -l < "$VALUES_FILE")
COMMENT_LINES=$(grep -c "^#\|^\s*#" "$VALUES_FILE" 2>/dev/null || echo 0)
EMPTY_LINES=$(grep -c "^$" "$VALUES_FILE" 2>/dev/null || echo 0)

echo ""
echo "=== File Statistics ==="
echo "   Total lines: $TOTAL_LINES"
echo "   Comments: $COMMENT_LINES"
echo "   Empty: $EMPTY_LINES"
echo "   Content: $((TOTAL_LINES - COMMENT_LINES - EMPTY_LINES))"
```

### Phase 2: Structure Analysis

```bash
VALUES_FILE="${ARGUMENTS:-values.yaml}"

echo ""
echo "=== Top-Level Keys ==="
grep -E "^[a-zA-Z]" "$VALUES_FILE" | grep -v "^#" | head -30

echo ""
echo "=== Nested Structure (2 levels) ==="
awk '/^[a-zA-Z]/{parent=$1} /^  [a-zA-Z]/{print parent, $1}' "$VALUES_FILE" | head -40

echo ""
echo "=== Deep Nesting (3+ levels) ==="
grep -E "^      [a-zA-Z]" "$VALUES_FILE" | head -20 && echo "   (showing first 20 deeply nested keys)"
```

### Phase 3: Type Inference

```bash
VALUES_FILE="${ARGUMENTS:-values.yaml}"

echo ""
echo "=== Value Types Detected ==="

# Strings
echo "📝 Strings:"
grep -E ': ".+"$|: '"'"'.+'"'"'$' "$VALUES_FILE" | head -10 | sed 's/^/   /'

# Numbers
echo "📊 Numbers:"
grep -E ': [0-9]+$|: [0-9]+\.[0-9]+$' "$VALUES_FILE" | head -10 | sed 's/^/   /'

# Booleans
echo "🔘 Booleans:"
grep -E ': true$|: false$' "$VALUES_FILE" | head -10 | sed 's/^/   /'

# Arrays/Lists
echo "📋 Arrays:"
grep -E ': \[\]$|^  - ' "$VALUES_FILE" | head -10 | sed 's/^/   /'

# Null/Empty
echo "⭕ Null/Empty:"
grep -E ': null$|: ~$|: {}$|: \[\]$|:$' "$VALUES_FILE" | head -10 | sed 's/^/   /'

# Objects (keys with children)
echo "📦 Objects (with children):"
grep -E '^[a-zA-Z][a-zA-Z0-9]*:$' "$VALUES_FILE" | head -10 | sed 's/^/   /'
```

### Phase 4: Feature Flags Analysis

```bash
VALUES_FILE="${ARGUMENTS:-values.yaml}"
CHART_PATH=$(dirname "$VALUES_FILE")

echo ""
echo "=== Feature Flags (*.enabled) ==="

# Find all enabled flags
grep -E "enabled:" "$VALUES_FILE" | while read line; do
    echo "   🔀 $line"
done

echo ""
echo "=== Conditional Usage in Templates ==="
if [ -d "$CHART_PATH/templates" ]; then
    grep -rh "\.enabled" "$CHART_PATH/templates/" 2>/dev/null | grep -oE '\.[a-zA-Z]+\.enabled' | sort -u | while read cond; do
        # Check if this condition exists in values
        key=$(echo "$cond" | sed 's/^\.//' | sed 's/\.enabled$//')
        if grep -q "${key}:" "$VALUES_FILE" 2>/dev/null; then
            echo "   ✓ $cond (defined in values)"
        else
            echo "   ⚠️  $cond (NOT in values - may cause nil error)"
        fi
    done
fi
```

### Phase 5: Documentation Coverage

```bash
VALUES_FILE="${ARGUMENTS:-values.yaml}"

echo ""
echo "=== Documentation Coverage ==="

# Count documented vs undocumented keys
TOTAL_KEYS=$(grep -cE "^[a-zA-Z].*:" "$VALUES_FILE" 2>/dev/null || echo 0)

# Keys with preceding comment
DOCUMENTED=0
UNDOCUMENTED=0
LAST_WAS_COMMENT=false

while IFS= read -r line; do
    if [[ "$line" =~ ^# ]]; then
        LAST_WAS_COMMENT=true
    elif [[ "$line" =~ ^[a-zA-Z].*: ]]; then
        if [ "$LAST_WAS_COMMENT" = true ]; then
            ((DOCUMENTED++))
        else
            ((UNDOCUMENTED++))
            [ $UNDOCUMENTED -le 10 ] && echo "   ○ Undocumented: ${line%%:*}"
        fi
        LAST_WAS_COMMENT=false
    else
        LAST_WAS_COMMENT=false
    fi
done < "$VALUES_FILE"

COVERAGE=$((DOCUMENTED * 100 / (DOCUMENTED + UNDOCUMENTED + 1)))
echo ""
echo "   📊 Documentation coverage: ${COVERAGE}% ($DOCUMENTED/$((DOCUMENTED + UNDOCUMENTED)) keys)"
```

### Phase 6: Schema Validation Check

```bash
VALUES_FILE="${ARGUMENTS:-values.yaml}"
CHART_PATH=$(dirname "$VALUES_FILE")

echo ""
echo "=== Schema Validation ==="

SCHEMA_FILE="$CHART_PATH/values.schema.json"
if [ -f "$SCHEMA_FILE" ]; then
    echo "✓ values.schema.json found"

    # Basic schema stats
    if command -v python3 &> /dev/null; then
        python3 -c "
import json
with open('$SCHEMA_FILE') as f:
    schema = json.load(f)
    props = schema.get('properties', {})
    required = schema.get('required', [])
    print(f'   Properties defined: {len(props)}')
    print(f'   Required fields: {len(required)}')
    if required:
        print('   Required:', ', '.join(required[:5]))
" 2>/dev/null
    fi
else
    echo "○ No values.schema.json found"
    echo ""
    echo "💡 Recommendation: Add values.schema.json for:"
    echo "   - IDE autocompletion"
    echo "   - Validation during helm install/upgrade"
    echo "   - Documentation generation"
    echo ""
    echo "   Generate with: helm schema generate values.yaml > values.schema.json"
fi
```

### Phase 7: Values Comparison (if multiple files)

```bash
VALUES_FILE="${ARGUMENTS:-values.yaml}"
CHART_PATH=$(dirname "$VALUES_FILE")

echo ""
echo "=== Environment Values Files ==="

ls "$CHART_PATH"/values*.yaml "$CHART_PATH"/values*.yml 2>/dev/null | while read f; do
    if [ "$f" != "$VALUES_FILE" ]; then
        echo "📄 $f"
        # Show keys that differ from base
        diff_count=$(diff <(grep -E "^[a-zA-Z]" "$VALUES_FILE") <(grep -E "^[a-zA-Z]" "$f") 2>/dev/null | grep -c "^[<>]" || echo 0)
        echo "   Different top-level keys: $diff_count"
    fi
done
```

### Phase 8: Generate Report

```
═══════════════════════════════════════════════════════════
VALUES ANALYSIS REPORT
═══════════════════════════════════════════════════════════

File: [values file path]
Chart: [chart name]

Structure Summary:
  📊 Total keys: [count]
  📊 Top-level: [count]
  📊 Max nesting: [depth] levels

Type Distribution:
  📝 Strings: [count]
  📊 Numbers: [count]
  🔘 Booleans: [count]
  📋 Arrays: [count]
  📦 Objects: [count]
  ⭕ Null/Empty: [count]

Feature Flags:
  🔀 [count] feature toggles found
  ✓ [count] properly defined
  ⚠️  [count] missing definitions

Documentation:
  Coverage: [X]%
  ○ Undocumented keys: [list first 5]

Schema:
  [✓/○] values.schema.json: [present/missing]

Potential Issues:
  - [Issue 1]
  - [Issue 2]

Recommendations:
  1. [Add documentation for key X]
  2. [Add default for required field Y]
  3. [Create values.schema.json]

Next Steps:
  - Run /debug-template to test values rendering
  - Run /diff-values values.yaml values-prod.yaml
  - Create values.schema.json for validation
═══════════════════════════════════════════════════════════
```
