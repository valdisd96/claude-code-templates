# Troubleshoot TFX/TFT Error

Analyze an error and provide diagnosis with solutions.

## Arguments
- `$ARGUMENTS`: Error message, traceback, or "last" to analyze last command output

## Execution Steps

### Phase 1: Error Classification

Classify the error into categories:

1. **Schema Errors**
   - Pattern: `SchemaError`, `InvalidArgument`, `feature.*not found`
   - Cause: Mismatch between expected and actual schema

2. **Transform Errors**
   - Pattern: `preprocessing_fn`, `tft.`, `AnalyzeAndTransform`
   - Cause: Issues in feature transformation logic

3. **Beam Pipeline Errors**
   - Pattern: `beam.`, `PipelineResult`, `DoFn`, `DirectRunner`
   - Cause: Data processing or parallelization issues

4. **TensorFlow Errors**
   - Pattern: `tf.`, `Tensor`, `dtype`, `shape`
   - Cause: Type/shape mismatches, graph issues

5. **Environment Errors**
   - Pattern: `ImportError`, `ModuleNotFoundError`, `version`
   - Cause: Missing or incompatible dependencies

6. **Resource Errors**
   - Pattern: `OOM`, `ResourceExhausted`, `timeout`
   - Cause: Memory or compute limitations

### Phase 2: Deep Analysis

Based on error type, perform targeted analysis:

#### For Schema Errors:
```bash
# Find schema definitions
find . -name "schema.pbtxt" -o -name "*schema*.py" | xargs grep -l "feature"
# Compare with preprocessing
grep -r "feature_spec\|FEATURE" --include="*.py"
```

#### For Transform Errors:
```bash
# Analyze preprocessing function
grep -r "def preprocessing_fn" --include="*.py" -A 100
# Check for numpy usage (common mistake)
grep -r "np\.\|numpy\." --include="*.py" | grep -v "import"
```

#### For Beam Errors:
```bash
# Check runner configuration
grep -r "DirectRunner\|DataflowRunner\|BeamDagRunner" --include="*.py"
# Look for parallelization issues
grep -r "beam.ParDo\|beam.Map" --include="*.py"
```

### Phase 3: Knowledge Base Lookup

Check against common issues:

```markdown
## Common TFX/TFT Issues Database

### "Feature X not found in schema"
**Cause**: Schema doesn't include all features used in preprocessing_fn
**Solution**: 
1. Check schema generation: `tfdv.infer_schema(statistics)`
2. Manually add missing features to schema
3. Ensure feature names match exactly (case-sensitive)

### "Input tensor must be a tf.Tensor"
**Cause**: Using numpy operations instead of TensorFlow ops in preprocessing_fn
**Solution**: Replace `np.` calls with `tf.` equivalents
- `np.log` → `tf.math.log`
- `np.where` → `tf.where`
- `np.mean` → `tf.reduce_mean`

### "Vocabulary file not found"
**Cause**: tft.compute_and_apply_vocabulary was not run in analyze phase
**Solution**: Ensure Transform component runs before Trainer

### "Shape mismatch"
**Cause**: Inconsistent tensor shapes between training and serving
**Solution**: 
1. Check feature preprocessing consistency
2. Use `tf.ensure_shape()` for debugging
3. Verify batch dimensions

### "OOM during Transform"
**Cause**: Full-pass analyzers loading too much data
**Solution**:
1. Use `tft.vocabulary()` with `top_k` parameter
2. Reduce `--direct_num_workers`
3. Increase instance memory or use DataflowRunner

### "INVALID_ARGUMENT: assertion failed"
**Cause**: Often schema validation failure
**Solution**: Run `tfdv.validate_statistics(stats, schema)` to identify specific failures
```

### Phase 4: Generate Solution

Provide structured diagnosis:

```markdown
## Error Diagnosis

### Error Type
[Classified type]

### Root Cause
[Specific cause identified]

### Evidence
- Found in: [file:line]
- Related code: [snippet]

### Solution

#### Quick Fix
[Immediate action to resolve]

#### Proper Fix
[Best practice solution]

#### Verification
```bash
[Command to verify fix worked]
```

### Prevention
[How to avoid this in future]

### Related Documentation
- [Link to TFX docs]
- [Link to relevant memory bank section]
```

### Phase 5: Update Memory Bank

If this is a new issue pattern:
1. Add to `docs/memory-bank/troubleshooting.md`
2. Update `progress.md` with known issues

### Output Format

```
=== Troubleshooting Report ===

Error: [brief description]
Type: [classification]
Severity: [critical/high/medium/low]

Diagnosis:
  Root cause: [explanation]
  Location: [file:line if found]

Solution:
  [Step-by-step fix]

Verification:
  [How to confirm fix works]

Memory Bank:
  ✓ Added to troubleshooting docs
```
