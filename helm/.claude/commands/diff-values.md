# Diff Helm Values Files

Compare two values files to identify differences, useful for environment comparisons and change review.

## Arguments
- `$ARGUMENTS`: Two values files to compare (e.g., "values.yaml values-prod.yaml")

## Execution Steps

### Phase 1: File Validation

```bash
ARGS="${ARGUMENTS}"

echo "═══════════════════════════════════════════════════════════"
echo "HELM VALUES DIFF"
echo "═══════════════════════════════════════════════════════════"

# Parse arguments
FILE1=$(echo "$ARGS" | awk '{print $1}')
FILE2=$(echo "$ARGS" | awk '{print $2}')

if [ -z "$FILE1" ] || [ -z "$FILE2" ]; then
    echo "❌ Usage: /diff-values <file1> <file2>"
    echo ""
    echo "Available values files:"
    find . -name "values*.yaml" -o -name "values*.yml" 2>/dev/null | sort
    exit 1
fi

# Validate files exist
if [ ! -f "$FILE1" ]; then
    echo "❌ File not found: $FILE1"
    exit 1
fi

if [ ! -f "$FILE2" ]; then
    echo "❌ File not found: $FILE2"
    exit 1
fi

echo "📄 Base: $FILE1"
echo "📄 Compare: $FILE2"
```

### Phase 2: Structural Comparison

```bash
FILE1=$(echo "$ARGUMENTS" | awk '{print $1}')
FILE2=$(echo "$ARGUMENTS" | awk '{print $2}')

echo ""
echo "=== Structural Comparison ==="

# Compare top-level keys
echo ""
echo "📊 Top-level keys:"

KEYS1=$(grep -E "^[a-zA-Z]" "$FILE1" | cut -d: -f1 | sort)
KEYS2=$(grep -E "^[a-zA-Z]" "$FILE2" | cut -d: -f1 | sort)

# Keys only in file1
echo ""
echo "   Only in $FILE1:"
comm -23 <(echo "$KEYS1") <(echo "$KEYS2") | sed 's/^/   ➖ /'

# Keys only in file2
echo ""
echo "   Only in $FILE2:"
comm -13 <(echo "$KEYS1") <(echo "$KEYS2") | sed 's/^/   ➕ /'

# Keys in both
COMMON=$(comm -12 <(echo "$KEYS1") <(echo "$KEYS2"))
echo ""
echo "   In both: $(echo "$COMMON" | wc -l | tr -d ' ') keys"
```

### Phase 3: Value Differences

```bash
FILE1=$(echo "$ARGUMENTS" | awk '{print $1}')
FILE2=$(echo "$ARGUMENTS" | awk '{print $2}')

echo ""
echo "=== Value Differences ==="

# Use diff to show changes
diff -u "$FILE1" "$FILE2" 2>/dev/null | head -100

# Summary
ADDED=$(diff "$FILE1" "$FILE2" 2>/dev/null | grep -c "^>" || echo 0)
REMOVED=$(diff "$FILE1" "$FILE2" 2>/dev/null | grep -c "^<" || echo 0)

echo ""
echo "📊 Summary:"
echo "   ➕ Lines added: $ADDED"
echo "   ➖ Lines removed: $REMOVED"
```

### Phase 4: Semantic Analysis

```bash
FILE1=$(echo "$ARGUMENTS" | awk '{print $1}')
FILE2=$(echo "$ARGUMENTS" | awk '{print $2}')

echo ""
echo "=== Semantic Analysis ==="

# Compare specific important sections
sections="image resources replicas ingress service"

for section in $sections; do
    echo ""
    echo "📦 $section:"

    # Extract section from both files
    SEC1=$(grep -A 20 "^${section}:" "$FILE1" 2>/dev/null | head -20)
    SEC2=$(grep -A 20 "^${section}:" "$FILE2" 2>/dev/null | head -20)

    if [ -z "$SEC1" ] && [ -z "$SEC2" ]; then
        echo "   ○ Not present in either file"
    elif [ -z "$SEC1" ]; then
        echo "   ➕ Only in $FILE2"
    elif [ -z "$SEC2" ]; then
        echo "   ➖ Only in $FILE1"
    elif [ "$SEC1" = "$SEC2" ]; then
        echo "   ✓ Identical"
    else
        echo "   ⚠️  Different:"
        diff <(echo "$SEC1") <(echo "$SEC2") 2>/dev/null | head -15 | sed 's/^/   /'
    fi
done
```

### Phase 5: Feature Flags Comparison

```bash
FILE1=$(echo "$ARGUMENTS" | awk '{print $1}')
FILE2=$(echo "$ARGUMENTS" | awk '{print $2}')

echo ""
echo "=== Feature Flags Comparison ==="

# Extract all enabled/disabled flags
FLAGS1=$(grep -E "enabled:" "$FILE1" 2>/dev/null | sort)
FLAGS2=$(grep -E "enabled:" "$FILE2" 2>/dev/null | sort)

echo ""
echo "📄 $FILE1:"
echo "$FLAGS1" | sed 's/^/   /'

echo ""
echo "📄 $FILE2:"
echo "$FLAGS2" | sed 's/^/   /'

# Find differences in enabled states
echo ""
echo "🔀 Flag differences:"
while IFS= read -r line; do
    key=$(echo "$line" | sed 's/:.*$//')
    val1=$(grep "^$key:" "$FILE1" 2>/dev/null | grep "enabled" | awk '{print $NF}')
    val2=$(grep "^$key:" "$FILE2" 2>/dev/null | grep "enabled" | awk '{print $NF}')

    if [ "$val1" != "$val2" ] && [ -n "$val1" ] && [ -n "$val2" ]; then
        echo "   $key: $val1 → $val2"
    fi
done < <(grep -h "enabled:" "$FILE1" "$FILE2" 2>/dev/null | sed 's/enabled:.*//' | sort -u)
```

### Phase 6: Security-Sensitive Differences

```bash
FILE1=$(echo "$ARGUMENTS" | awk '{print $1}')
FILE2=$(echo "$ARGUMENTS" | awk '{print $2}')

echo ""
echo "=== Security-Sensitive Differences ==="

# Check for changes in security-related values
security_patterns="securityContext|runAsUser|runAsNonRoot|readOnlyRootFilesystem|capabilities|allowPrivilegeEscalation|serviceAccount|rbac|networkPolicy|podSecurityPolicy"

echo ""
echo "🔐 Security configuration changes:"

for pattern in securityContext runAsUser runAsNonRoot capabilities serviceAccount; do
    SEC1=$(grep -A 5 "$pattern" "$FILE1" 2>/dev/null)
    SEC2=$(grep -A 5 "$pattern" "$FILE2" 2>/dev/null)

    if [ "$SEC1" != "$SEC2" ]; then
        echo ""
        echo "   ⚠️  $pattern differs:"
        diff <(echo "$SEC1") <(echo "$SEC2") 2>/dev/null | head -10 | sed 's/^/      /'
    fi
done
```

### Phase 7: Generate Report

```
═══════════════════════════════════════════════════════════
VALUES DIFF REPORT
═══════════════════════════════════════════════════════════

Comparing:
  📄 Base: [file1]
  📄 Compare: [file2]

Structural Summary:
  ➕ Keys only in [file2]: [count]
  ➖ Keys only in [file1]: [count]
  ✓ Common keys: [count]

Line Changes:
  ➕ Lines added: [count]
  ➖ Lines removed: [count]
  📊 Total changes: [count]

Section Comparison:
| Section | Status |
|---------|--------|
| image | [identical/different/missing] |
| resources | [identical/different/missing] |
| replicas | [identical/different/missing] |
| ingress | [identical/different/missing] |
| service | [identical/different/missing] |

Feature Flag Changes:
  🔀 [feature]: [value1] → [value2]
  🔀 [feature]: [value1] → [value2]

Security Changes:
  [⚠️/✓] securityContext: [changed/unchanged]
  [⚠️/✓] serviceAccount: [changed/unchanged]
  [⚠️/✓] capabilities: [changed/unchanged]

Key Differences:
  1. [Most important change]
  2. [Second important change]
  3. [Third important change]

Recommendations:
  - Review security changes carefully
  - Ensure resource limits are appropriate for target environment
  - Verify feature flags match environment requirements

Commands:
  # Render with base values
  helm template release . -f [file1]

  # Render with compare values
  helm template release . -f [file2]

  # Render with merged values
  helm template release . -f [file1] -f [file2]
═══════════════════════════════════════════════════════════
```
