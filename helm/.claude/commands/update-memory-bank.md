# Update Helm Memory Bank

Analyze recent changes in the chart repository and update Memory Bank documentation accordingly.

## Arguments
- `$ARGUMENTS`: Optional focus area: "values", "templates", "deps", "all" (default: "all")

## Critical Rules

1. **Read before write** - always read existing Memory Bank files first
2. **Incremental updates** - append/modify, don't regenerate from scratch
3. **Preserve manual edits** - don't overwrite human-written sections
4. **Timestamp everything** - every update should have a date

## Execution Steps

### Phase 1: Read Current State

```bash
# 1. Check Memory Bank exists
echo "=== Checking Memory Bank ==="
if [ ! -d "docs/memory-bank" ]; then
    echo "❌ ERROR: Memory Bank not found. Run /init-memory-bank first"
    exit 1
fi

ls docs/memory-bank/*.md 2>/dev/null

# 2. Read current progress and active context
echo ""
echo "=== Current Progress ==="
cat docs/memory-bank/progress.md 2>/dev/null | head -30

echo ""
echo "=== Active Context ==="
cat docs/memory-bank/activeContext.md 2>/dev/null | head -20
```

### Phase 2: Detect Changes

```bash
# Git-based detection (preferred)
if git rev-parse --git-dir > /dev/null 2>&1; then
    echo ""
    echo "=== Git Status ==="
    git status --porcelain | grep -E "\.(yaml|yml|tpl|json)$"

    echo ""
    echo "=== Recent Commits ==="
    git log --oneline -10 --all

    echo ""
    echo "=== Changed Chart Files (last 5 commits) ==="
    git diff --name-only HEAD~5 2>/dev/null | grep -E "\.(yaml|yml|tpl)$"
fi

# Timestamp-based fallback
echo ""
echo "=== Recently Modified Files ==="
find . -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.tpl" \) -mtime -1 2>/dev/null | grep -v ".git"
```

### Phase 3: Analyze Changes by Category

#### Values Changes
```bash
FOCUS="${ARGUMENTS:-all}"

if [ "$FOCUS" = "values" ] || [ "$FOCUS" = "all" ]; then
    echo ""
    echo "=== Values File Changes ==="

    # Find modified values files
    CHANGED_VALUES=$(git diff --name-only HEAD~5 2>/dev/null | grep "values.*\.yaml$" || find . -name "values*.yaml" -mtime -1)

    for f in $CHANGED_VALUES; do
        echo "📄 $f changed:"
        # Show diff if git available
        git diff HEAD~1 -- "$f" 2>/dev/null | head -30 || echo "   (new file or non-git)"

        # New top-level keys
        echo "   Top-level keys:"
        grep -E "^[a-zA-Z]" "$f" 2>/dev/null | head -15
    done
fi
```

#### Template Changes
```bash
if [ "$FOCUS" = "templates" ] || [ "$FOCUS" = "all" ]; then
    echo ""
    echo "=== Template Changes ==="

    CHANGED_TEMPLATES=$(git diff --name-only HEAD~5 2>/dev/null | grep -E "templates/.*\.(yaml|tpl)$" || find . -path "*/templates/*" -mtime -1)

    for f in $CHANGED_TEMPLATES; do
        echo "📄 $f:"
        # Check for new named templates
        grep "define \"" "$f" 2>/dev/null | sed 's/.*define "\([^"]*\)".*/   🔧 New helper: \1/'

        # Check for new conditionals
        grep -E "if \.Values\.[a-zA-Z]+\.enabled" "$f" 2>/dev/null | head -5 | sed 's/^/   🔀 /'
    done
fi
```

#### Dependency Changes
```bash
if [ "$FOCUS" = "deps" ] || [ "$FOCUS" = "all" ]; then
    echo ""
    echo "=== Dependency Changes ==="

    # Check Chart.yaml changes
    git diff HEAD~5 -- "**/Chart.yaml" 2>/dev/null | grep -E "^\+.*dependencies:|^\+.*name:|^\+.*version:" | head -20

    # Check Chart.lock changes
    for lock in $(find . -name "Chart.lock" 2>/dev/null); do
        echo "🔒 $lock:"
        git diff HEAD~5 -- "$lock" 2>/dev/null | head -15 || echo "   (unchanged)"
    done
fi
```

### Phase 4: Determine Updates Needed

| Change Type | Update Target |
|-------------|---------------|
| New values key | valuesContext.md → Values Hierarchy |
| New template file | templatePatterns.md → Resource Templates |
| New helper function | templatePatterns.md → Named Templates |
| New conditional | valuesContext.md → Feature Flags |
| Dependency added/updated | releaseContext.md → Dependencies |
| Chart version bump | chartbrief.md → Version |
| Any significant work | activeContext.md, progress.md |

### Phase 5: Apply Updates

Based on detected changes, update the appropriate Memory Bank files:

#### Update progress.md
Add to "Recent Changes" section:
```markdown
## Recent Changes
- [TODAY'S DATE]: [Summary of changes detected]
  - Values: [changes to values files]
  - Templates: [new/modified templates]
  - Dependencies: [dependency updates]
```

#### Update activeContext.md
```markdown
## Current Session
- **Date**: [TODAY]
- **Focus**: [Inferred from changes - values refactoring, new feature, etc.]

## Working On
- [Based on recent file changes]

## Recent Decisions
- [If new patterns detected, document them]
```

#### Update valuesContext.md (if values changed)
- Add new top-level keys to Values Hierarchy
- Update Feature Flags table
- Document new defaults

#### Update templatePatterns.md (if templates changed)
- Add new named templates to Helpers table
- Update Resource Templates list
- Document new patterns

#### Update releaseContext.md (if deps changed)
- Update Dependencies table
- Note version changes

### Phase 6: Generate Report

```
═══════════════════════════════════════════════════════════
MEMORY BANK UPDATE COMPLETE
═══════════════════════════════════════════════════════════
Timestamp: [datetime]
Focus: [ARGUMENTS or "all"]

Changes Detected:
  📄 Values files: [count] modified
  📁 Templates: [count] modified
  📦 Chart.yaml: [changed/unchanged]
  🔒 Dependencies: [changed/unchanged]

Updated Files:
  ✓ progress.md - Added [X] items to Recent Changes
  ✓ activeContext.md - Updated session info
  [✓/○] valuesContext.md - [Updated/No changes needed]
  [✓/○] templatePatterns.md - [Updated/No changes needed]
  [✓/○] releaseContext.md - [Updated/No changes needed]

New Items Tracked:
  + [New value key added]
  + [New template added]
  + [New dependency added]

Suggested Actions:
  - Review [file] for accuracy
  - Fill TODO for [item]
  - Run /validate-chart to verify changes
═══════════════════════════════════════════════════════════
```
