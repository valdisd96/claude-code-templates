# Test TFX Pipeline

Run TFX pipeline tests with detailed output and failure analysis.

## Arguments
- `$ARGUMENTS`: Optional - specific test path, test name pattern, or "all" (default: all)

## Execution Steps

### Phase 1: Discover Test Files

```bash
echo "=== Test Discovery ==="

# Find all test files
find . -name "test_*.py" -o -name "*_test.py" | grep -v __pycache__ | grep -v .venv

# Find pipeline-specific tests
echo "=== Pipeline Tests ==="
find . -path "*test*" -name "*.py" | xargs grep -l "Pipeline\|preprocessing_fn\|Transform\|Trainer" 2>/dev/null

# Check test configuration
echo "=== Test Configuration ==="
cat pytest.ini 2>/dev/null || cat setup.cfg 2>/dev/null | grep -A 20 "\[tool:pytest\]" || cat pyproject.toml 2>/dev/null | grep -A 20 "\[tool.pytest"
```

### Phase 2: Environment Verification

```bash
echo "=== Test Environment ==="

# Check pytest is available
python -m pytest --version

# Check TFX test utilities
python -c "import tfx; print(f'TFX: {tfx.__version__}')"
python -c "import tensorflow as tf; print(f'TF: {tf.__version__}')"

# Check for test fixtures
echo "=== Test Fixtures ==="
grep -r "@pytest.fixture\|@fixture" --include="*.py" -l 2>/dev/null | head -10

# Check for conftest.py
find . -name "conftest.py" -not -path "*/.venv/*" 2>/dev/null
```

### Phase 3: Run Tests

Based on `$ARGUMENTS`:

#### All Tests (default)
```bash
python -m pytest tests/ -v --tb=long -x 2>&1 | tee /tmp/pytest_output.log
```

#### Pipeline Tests Only
```bash
python -m pytest tests/pipeline/ -v --tb=long 2>&1 | tee /tmp/pytest_output.log
```

#### Specific Test Pattern
```bash
python -m pytest -v --tb=long -k "$ARGUMENTS" 2>&1 | tee /tmp/pytest_output.log
```

### Phase 4: Analyze Failures

If tests fail, perform deeper analysis:

```python
"""
Analyze pytest output for common TFX issues
"""
import re
import sys

def analyze_test_failures(log_path):
    with open(log_path) as f:
        content = f.read()

    failures = []

    # Extract failure blocks
    failure_pattern = r'FAILED (.*?) - (.*?)(?=\n(?:FAILED|PASSED|=====|$))'
    for match in re.finditer(failure_pattern, content, re.DOTALL):
        test_name = match.group(1)
        error_text = match.group(2)

        failure = {
            'test': test_name,
            'error': error_text[:200],
            'category': categorize_error(error_text)
        }
        failures.append(failure)

    return failures

def categorize_error(error_text):
    """Categorize TFX test errors."""
    if 'Schema' in error_text or 'schema' in error_text:
        return 'schema_error'
    elif 'preprocessing_fn' in error_text or 'tft.' in error_text:
        return 'transform_error'
    elif 'shape' in error_text or 'dtype' in error_text:
        return 'tensor_error'
    elif 'ImportError' in error_text or 'ModuleNotFound' in error_text:
        return 'import_error'
    elif 'Artifact' in error_text or 'artifact' in error_text:
        return 'artifact_error'
    else:
        return 'unknown'

if __name__ == "__main__":
    failures = analyze_test_failures('/tmp/pytest_output.log')
    for f in failures:
        print(f"[{f['category']}] {f['test']}")
        print(f"  {f['error'][:100]}...")
```

### Phase 5: TFX-Specific Checks

```bash
echo "=== TFX Test Patterns Check ==="

# Check for proper TFX test patterns
echo "Testing patterns used:"
grep -r "InteractiveContext\|TfxRunner\|LocalDagRunner" --include="test_*.py" 2>/dev/null | head -10

# Check for schema test utilities
echo "Schema testing:"
grep -r "tfdv.validate_statistics\|schema_utils" --include="test_*.py" 2>/dev/null | head -10

# Check for transform test utilities
echo "Transform testing:"
grep -r "tft_unit\|tft.TFTransformOutput" --include="test_*.py" 2>/dev/null | head -10
```

### Phase 6: Coverage Report (Optional)

```bash
# Run with coverage if available
if python -c "import pytest_cov" 2>/dev/null; then
    echo "=== Running with Coverage ==="
    python -m pytest tests/ -v --cov=src --cov-report=term-missing --tb=short
fi
```

### Common TFX Test Issues

| Issue | Symptom | Solution |
|-------|---------|----------|
| Schema mismatch | `ValueError: Feature X not found` | Regenerate schema or update test fixtures |
| Transform graph | `tensorflow.python.framework.errors_impl.NotFoundError` | Ensure Transform artifacts exist |
| Beam serialization | `PicklingError` | Avoid lambdas, use named functions |
| TF version | `AttributeError: module 'tensorflow'` | Check TF/TFX version compatibility |
| Artifact paths | `FileNotFoundError` | Use `tempfile` for test artifacts |

### Output Report

```
═══════════════════════════════════════════════════════════
TFX PIPELINE TEST REPORT
═══════════════════════════════════════════════════════════

Test Run: [timestamp]
Arguments: [provided args or "all"]

Summary:
  Total tests: [count]
  Passed: [count] ✓
  Failed: [count] ✗
  Skipped: [count] ○

Duration: [time]

[If failures]
Failed Tests by Category:

  Schema Errors ([count]):
    - test_name: [brief error]

  Transform Errors ([count]):
    - test_name: [brief error]

  Other Errors ([count]):
    - test_name: [brief error]

Suggested Fixes:
  1. [Based on error analysis]
  2. [Based on error analysis]

[If all passed]
✓ All tests passed!

Coverage: [if available]
  Overall: [percentage]
  Missing: [files with low coverage]

Next Steps:
  - [Recommendation based on results]
═══════════════════════════════════════════════════════════
```
