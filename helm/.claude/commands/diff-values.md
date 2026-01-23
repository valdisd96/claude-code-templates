# Diff Values Files

Compare two values files to identify differences.

## Arguments
- `$ARGUMENTS`: Two file paths (e.g., "values.yaml values-prod.yaml")

## Steps

1. Parse file paths from arguments:
```bash
FILE1=$(echo "$ARGUMENTS" | awk '{print $1}')
FILE2=$(echo "$ARGUMENTS" | awk '{print $2}')
```

2. Show unified diff:
```bash
diff -u "$FILE1" "$FILE2"
```

3. Summarize key differences:
   - Feature flag changes (`.enabled` values)
   - Resource limits/requests differences
   - Replica count differences
   - Image tag differences
