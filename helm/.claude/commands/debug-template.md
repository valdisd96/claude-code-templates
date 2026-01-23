# Debug Helm Template

Render a specific template and diagnose errors.

## Arguments
- `$ARGUMENTS`: Template name (e.g., "deployment", "service") or "all"

## Steps

1. Render the template:
```bash
# For specific template
helm template test-release . -s templates/${ARGUMENTS}.yaml --debug 2>&1

# For all templates (if $ARGUMENTS is "all" or empty)
helm template test-release . --debug 2>&1
```

2. If rendering fails, identify the error type:
   - "nil pointer evaluating" → Missing value, suggest `default` or `if` check
   - "can't evaluate field" → Wrong scope in range, suggest using `$`
   - "expected X; got Y" → Type mismatch, suggest conversion function
   - YAML parse error → Indentation issue, check `nindent` usage

3. Show the specific line causing the error and suggest a fix.
