# Update Memory Bank

Analyze recent changes in the project and update Memory Bank documentation accordingly.

## Arguments
- `$ARGUMENTS`: Optional - specific focus area: "pipelines", "notebooks", "deps", "all" (default: "all")

## Critical Rules

1. **Read before write** - always read existing Memory Bank files first
2. **Incremental updates** - append/modify, don't regenerate from scratch
3. **Preserve manual edits** - don't overwrite human-written sections
4. **Timestamp everything** - every update should have a date

## Execution Steps

### Phase 1: Read Current State

```bash
# 1. Check Memory Bank exists
ls docs/memory-bank/*.md 2>/dev/null || echo "ERROR: Run /init-memory-bank first"

# 2. Read current progress
cat docs/memory-bank/progress.md 2>/dev/null
cat docs/memory-bank/activeContext.md 2>/dev/null
```

### Phase 2: Detect Changes

```bash
# Git-based detection (preferred)
if git rev-parse --git-dir > /dev/null 2>&1; then
    echo "=== Git Changes ==="
    git status --porcelain
    echo "=== Recent Commits ==="
    git log --oneline -10
    echo "=== Changed Files (last 5 commits) ==="
    git diff --name-only HEAD~5 2>/dev/null
fi

# Timestamp-based fallback
echo "=== Recently Modified Files ==="
find . -type f \( -name "*.py" -o -name "*.ipynb" \) -mtime -1 -not -path "*/.venv/*" 2>/dev/null
```

### Phase 3: Analyze Changes by Category

#### Python Modules Changed
```bash
# Find modified Python files
CHANGED_PY=$(git diff --name-only HEAD~5 2>/dev/null | grep "\.py$" || find . -name "*.py" -mtime -1)

for f in $CHANGED_PY; do
    echo "=== $f ==="
    # New classes/functions
    grep "^class \|^def " "$f" 2>/dev/null | head -10
    # New TODOs
    grep -n "TODO\|FIXME" "$f" 2>/dev/null
done
```

#### TFX Components Changed
```bash
# Check for pipeline changes
git diff HEAD~5 --name-only 2>/dev/null | xargs grep -l "Pipeline\|@component\|preprocessing_fn" 2>/dev/null
```

#### Dependencies Changed
```bash
# Check requirements changes
git diff HEAD~5 -- requirements.txt pyproject.toml setup.py 2>/dev/null
```

#### Notebooks Changed
```bash
# Find modified notebooks
find . -name "*.ipynb" -mtime -1 -not -path "*/.venv/*" 2>/dev/null
```

### Phase 4: Determine Updates Needed

| Change Type | Update Target |
|-------------|---------------|
| New Python module | systemPatterns.md → Components |
| New TFX component | systemPatterns.md → Pipeline |
| New preprocessing logic | systemPatterns.md → Transformations |
| New dependency | techContext.md → Stack |
| New notebook | systemPatterns.md → Notebooks |
| TODO/FIXME added | progress.md → Known Issues |
| TODO/FIXME resolved | progress.md → What Works |
| Any significant work | activeContext.md, progress.md |

### Phase 5: Apply Updates

For each affected file, use this pattern:

```markdown
# Reading [filename]...
# Finding section to update...
# Appending/modifying content...
```

#### Update progress.md
Add to "Recent Changes" section:
```markdown
## Recent Changes
- [TODAY'S DATE]: [Summary of changes detected]
  - [Specific change 1]
  - [Specific change 2]
```

Move items between sections if:
- Code now has tests → move from "In Progress" to "What Works"
- New TODO found → add to "Known Issues"
- Issue fixed → move from "Known Issues" to "What Works"

#### Update activeContext.md
Replace/update current session info:
```markdown
## Current Session
- **Date**: [TODAY]
- **Focus**: [Inferred from recent changes]

## Working On
- [Based on recent file changes]

## Recent Decisions
- [If architectural changes detected]
```

#### Update systemPatterns.md (if architecture changed)
Only update if:
- New components added
- New preprocessing patterns
- Pipeline structure changed

#### Update techContext.md (if deps changed)
Only update if:
- requirements.txt changed
- New imports detected

### Phase 6: Generate Report

```
═══════════════════════════════════════════════════════════
MEMORY BANK UPDATE COMPLETE
═══════════════════════════════════════════════════════════
Timestamp: [datetime]

Changes Detected:
  Python files: [count] modified
  Notebooks: [count] modified
  Dependencies: [changed/unchanged]
  Pipeline: [changed/unchanged]

Updated Files:
  ✓ progress.md - Added [X] items to Recent Changes
  ✓ activeContext.md - Updated session info
  [✓/○] systemPatterns.md - [Updated/No changes needed]
  [✓/○] techContext.md - [Updated/No changes needed]

New Items Tracked:
  + [New feature/component added]
  + [New TODO discovered]

Resolved Items:
  ✓ [Item moved to completed]

Suggested Actions:
  - [Any manual review needed]
═══════════════════════════════════════════════════════════
```
