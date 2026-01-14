# Analyze TFX Pipeline

Deep analysis of TensorFlow Extended pipeline structure and components.

## Arguments
- `$ARGUMENTS`: Optional - path to specific pipeline file or "all"

## Execution Steps

### Phase 1: Discover Pipeline Structure

1. **Find pipeline definitions**:
   ```bash
   grep -r "tfx.dsl.Pipeline\|from tfx.dsl import Pipeline\|@component" --include="*.py" -l
   grep -r "def create_pipeline\|def get_pipeline" --include="*.py" -l
   ```

2. **Extract pipeline DAG**:
   - Identify all components
   - Map input/output relationships
   - Find artifact dependencies

3. **Analyze component configuration**:
   ```bash
   grep -r "ExampleGen\|StatisticsGen\|SchemaGen\|Transform\|Trainer\|Evaluator\|Pusher" --include="*.py"
   ```

### Phase 2: Analyze TFT Preprocessing

1. **Find preprocessing functions**:
   ```bash
   grep -r "def preprocessing_fn\|preprocessing_fn\s*=" --include="*.py" -A 50
   ```

2. **Extract feature transformations**:
   - tft.scale_to_z_score
   - tft.compute_and_apply_vocabulary
   - tft.bucketize
   - Custom transformations

3. **Check for common issues**:
   - Numpy usage (should be tf ops)
   - Missing sparse tensor handling
   - Schema mismatches

### Phase 3: Schema Analysis

1. **Find schema definitions**:
   ```bash
   find . -name "schema.pbtxt" -o -name "*schema*.py"
   grep -r "schema_utils\|feature_spec\|FeatureSpec" --include="*.py"
   ```

2. **Validate feature consistency**:
   - Compare schema with preprocessing_fn
   - Check serving signature compatibility
   - Identify potential drift issues

### Phase 4: Generate Pipeline Documentation

Create/update `docs/memory-bank/tfx-pipeline.md`:

```markdown
# TFX Pipeline Analysis

## Pipeline Overview
- Name: [extracted]
- Components: [count]
- Runner: [LocalDagRunner/BeamDagRunner/etc]

## Component Graph
[ASCII diagram of pipeline DAG]

## Components Detail

### ExampleGen
- Input: [source]
- Output splits: [train/eval ratio]

### StatisticsGen
- Purpose: Compute dataset statistics

### SchemaGen
- Generated schema location: [path]
- Feature count: [number]

### Transform
- Preprocessing module: [path]
- Key transformations:
  - [feature]: [transformation type]
  - ...

### Trainer
- Model type: [extracted]
- Training config: [summary]

### Evaluator
- Metrics: [list]
- Thresholds: [if configured]

### Pusher
- Destination: [path/endpoint]

## Feature Specifications

| Feature | Type | Transformation | Notes |
|---------|------|----------------|-------|
| [name]  | [dtype] | [tft function] | [any issues] |

## Identified Issues
- [ ] [Issue 1]
- [ ] [Issue 2]

## Recommendations
1. [Recommendation based on analysis]
```

### Phase 5: Output Report

```
=== TFX Pipeline Analysis Complete ===

Pipeline: [name]
Components: [count]
Features: [count]

Health Check:
  ✓ Schema consistency: [OK/ISSUES]
  ✓ Preprocessing validation: [OK/ISSUES]
  ✓ Type safety: [OK/ISSUES]

Documentation:
  ✓ Updated docs/memory-bank/tfx-pipeline.md

Warnings:
  - [Any issues found]
```
