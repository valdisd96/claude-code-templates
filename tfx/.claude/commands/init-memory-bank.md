# Initialize Memory Bank for Current Project

Analyze the current project structure and generate a comprehensive Memory Bank documentation system.

## Critical Rules

1. **Always run discovery commands FIRST** before generating any files
2. **Never hallucinate** - only document what is actually found in code
3. **Mark unknowns as `[TODO]`** - don't guess at business context
4. **Preserve existing docs** - if Memory Bank exists, merge don't overwrite

## Execution Steps

### Phase 1: Project Discovery

Run these commands and collect results:

```bash
# 1. Directory structure
find . -maxdepth 4 -type f \( -name "*.py" -o -name "*.ipynb" -o -name "*.yaml" -o -name "*.json" \) 2>/dev/null | grep -v __pycache__ | grep -v .venv | sort

# 2. Dependencies detection
cat requirements.txt 2>/dev/null; cat pyproject.toml 2>/dev/null; cat setup.py 2>/dev/null; cat environment.yml 2>/dev/null

# 3. TFX/TFT specific detection
grep -r "tfx\|tensorflow_transform\|apache_beam\|tft\." --include="*.py" -l 2>/dev/null

# 4. Existing documentation
find . -maxdepth 2 \( -name "README*" -o -name "*.md" \) -type f 2>/dev/null
```

### Phase 2: Deep Code Analysis

```bash
# 1. Find all Python classes and main functions
grep -r "^class \|^def \|^async def " --include="*.py" 2>/dev/null | grep -v test | head -80

# 2. TFX Components
grep -r "ExampleGen\|StatisticsGen\|SchemaGen\|Transform\|Trainer\|Evaluator\|Pusher\|@component" --include="*.py" 2>/dev/null

# 3. Preprocessing functions (critical for TFT)
grep -r "def preprocessing_fn\|preprocessing_fn\s*=" --include="*.py" -A 30 2>/dev/null

# 4. Schema definitions
grep -r "feature_spec\|schema_utils\|FeatureSpec\|Schema(" --include="*.py" 2>/dev/null

# 5. Pipeline definitions
grep -r "Pipeline(\|create_pipeline\|def.*pipeline" --include="*.py" -B 2 -A 10 2>/dev/null

# 6. TODO/FIXME comments (known issues)
grep -r "TODO\|FIXME\|HACK\|XXX" --include="*.py" 2>/dev/null | head -30

# 7. Notebook analysis
for nb in $(find . -name "*.ipynb" -not -path "*/.venv/*" 2>/dev/null); do
  echo "=== $nb ==="
  python3 -c "import json; nb=json.load(open('$nb')); print('Cells:', len(nb.get('cells',[]))); [print(c['source'][0][:80] if c.get('source') else '') for c in nb.get('cells',[])[:5] if c.get('cell_type')=='markdown']" 2>/dev/null
done
```

### Phase 3: Analysis Synthesis

Based on collected data, determine:

| Aspect | How to Detect |
|--------|---------------|
| Project Type | TFX imports → "TFX Pipeline", notebooks only → "Notebook Collection", mixed → "ML Project" |
| Pipeline Runner | Look for `DirectRunner`, `DataflowRunner`, `BeamDagRunner` |
| Data Sources | Look for `CsvExampleGen`, `BigQueryExampleGen`, file paths |
| Model Type | Look for `Trainer`, keras/tf model definitions |
| Deployment Target | Look for `Pusher`, serving configs |

### Phase 4: Generate Memory Bank

Create `docs/memory-bank/` directory and generate files:

#### projectbrief.md
```markdown
# Project Brief

## Overview
<!-- Generated from README or code analysis -->
[DISCOVERED: description] OR [TODO: Add project description]

## Core Requirements
<!-- Inferred from code structure -->
- [Requirement based on components found]

## Project Scope
<!-- Based on directory/module analysis -->
- Pipelines: [count found]
- Components: [list]
- Notebooks: [count]

## Key Stakeholders
[TODO: Add stakeholder information]

## Success Criteria
[TODO: Define success metrics]
```

#### productContext.md
```markdown
# Product Context

## Problem Being Solved
<!-- Extract from README, docstrings, notebook markdown -->
[DISCOVERED: ...] OR [TODO: Describe the problem]

## Target Users
[TODO: Define target users]

## How It Works
<!-- High-level flow from code analysis -->
1. Data ingestion: [detected source]
2. Processing: [detected transformations]
3. Output: [detected destination]

## Integration Points
<!-- Detected external systems -->
- [System]: [how detected]
```

#### systemPatterns.md
```markdown
# System Patterns

## Architecture Overview
<!-- Generated from directory + import analysis -->

```
[ASCII diagram based on discovered structure]
```

## TFX Pipeline Structure
<!-- Only if TFX detected -->
### Components
| Component | Module | Purpose |
|-----------|--------|---------|
| [Name] | [file.py] | [inferred] |

### Data Flow
[ExampleGen] → [StatisticsGen] → [SchemaGen] → [Transform] → [Trainer] → ...

## Preprocessing Patterns
<!-- From preprocessing_fn analysis -->
### Feature Transformations
| Feature | Transformation | TFT Function |
|---------|---------------|--------------|
| [name] | [type] | [tft.xxx] |

## Key Design Decisions
<!-- From code comments, patterns -->
- [Decision]: [evidence from code]

## Code Patterns Used
- [Pattern]: [where found]
```

#### techContext.md
```markdown
# Technical Context

## Technology Stack
- **Python**: [version from pyproject/setup]
- **TensorFlow**: [version]
- **TFX**: [version]
- **Beam**: [version]
- **Other**: [list]

## Environment Setup
```bash
# Detected setup method
[pip/conda commands based on found files]
```

## Project Structure
```
[Generated tree of key directories]
```

## Configuration Files
| File | Purpose |
|------|---------|
| [file] | [purpose] |

## Infrastructure
- Runner: [detected]
- Storage: [detected]
- Deployment: [detected]
```

#### progress.md
```markdown
# Progress Tracker

## What Works
<!-- Inferred from test files, stable modules -->
- [Feature]: [evidence]

## In Progress
<!-- Initially from TODO comments -->
- [Item from TODO/FIXME]

## Known Issues
<!-- From code comments -->
- [ ] [Issue from FIXME]
- [ ] [Issue from TODO]

## Backlog
[TODO: Add planned work]

## Recent Changes
<!-- Template for updates -->
- [Date]: Initial Memory Bank creation
```

#### activeContext.md
```markdown
# Active Context

## Current Session
- **Date**: [today]
- **Focus**: Initial project analysis

## Working On
[To be updated each session]

## Recent Decisions
[To be updated as decisions are made]

## Open Questions
- [Questions discovered during analysis]

## Next Session
[To be updated at session end]
```

### Phase 5: Verification & Report

```bash
# Verify created files
ls -la docs/memory-bank/
wc -l docs/memory-bank/*.md
```

Output summary:
```
═══════════════════════════════════════════════════════════
MEMORY BANK INITIALIZATION COMPLETE
═══════════════════════════════════════════════════════════

Project Analysis:
  Type: [detected]
  TFX Components: [count]
  Notebooks: [count]
  Python Modules: [count]

Created Files:
  ✓ projectbrief.md      [X lines, Y TODOs]
  ✓ productContext.md    [X lines, Y TODOs]
  ✓ systemPatterns.md    [X lines, Y TODOs]
  ✓ techContext.md       [X lines, Y TODOs]
  ✓ progress.md          [X lines, Y TODOs]
  ✓ activeContext.md     [X lines, Y TODOs]

Discovered vs TODO:
  ✓ Discovered: [list items found in code]
  ○ Needs Input: [list TODO items requiring human]

Recommended Next Steps:
  1. Review systemPatterns.md for accuracy
  2. Fill TODOs in projectbrief.md
  3. Verify techContext.md setup instructions
  4. Run /analyze-tfx for deeper pipeline analysis
═══════════════════════════════════════════════════════════
```
