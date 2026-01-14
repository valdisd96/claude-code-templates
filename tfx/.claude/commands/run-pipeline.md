# Run TFX Pipeline

Execute TFX pipeline locally with debugging options.

## Arguments
- `$ARGUMENTS`: Options - "debug", "dry-run", "full", or path to pipeline module

## Execution Steps

### Phase 1: Locate Pipeline

```bash
# Find pipeline definitions
echo "=== Pipeline Files ==="
grep -r "def create_pipeline\|def get_pipeline\|Pipeline(" --include="*.py" -l 2>/dev/null

# Find pipeline runner scripts
find . -name "*pipeline*.py" -o -name "*runner*.py" -o -name "main.py" | head -10
```

### Phase 2: Verify Environment

```bash
echo "=== Environment Check ==="

# Python version
python --version

# Key packages
pip list 2>/dev/null | grep -E "tfx|tensorflow|apache-beam" || \
conda list 2>/dev/null | grep -E "tfx|tensorflow|apache-beam"

# Check TFX version compatibility
python -c "import tfx; print(f'TFX: {tfx.__version__}')"
python -c "import tensorflow as tf; print(f'TF: {tf.__version__}')"
```

### Phase 3: Validate Pipeline Configuration

```bash
# Find and display pipeline config
echo "=== Pipeline Configuration ==="

# Look for config files
find . -name "*config*.py" -o -name "*config*.yaml" -o -name "*config*.json" | head -5

# Extract pipeline parameters
grep -r "pipeline_name\|pipeline_root\|data_root\|module_file" --include="*.py" | head -20
```

### Phase 4: Pre-run Checks

```python
# Validation script
"""
Pre-run pipeline validation
"""
import sys
import importlib.util

def validate_pipeline_module(module_path):
    """Validate pipeline module before running."""
    
    # Load module
    spec = importlib.util.spec_from_file_location("pipeline", module_path)
    module = importlib.util.module_from_spec(spec)
    
    try:
        spec.loader.exec_module(module)
    except Exception as e:
        print(f"ERROR: Failed to load pipeline module: {e}")
        return False
    
    # Check for required functions
    required = ['create_pipeline', 'get_pipeline']
    found = [f for f in required if hasattr(module, f)]
    
    if not found:
        print(f"ERROR: No pipeline factory function found. Expected one of: {required}")
        return False
    
    print(f"✓ Found pipeline function: {found[0]}")
    return True

if __name__ == "__main__":
    if len(sys.argv) > 1:
        validate_pipeline_module(sys.argv[1])
```

### Phase 5: Execute Pipeline

Based on `$ARGUMENTS`:

#### Debug Mode (`debug`)
```bash
# Run with minimal parallelism for easier debugging
export TF_CPP_MIN_LOG_LEVEL=0  # Full logging
export BEAM_DEBUG=1

python -m [pipeline_module] \
    --runner=DirectRunner \
    --direct_num_workers=1 \
    --direct_running_mode=in_memory
```

#### Dry Run (`dry-run`)
```bash
# Validate without executing
python -c "
from [pipeline_module] import create_pipeline
pipeline = create_pipeline()
print('Pipeline components:')
for component in pipeline.components:
    print(f'  - {component.id}')
print(f'Total components: {len(pipeline.components)}')
"
```

#### Full Run (`full`)
```bash
# Normal execution
python -m [pipeline_module] \
    --runner=DirectRunner \
    --direct_num_workers=4
```

### Phase 6: Monitor Execution

```bash
# Watch for common errors during execution

# Memory monitoring
watch -n 5 'ps aux | grep python | head -5'

# Check artifacts being created
watch -n 10 'find . -path "*/pipeline_root/*" -type f -newer /tmp/pipeline_start 2>/dev/null | wc -l'
```

### Phase 7: Post-run Analysis

```bash
# Check execution results
echo "=== Pipeline Artifacts ==="
find . -path "*/pipeline_root/*" -type d | head -20

echo "=== Component Outputs ==="
for component in Transform Trainer Evaluator; do
    echo "--- $component ---"
    find . -path "*/$component/*" -type f | head -5
done

# Check for errors in logs
echo "=== Error Check ==="
find . -name "*.log" -newer /tmp/pipeline_start 2>/dev/null | xargs grep -l "ERROR\|Exception" 2>/dev/null
```

### Error Recovery

If pipeline fails, check:

| Error Type | Check | Solution |
|------------|-------|----------|
| Schema mismatch | `tfdv.validate_statistics()` | Regenerate schema |
| Transform OOM | Memory usage | Reduce workers, add `top_k` |
| Missing module | Import errors | Check PYTHONPATH |
| Artifact not found | Pipeline order | Check component dependencies |

### Output Report

```
═══════════════════════════════════════════════════════════
PIPELINE EXECUTION REPORT
═══════════════════════════════════════════════════════════

Pipeline: [name]
Mode: [debug/dry-run/full]
Status: [SUCCESS/FAILED]

Execution Time: [duration]

Components Executed:
  ✓ ExampleGen      [time]
  ✓ StatisticsGen   [time]
  ✓ SchemaGen       [time]
  ✓ Transform       [time]
  ✓ Trainer         [time]
  [✓/✗] Evaluator   [time/error]
  [✓/✗] Pusher      [time/error]

Artifacts Created:
  - [artifact path]: [size]

[If failed]
Error Summary:
  Component: [failed component]
  Error: [error message]
  
Suggested Fix:
  [Based on error analysis]

Next Steps:
  1. [Recommendation]
═══════════════════════════════════════════════════════════
```