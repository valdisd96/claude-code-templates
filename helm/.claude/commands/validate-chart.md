# Validate Helm Chart

Lint and test template rendering.

## Arguments
- `$ARGUMENTS`: Chart path (default: current directory)

## Steps

1. Run helm lint:
```bash
helm lint "${ARGUMENTS:-.}" --strict
```

2. Test template rendering:
```bash
helm template test-release "${ARGUMENTS:-.}" --debug 2>&1 | head -100
```

3. Report results:
- If lint passes and templates render: Chart is valid
- If lint fails: Show errors and suggest fixes
- If templates fail: Run `/debug-template` for detailed analysis
