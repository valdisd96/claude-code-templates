# Initialize Helm Chart Memory Bank

Analyze the current Helm chart repository and generate a comprehensive Memory Bank documentation system for persistent context across sessions.

## Arguments
- `$ARGUMENTS`: Optional - path to chart directory (default: current directory)

## Critical Rules

1. **Always run discovery commands FIRST** before generating any files
2. **Never hallucinate** - only document what is actually found in charts
3. **Mark unknowns as `[TODO]`** - don't guess at business context
4. **Preserve existing docs** - if Memory Bank exists, merge don't overwrite

## Execution Steps

### Phase 1: Chart Discovery

```bash
CHART_PATH="${ARGUMENTS:-.}"

echo "═══════════════════════════════════════════════════════════"
echo "HELM CHART DISCOVERY"
echo "═══════════════════════════════════════════════════════════"

# 1. Find all charts in repository
echo ""
echo "=== Charts Found ==="
find "$CHART_PATH" -name "Chart.yaml" -type f 2>/dev/null | while read chart; do
    dir=$(dirname "$chart")
    echo "📦 $dir"
    grep -E "^name:|^version:|^appVersion:|^description:" "$chart" 2>/dev/null | sed 's/^/   /'
done

# 2. Chart structure analysis
echo ""
echo "=== Repository Structure ==="
find "$CHART_PATH" -maxdepth 4 -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.tpl" -o -name "*.json" \) 2>/dev/null | grep -v ".git" | sort

# 3. Values files detection
echo ""
echo "=== Values Files ==="
find "$CHART_PATH" -name "values*.yaml" -o -name "values*.yml" 2>/dev/null | sort

# 4. Existing documentation
echo ""
echo "=== Existing Documentation ==="
find "$CHART_PATH" -maxdepth 3 \( -name "README*" -o -name "CHANGELOG*" -o -name "*.md" \) -type f 2>/dev/null
```

### Phase 2: Deep Chart Analysis

```bash
CHART_PATH="${ARGUMENTS:-.}"

# 1. Dependencies analysis
echo ""
echo "=== Dependencies ==="
for chart in $(find "$CHART_PATH" -name "Chart.yaml" 2>/dev/null); do
    dir=$(dirname "$chart")
    echo "📦 $dir:"
    grep -A 20 "^dependencies:" "$chart" 2>/dev/null | head -25
    [ -f "$dir/Chart.lock" ] && echo "   🔒 Chart.lock present"
done

# 2. Template analysis
echo ""
echo "=== Templates Overview ==="
for tpl_dir in $(find "$CHART_PATH" -type d -name "templates" 2>/dev/null); do
    echo "📁 $tpl_dir:"
    ls -la "$tpl_dir"/*.yaml "$tpl_dir"/*.yml "$tpl_dir"/*.tpl 2>/dev/null | awk '{print "   " $NF}'
done

# 3. Helper functions
echo ""
echo "=== Named Templates (Helpers) ==="
find "$CHART_PATH" -name "_helpers.tpl" -exec grep -h "define \"" {} \; 2>/dev/null | sed 's/.*define "\([^"]*\)".*/   🔧 \1/'

# 4. Values structure (top-level keys)
echo ""
echo "=== Values Structure ==="
for values in $(find "$CHART_PATH" -name "values.yaml" 2>/dev/null | head -5); do
    echo "📄 $values:"
    grep -E "^[a-zA-Z]" "$values" 2>/dev/null | head -30 | sed 's/^/   /'
done

# 5. Conditional features detection
echo ""
echo "=== Conditional Features ==="
grep -rh "\.enabled" "$CHART_PATH"/*/templates/ 2>/dev/null | grep -oE '\.[a-zA-Z]+\.enabled' | sort -u | sed 's/^/   🔀 /'

# 6. Resource types
echo ""
echo "=== Kubernetes Resources ==="
grep -rh "^kind:" "$CHART_PATH"/*/templates/ 2>/dev/null | sort | uniq -c | sort -rn | sed 's/^/   /'
```

### Phase 3: Values Deep Dive

```bash
CHART_PATH="${ARGUMENTS:-.}"

# Analyze values.yaml structure
echo ""
echo "=== Values Analysis ==="

for values in $(find "$CHART_PATH" -name "values.yaml" 2>/dev/null | head -3); do
    echo "📄 $values"

    # Image configurations
    echo "   🐳 Images:"
    grep -E "image:|repository:|tag:" "$values" 2>/dev/null | head -10 | sed 's/^/      /'

    # Resource configurations
    echo "   💾 Resources:"
    grep -A 10 "^resources:" "$values" 2>/dev/null | head -12 | sed 's/^/      /'

    # Ingress/Service
    echo "   🌐 Networking:"
    grep -E "ingress:|service:|port:|host:" "$values" 2>/dev/null | head -10 | sed 's/^/      /'

    # Security contexts
    echo "   🔐 Security:"
    grep -E "securityContext:|runAsUser:|runAsNonRoot:|readOnlyRootFilesystem:" "$values" 2>/dev/null | head -10 | sed 's/^/      /'
done

# Check for values.schema.json
echo ""
echo "=== Schema Validation ==="
find "$CHART_PATH" -name "values.schema.json" 2>/dev/null | while read schema; do
    echo "✓ Found: $schema"
    python3 -c "import json; s=json.load(open('$schema')); print('  Properties:', len(s.get('properties', {})))" 2>/dev/null
done || echo "○ No values.schema.json found (recommended to add)"
```

### Phase 4: Generate Memory Bank

Create `docs/memory-bank/` directory and generate Helm-specific documentation:

#### chartbrief.md
```markdown
# Chart Brief

## Overview
<!-- Generated from Chart.yaml -->
[DISCOVERED: chart name, description, version]

## Charts in Repository
| Chart | Version | App Version | Description |
|-------|---------|-------------|-------------|
| [name] | [version] | [appVersion] | [description] |

## Maintainers
[DISCOVERED from Chart.yaml or TODO]

## Keywords
[DISCOVERED or TODO]

## Target Use Cases
[TODO: Describe when to use this chart]

## Prerequisites
- Kubernetes [version]
- Helm [version]
- [Other requirements]
```

#### valuesContext.md
```markdown
# Values Context

## Values Hierarchy
<!-- Auto-generated from values.yaml analysis -->

### Global Values
| Key | Type | Default | Description |
|-----|------|---------|-------------|
| [key] | [type] | [default] | [TODO] |

### Image Configuration
```yaml
# Discovered pattern:
[image configuration block]
```

### Resource Limits
```yaml
# Discovered pattern:
[resources block]
```

### Feature Flags
| Feature | Key | Default | Purpose |
|---------|-----|---------|---------|
| [name] | [.enabled key] | [value] | [TODO] |

## Environment-Specific Overrides
[TODO: Document values for dev/staging/prod]

## Required vs Optional Values
### Required
- [List values that must be set]

### Optional with Sensible Defaults
- [List values with good defaults]
```

#### templatePatterns.md
```markdown
# Template Patterns

## Named Templates (Helpers)
| Template | Purpose | Usage |
|----------|---------|-------|
| [name] | [inferred] | `{{ include "[name]" . }}` |

## Resource Templates
| File | Kind | Description |
|------|------|-------------|
| [file.yaml] | [Kind] | [TODO] |

## Conditional Patterns
```yaml
# Feature toggles found:
{{- if .Values.xxx.enabled }}
...
{{- end }}
```

## Label Standards
```yaml
# Standard labels used:
[discovered label pattern]
```

## Common Patterns
### Image Pull
```yaml
[discovered image pattern]
```

### Resource Limits
```yaml
[discovered resource pattern]
```

### Probes
```yaml
[discovered probe pattern]
```
```

#### releaseContext.md
```markdown
# Release Context

## Target Environments
| Environment | Values File | Notes |
|-------------|-------------|-------|
| Development | values-dev.yaml | [TODO] |
| Staging | values-staging.yaml | [TODO] |
| Production | values-prod.yaml | [TODO] |

## Upgrade Considerations
[TODO: Document breaking changes between versions]

## Rollback Procedures
[TODO: Document rollback steps]

## Dependencies
| Dependency | Version | Repository | Condition |
|------------|---------|------------|-----------|
| [name] | [version] | [repo] | [condition] |

## Integration Points
- [External systems this chart connects to]
```

#### activeContext.md
```markdown
# Active Context

## Current Session
- **Date**: [today]
- **Focus**: Initial chart analysis

## Working On
[To be updated each session]

## Recent Decisions
[Architecture/design decisions made]

## Open Questions
- [Questions discovered during analysis]

## Next Session
[To be updated at session end]
```

#### progress.md
```markdown
# Progress Tracker

## What Works
<!-- Verified functionality -->
- [ ] Chart lints successfully
- [ ] Templates render without errors
- [ ] [Feature]: [status]

## In Progress
- [Current work items]

## Known Issues
<!-- From template analysis -->
- [ ] [Issue found]

## Backlog
[TODO: Add planned improvements]

## Recent Changes
- [Date]: Initial Memory Bank creation
```

### Phase 5: Verification & Report

```bash
# Verify created files
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "MEMORY BANK INITIALIZATION COMPLETE"
echo "═══════════════════════════════════════════════════════════"

ls -la docs/memory-bank/ 2>/dev/null

echo ""
echo "Created Files:"
for f in docs/memory-bank/*.md; do
    lines=$(wc -l < "$f" 2>/dev/null || echo 0)
    todos=$(grep -c "TODO" "$f" 2>/dev/null || echo 0)
    echo "  ✓ $(basename $f) [$lines lines, $todos TODOs]"
done
```

Output summary:
```
═══════════════════════════════════════════════════════════
HELM MEMORY BANK INITIALIZED
═══════════════════════════════════════════════════════════

Repository Analysis:
  📦 Charts Found: [count]
  📄 Values Files: [count]
  📁 Templates: [count]
  🔧 Named Templates: [count]

Memory Bank Created:
  ✓ chartbrief.md        - Chart overview & metadata
  ✓ valuesContext.md     - Values documentation
  ✓ templatePatterns.md  - Template architecture
  ✓ releaseContext.md    - Deployment context
  ✓ activeContext.md     - Session tracking
  ✓ progress.md          - Work tracking

Discovered:
  ✓ [Items auto-populated from chart analysis]

Needs Your Input:
  ○ [TODO items requiring human knowledge]

Next Steps:
  1. Review chartbrief.md for accuracy
  2. Fill TODOs in valuesContext.md
  3. Document environments in releaseContext.md
  4. Run /validate-chart to verify chart health
  5. Run /analyze-values for detailed values analysis
═══════════════════════════════════════════════════════════
```
