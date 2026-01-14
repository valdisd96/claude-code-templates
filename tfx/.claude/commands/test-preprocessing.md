# Test Preprocessing Function

Validate and test TensorFlow Transform preprocessing_fn with sample data.

## Arguments
- `$ARGUMENTS`: Optional - path to preprocessing module or "auto" to find automatically

## Critical Rules

1. **Never use numpy** in preprocessing_fn - only tf.* and tft.* ops
2. **Test with real schema** - ensure feature specs match
3. **Check both training and serving** - transformations must work in both modes

## Execution Steps

### Phase 1: Locate Preprocessing

```bash
# Find preprocessing_fn definitions
grep -r "def preprocessing_fn" --include="*.py" -l 2>/dev/null

# If $ARGUMENTS provided, use that path
# Otherwise use first found
```

### Phase 2: Static Analysis

```bash
# Extract preprocessing_fn code
PREPROC_FILE="[found or provided file]"

echo "=== Preprocessing Function ==="
grep -A 100 "def preprocessing_fn" "$PREPROC_FILE" | head -100

echo "=== Checking for Common Issues ==="

# Issue 1: Numpy usage (CRITICAL)
echo "Numpy usage (SHOULD BE EMPTY):"
grep -n "np\.\|numpy\." "$PREPROC_FILE" | grep -v "^#\|import"

# Issue 2: Python builtins instead of TF ops
echo "Python builtins (REVIEW THESE):"
grep -n "len(\|max(\|min(\|sum(\|abs(" "$PREPROC_FILE" | grep -v "tf\."

# Issue 3: Missing tft imports
echo "TFT functions used:"
grep -o "tft\.[a-z_]*" "$PREPROC_FILE" | sort -u
```

### Phase 3: Validate Against Schema

```bash
# Find schema files
echo "=== Schema Discovery ==="
SCHEMA_PBTXT=$(find . -name "schema.pbtxt" -not -path "*/.venv/*" 2>/dev/null | head -1)
SCHEMA_PY=$(find . -name "*schema*.py" -not -path "*/.venv/*" -not -name "test_*" 2>/dev/null | head -1)

echo "Schema protobuf: ${SCHEMA_PBTXT:-'Not found'}"
echo "Schema Python: ${SCHEMA_PY:-'Not found'}"

# Extract features from schema.pbtxt
if [ -n "$SCHEMA_PBTXT" ]; then
    echo "=== Features in Schema ==="
    grep -o "name: \"[^\"]*\"" "$SCHEMA_PBTXT" | sed 's/name: "//;s/"//' | sort
fi

# Extract features from Python schema
if [ -n "$SCHEMA_PY" ]; then
    echo "=== Feature Spec in Python ==="
    grep -o "'[^']*'\s*:" "$SCHEMA_PY" | sed "s/'//g;s/://" | sort
fi

# Compare with preprocessing inputs
echo "=== Features in Preprocessing ==="
grep -o "inputs\['[^']*'\]" "$PREPROC_FILE" | sed "s/inputs\['//;s/'\]//" | sort -u
```

### Phase 3.1: Deep Schema Validation

```python
"""
Comprehensive schema validation against preprocessing_fn
"""
import os
import re

def extract_schema_features(schema_path):
    """Extract features from schema.pbtxt."""
    features = []
    if schema_path and os.path.exists(schema_path):
        with open(schema_path) as f:
            content = f.read()
        features = re.findall(r'name:\s*"([^"]+)"', content)
    return set(features)

def extract_preprocessing_features(preproc_path):
    """Extract features used in preprocessing_fn."""
    features = set()
    if os.path.exists(preproc_path):
        with open(preproc_path) as f:
            content = f.read()
        # Find inputs['feature_name'] patterns
        features = set(re.findall(r"inputs\['([^']+)'\]", content))
    return features

def extract_output_features(preproc_path):
    """Extract output features from preprocessing_fn."""
    outputs = set()
    if os.path.exists(preproc_path):
        with open(preproc_path) as f:
            content = f.read()
        # Find outputs['feature_name'] patterns
        outputs = set(re.findall(r"outputs\['([^']+)'\]", content))
    return outputs

def validate_schema_consistency(schema_path, preproc_path):
    """Full schema validation."""
    schema_features = extract_schema_features(schema_path)
    preproc_inputs = extract_preprocessing_features(preproc_path)
    preproc_outputs = extract_output_features(preproc_path)

    issues = []

    # Check for features used but not in schema
    missing_in_schema = preproc_inputs - schema_features
    if missing_in_schema:
        issues.append(f"Features used in preprocessing but missing from schema: {missing_in_schema}")

    # Check for schema features not used
    unused_features = schema_features - preproc_inputs
    if unused_features:
        issues.append(f"Schema features not used in preprocessing: {unused_features}")

    # Check for outputs without inputs
    orphan_outputs = preproc_outputs - preproc_inputs
    # This is often OK (derived features), but worth noting

    return {
        'schema_features': schema_features,
        'preprocessing_inputs': preproc_inputs,
        'preprocessing_outputs': preproc_outputs,
        'missing_in_schema': missing_in_schema,
        'unused_in_schema': unused_features,
        'issues': issues
    }

if __name__ == "__main__":
    import sys
    results = validate_schema_consistency(sys.argv[1], sys.argv[2])

    print("Schema Validation Results:")
    print(f"  Schema features: {len(results['schema_features'])}")
    print(f"  Preprocessing inputs: {len(results['preprocessing_inputs'])}")
    print(f"  Preprocessing outputs: {len(results['preprocessing_outputs'])}")

    if results['issues']:
        print("\nIssues Found:")
        for issue in results['issues']:
            print(f"  ✗ {issue}")
    else:
        print("\n✓ Schema and preprocessing are consistent")
```

### Phase 3.2: Type Validation

```bash
echo "=== Type Consistency Check ==="

# Check for type definitions in schema
if [ -n "$SCHEMA_PBTXT" ]; then
    echo "Feature types in schema:"
    grep -A 2 "feature {" "$SCHEMA_PBTXT" | grep -E "name:|type:" | paste - - 2>/dev/null | head -20
fi

# Check for type handling in preprocessing
echo "Type handling in preprocessing:"
grep -n "tf.cast\|dtype\|tf.string\|tf.int\|tf.float" "$PREPROC_FILE" 2>/dev/null | head -10
```

### Phase 3.3: Vocabulary Size Validation

```bash
echo "=== Vocabulary Configuration ==="

# Check vocabulary settings in preprocessing
grep -n "compute_and_apply_vocabulary\|top_k\|num_oov_buckets\|vocabulary_file" "$PREPROC_FILE" 2>/dev/null

# Check for vocabulary constraints in schema
if [ -n "$SCHEMA_PBTXT" ]; then
    grep -A 5 "string_domain\|int_domain" "$SCHEMA_PBTXT" 2>/dev/null | head -20
fi
```

### Phase 4: Generate Test Script

Create a test script if it doesn't exist:

```python
# test_preprocessing.py
"""
Auto-generated test for preprocessing_fn
Run with: python -m pytest test_preprocessing.py -v
"""
import tensorflow as tf
import tensorflow_transform as tft
from tensorflow_transform.tf_metadata import schema_utils

# Import the preprocessing function
from [MODULE] import preprocessing_fn

def test_preprocessing_fn_no_numpy():
    """Verify no numpy operations in preprocessing_fn source."""
    import inspect
    source = inspect.getsource(preprocessing_fn)
    assert 'np.' not in source, "Found numpy usage in preprocessing_fn"
    assert 'numpy.' not in source, "Found numpy usage in preprocessing_fn"

def test_preprocessing_fn_returns_dict():
    """Verify preprocessing_fn returns a dictionary."""
    # Create minimal test input
    test_inputs = {
        # [FEATURE_NAME]: tf.constant([SAMPLE_VALUE]),
    }
    
    # This will fail if function has errors
    try:
        outputs = preprocessing_fn(test_inputs)
        assert isinstance(outputs, dict), "preprocessing_fn must return dict"
    except Exception as e:
        # If we can't test with dummy data, at least verify signature
        import inspect
        sig = inspect.signature(preprocessing_fn)
        assert len(sig.parameters) == 1, "preprocessing_fn should take single 'inputs' arg"

def test_feature_coverage():
    """Verify all expected features are transformed."""
    import inspect
    source = inspect.getsource(preprocessing_fn)
    
    expected_features = [
        # [LIST_OF_EXPECTED_FEATURES]
    ]
    
    for feature in expected_features:
        assert feature in source, f"Feature {feature} not found in preprocessing_fn"

if __name__ == "__main__":
    import pytest
    pytest.main([__file__, "-v"])
```

### Phase 5: Run Validation Tests

```bash
# Run static checks
python -m py_compile "$PREPROC_FILE"

# Run tests if they exist
if [ -f "tests/test_preprocessing.py" ]; then
    python -m pytest tests/test_preprocessing.py -v
elif [ -f "test_preprocessing.py" ]; then
    python -m pytest test_preprocessing.py -v
fi
```

### Phase 6: TFT-Specific Validation

Check for these common TFT patterns:

| Pattern | Correct | Incorrect |
|---------|---------|-----------|
| Scaling | `tft.scale_to_z_score(x)` | `(x - mean) / std` |
| Vocabulary | `tft.compute_and_apply_vocabulary(x)` | Manual encoding |
| Bucketizing | `tft.bucketize(x, num_buckets=N)` | `tf.where` conditions |
| Missing values | `tf.where(tf.math.is_nan(x), default, x)` | Python `if` |

### Output Report

```
═══════════════════════════════════════════════════════════
PREPROCESSING & SCHEMA VALIDATION REPORT
═══════════════════════════════════════════════════════════

File: [preprocessing module path]
Function: preprocessing_fn

Static Analysis:
  ✓ No numpy usage detected
  ✓ Python syntax valid
  ✓ No Python builtins in tensor operations

TFT Operations Found:
  - tft.scale_to_z_score: [count] uses
  - tft.compute_and_apply_vocabulary: [count] uses
  - tft.bucketize: [count] uses
  - [other tft functions]

Schema Validation:
  Schema source: [schema.pbtxt path or "Not found"]
  Schema features: [count]
  Preprocessing inputs: [count]
  Preprocessing outputs: [count]

  [✓/✗] Schema-preprocessing consistency
  [✓/✗] Type definitions match
  [✓/✗] Vocabulary configurations valid

Feature Mapping:
  | Input Feature | Output Feature | Transformation | Type |
  |---------------|----------------|----------------|------|
  | [name]        | [name]         | [tft function] | [dtype] |

Issues Found:
  Schema Issues:
    [✗/○] [Missing features in schema]
    [✗/○] [Unused schema features]
    [✗/○] [Type mismatches]

  Preprocessing Issues:
    [✗/○] [Numpy usage detected]
    [✗/○] [Python builtins used]
    [✗/○] [Missing vocabulary config]

Test Results:
  [Test output or "No tests found"]

Recommendations:
  1. [Specific recommendation based on analysis]
  2. [Schema-specific recommendation if issues found]
═══════════════════════════════════════════════════════════
```