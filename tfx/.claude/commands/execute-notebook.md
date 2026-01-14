# Execute Notebook

Run and validate a Jupyter notebook with error detection and output analysis.

## Arguments
- `$ARGUMENTS`: Path to notebook or "all" to run all notebooks

## Execution Steps

### Phase 1: Locate Notebooks

```bash
if [ "$ARGUMENTS" = "all" ]; then
    NOTEBOOKS=$(find . -name "*.ipynb" -not -path "*/.venv/*" -not -path "*checkpoint*" 2>/dev/null)
else
    NOTEBOOKS="$ARGUMENTS"
fi

echo "=== Notebooks to Execute ==="
echo "$NOTEBOOKS"
```

### Phase 2: Pre-execution Checks

For each notebook:

```bash
NOTEBOOK="[notebook path]"

echo "=== Pre-execution Check: $NOTEBOOK ==="

# Check kernel
python3 -c "
import json
with open('$NOTEBOOK') as f:
    nb = json.load(f)
kernel = nb.get('metadata', {}).get('kernelspec', {})
print(f\"Kernel: {kernel.get('display_name', 'unknown')}\")
print(f\"Language: {kernel.get('language', 'unknown')}\")
"

# Check for problematic patterns
echo "Potential issues:"
python3 -c "
import json
with open('$NOTEBOOK') as f:
    nb = json.load(f)

issues = []
for i, cell in enumerate(nb.get('cells', [])):
    if cell.get('cell_type') != 'code':
        continue
    source = ''.join(cell.get('source', []))
    
    # Check for hardcoded paths
    if '/home/' in source or 'C:\\\\' in source:
        issues.append(f'Cell {i}: Hardcoded path detected')
    
    # Check for credentials
    if 'password' in source.lower() or 'api_key' in source.lower():
        issues.append(f'Cell {i}: Possible credentials in code')
    
    # Check for magic commands that might fail
    if '!pip install' in source:
        issues.append(f'Cell {i}: pip install in notebook (may cause issues)')

for issue in issues[:10]:
    print(f'  ⚠ {issue}')
if not issues:
    print('  ✓ No obvious issues found')
"
```

### Phase 3: Execute Notebook

```bash
NOTEBOOK="[notebook path]"
OUTPUT_DIR="$(dirname $NOTEBOOK)"
NOTEBOOK_NAME="$(basename $NOTEBOOK .ipynb)"

echo "=== Executing: $NOTEBOOK ==="

# Execute with timeout and capture output
jupyter nbconvert \
    --to notebook \
    --execute \
    --inplace \
    --ExecutePreprocessor.timeout=600 \
    --ExecutePreprocessor.kernel_name=python3 \
    "$NOTEBOOK" 2>&1 | tee "/tmp/notebook_exec_${NOTEBOOK_NAME}.log"

EXEC_STATUS=$?

if [ $EXEC_STATUS -eq 0 ]; then
    echo "✓ Execution successful"
else
    echo "✗ Execution failed (exit code: $EXEC_STATUS)"
fi
```

### Phase 4: Analyze Results

```python
"""
Analyze notebook execution results
"""
import json
import sys

def analyze_notebook(path):
    with open(path) as f:
        nb = json.load(f)
    
    results = {
        'total_cells': 0,
        'code_cells': 0,
        'executed_cells': 0,
        'error_cells': [],
        'warnings': [],
        'outputs_summary': []
    }
    
    for i, cell in enumerate(nb.get('cells', [])):
        results['total_cells'] += 1
        
        if cell.get('cell_type') != 'code':
            continue
        
        results['code_cells'] += 1
        
        # Check execution count
        if cell.get('execution_count') is not None:
            results['executed_cells'] += 1
        
        # Check outputs for errors
        for output in cell.get('outputs', []):
            if output.get('output_type') == 'error':
                results['error_cells'].append({
                    'cell': i,
                    'ename': output.get('ename'),
                    'evalue': output.get('evalue', '')[:100]
                })
            
            # Check for warnings in stream output
            if output.get('output_type') == 'stream':
                text = ''.join(output.get('text', []))
                if 'warning' in text.lower():
                    results['warnings'].append(f'Cell {i}: Warning in output')
    
    return results

if __name__ == "__main__":
    results = analyze_notebook(sys.argv[1])
    
    print(f"Cells: {results['executed_cells']}/{results['code_cells']} executed")
    
    if results['error_cells']:
        print("\\nErrors found:")
        for err in results['error_cells']:
            print(f"  Cell {err['cell']}: {err['ename']}: {err['evalue']}")
    
    if results['warnings']:
        print("\\nWarnings:")
        for warn in results['warnings'][:5]:
            print(f"  {warn}")
```

### Phase 5: Output Validation

```bash
# Check output sizes
python3 -c "
import json
import sys

with open('$NOTEBOOK') as f:
    nb = json.load(f)

large_outputs = []
for i, cell in enumerate(nb.get('cells', [])):
    for output in cell.get('outputs', []):
        output_str = json.dumps(output)
        if len(output_str) > 100000:  # 100KB
            large_outputs.append((i, len(output_str)))

if large_outputs:
    print('⚠ Large outputs detected (consider clearing before commit):')
    for cell, size in large_outputs:
        print(f'  Cell {cell}: {size/1024:.1f}KB')
else:
    print('✓ No oversized outputs')
"
```

### Phase 6: Generate HTML Report (Optional)

```bash
# Create HTML version for easy viewing
jupyter nbconvert \
    --to html \
    --no-input \
    --output "${NOTEBOOK_NAME}_output.html" \
    "$NOTEBOOK" 2>/dev/null

echo "HTML report: ${OUTPUT_DIR}/${NOTEBOOK_NAME}_output.html"
```

### Output Report

```
═══════════════════════════════════════════════════════════
NOTEBOOK EXECUTION REPORT
═══════════════════════════════════════════════════════════

Notebook: [path]
Status: [SUCCESS/FAILED/PARTIAL]

Execution Summary:
  Total cells: [count]
  Code cells: [count]
  Executed: [count]
  Errors: [count]

[If errors]
Errors:
  Cell [N]: [ErrorType]
    [Error message excerpt]
  
  Suggested fixes:
    - [Based on error type]

[If warnings]
Warnings:
  - [Warning summary]

Output Analysis:
  ✓ All outputs reasonable size
  OR
  ⚠ Large outputs in cells: [list]

Execution Time: [duration]

[If successful]
Key Outputs:
  - [Summary of final outputs/visualizations]

Recommendations:
  1. [Based on analysis]
═══════════════════════════════════════════════════════════
```