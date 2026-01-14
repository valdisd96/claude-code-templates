# Analyze and Document Jupyter Notebooks

Analyze Jupyter notebooks in the project, validate them, and update documentation.

## Arguments
- `$ARGUMENTS`: Optional - specific notebook path or "all" (default: all)

## Execution Steps

### Phase 1: Discover Notebooks

1. **Find all notebooks**:
   ```bash
   find . -name "*.ipynb" -not -path "./.venv/*" -not -path "./venv/*" -not -path "./*checkpoint*"
   ```

2. **Categorize by purpose** (infer from path/name):
   - `notebooks/exploration/` → EDA notebooks
   - `notebooks/training/` → Model training
   - `notebooks/evaluation/` → Model evaluation
   - `notebooks/pipelines/` → Pipeline development

### Phase 2: Analyze Each Notebook

For each notebook:

1. **Extract metadata**:
   ```bash
   jq '.metadata.kernelspec.display_name, .metadata.kernelspec.language' notebook.ipynb
   ```

2. **Analyze structure**:
   ```python
   import json
   with open('notebook.ipynb') as f:
       nb = json.load(f)
   
   stats = {
       'total_cells': len(nb['cells']),
       'code_cells': len([c for c in nb['cells'] if c['cell_type'] == 'code']),
       'markdown_cells': len([c for c in nb['cells'] if c['cell_type'] == 'markdown']),
       'has_outputs': any(c.get('outputs') for c in nb['cells'] if c['cell_type'] == 'code')
   }
   ```

3. **Extract key information**:
   - Imports used
   - Functions defined
   - Data sources accessed
   - Models trained/evaluated
   - Visualizations created

4. **Check for issues**:
   - Large outputs committed (images, dataframes)
   - Hardcoded paths
   - Missing documentation
   - Out-of-order execution risk
   - Unused imports

### Phase 3: Validate Notebooks

1. **Syntax validation**:
   ```bash
   python -m py_compile <(jq -r '.cells[] | select(.cell_type=="code") | .source | join("")' notebook.ipynb)
   ```

2. **Optional execution test** (if requested):
   ```bash
   jupyter nbconvert --execute --to notebook --inplace --ExecutePreprocessor.timeout=300 notebook.ipynb
   ```

3. **Check kernel availability**:
   ```bash
   jupyter kernelspec list
   ```

### Phase 4: Generate Notebook Documentation

Create/update `docs/memory-bank/notebooks.md`:

```markdown
# Jupyter Notebooks Documentation

## Overview
- Total notebooks: [count]
- Categories: [list]
- Last analyzed: [timestamp]

## Notebook Catalog

### Exploration Notebooks

#### [notebook_name.ipynb]
- **Purpose**: [inferred from markdown/code]
- **Key operations**: 
  - [operation 1]
  - [operation 2]
- **Data sources**: [list]
- **Outputs**: [descriptions]
- **Dependencies**: [key imports]
- **Status**: [clean/has-issues]

### Training Notebooks
[Similar structure]

### Evaluation Notebooks
[Similar structure]

## Cross-Notebook Dependencies
- [notebook A] → [notebook B]: [relationship]

## Common Patterns Identified
1. [Pattern]: Used in [notebooks]

## Issues Found

| Notebook | Issue | Severity | Recommendation |
|----------|-------|----------|----------------|
| [name] | [issue] | [high/med/low] | [fix] |

## Best Practices Checklist
- [ ] All notebooks have markdown headers
- [ ] No large outputs committed
- [ ] Consistent kernel usage
- [ ] No hardcoded paths
- [ ] Clear execution order
```

### Phase 5: Generate Individual Notebook Headers

For notebooks missing documentation, suggest header template:

```markdown
# [Notebook Title]

## Purpose
[What this notebook does]

## Prerequisites
- Data: [required data files]
- Models: [required pretrained models]
- Environment: [specific requirements]

## Usage
1. [Step 1]
2. [Step 2]

## Outputs
- [Output 1]: [description]
```

### Phase 6: Output Report

```
=== Notebook Analysis Complete ===

Analyzed: [count] notebooks

Summary by category:
  - Exploration: [count]
  - Training: [count]
  - Evaluation: [count]
  - Other: [count]

Health status:
  ✓ Clean: [count]
  ⚠ Issues: [count]
  ✗ Critical: [count]

Documentation:
  ✓ Updated docs/memory-bank/notebooks.md
  
Top issues:
  1. [Issue affecting most notebooks]
  2. [Second most common issue]

Recommendations:
  - [Actionable recommendation]
```
