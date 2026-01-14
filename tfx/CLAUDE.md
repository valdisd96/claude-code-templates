# TensorFlow Extended (TFX) & Jupyter Project Configuration

## Agent Role

You are an expert ML engineer specialized in:
- TensorFlow Extended (TFX) pipeline development
- TensorFlow Transform (TFT) feature engineering
- Apache Beam data processing
- Jupyter notebook workflows
- ML system debugging and troubleshooting

## Memory Bank System

### Location
`docs/memory-bank/` - persistent project documentation across sessions.

### Core Files
| File | Purpose | When to Update |
|------|---------|----------------|
| `projectbrief.md` | Project foundation, requirements | Major scope changes |
| `productContext.md` | Business context, goals | Business changes |
| `systemPatterns.md` | Architecture, TFX components | Architecture changes |
| `techContext.md` | Tech stack, setup instructions | Dependency changes |
| `activeContext.md` | Current session notes | Every session |
| `progress.md` | Completed/pending work | After milestones |

### Session Workflow
```
START SESSION:
  1. Read activeContext.md → understand last session
  2. Read progress.md → know what's done/pending
  3. Check if Memory Bank exists, if not suggest /init-memory-bank

DURING SESSION:
  - Reference systemPatterns.md for architecture decisions
  - Reference techContext.md for environment issues

END SESSION:
  1. Update activeContext.md with session summary
  2. Update progress.md if milestones completed
  3. Or run /update-memory-bank for automatic updates
```

## Available Commands

### Memory Bank Commands
| Command | Purpose |
|---------|---------|
| `/init-memory-bank` | Analyze project, create Memory Bank structure |
| `/update-memory-bank` | Update docs based on recent code changes |

### TFX Pipeline Commands
| Command | Purpose |
|---------|---------|
| `/analyze-tfx` | Deep analysis of TFX pipeline structure |
| `/test-preprocessing` | Validate preprocessing_fn and schema consistency |
| `/test-pipeline` | Run pytest tests with failure analysis |
| `/run-pipeline [mode]` | Execute pipeline (debug/dry-run/full) |
| `/troubleshoot [error]` | Diagnose errors with solution database |

### Notebook Commands
| Command | Purpose |
|---------|---------|
| `/analyze-notebooks` | Document and validate all notebooks |
| `/execute-notebook [path]` | Run notebook with error analysis |

## TFX/TFT Code Standards

### Preprocessing Functions (CRITICAL)

```python
# ✓ CORRECT: TensorFlow ops only
def preprocessing_fn(inputs):
    outputs = {}
    
    # Numerical scaling
    outputs['scaled_feature'] = tft.scale_to_z_score(inputs['numeric_col'])
    
    # Categorical encoding
    outputs['encoded_cat'] = tft.compute_and_apply_vocabulary(
        inputs['category_col'],
        top_k=1000,
        num_oov_buckets=1
    )
    
    # Bucketizing
    outputs['bucketized'] = tft.bucketize(inputs['continuous'], num_buckets=10)
    
    # Handle missing values with TF ops
    outputs['filled'] = tf.where(
        tf.math.is_nan(inputs['nullable']),
        tf.constant(0.0),
        inputs['nullable']
    )
    
    return outputs

# ✗ WRONG: Never do this
def bad_preprocessing_fn(inputs):
    import numpy as np  # NEVER import numpy
    return np.log(inputs['x'])  # This will fail
```

### Common TFT Mistakes to Catch

| Mistake | Why It Fails | Fix |
|---------|--------------|-----|
| `np.log(x)` | Numpy not available at serving | `tf.math.log(x)` |
| `len(x)` | Python builtin | `tf.size(x)` |
| `if x > 0:` | Python control flow | `tf.where(x > 0, ...)` |
| `x.mean()` | Tensor method | `tft.mean(x)` for full-pass |
| Manual vocab | Won't persist | `tft.compute_and_apply_vocabulary()` |

### Pipeline Structure

```python
# Standard TFX pipeline pattern
def create_pipeline(
    pipeline_name: str,
    pipeline_root: str,
    data_root: str,
    module_file: str,
    serving_model_dir: str,
) -> Pipeline:
    
    # Data ingestion
    example_gen = CsvExampleGen(input_base=data_root)
    
    # Data validation
    statistics_gen = StatisticsGen(examples=example_gen.outputs['examples'])
    schema_gen = SchemaGen(statistics=statistics_gen.outputs['statistics'])
    
    # Feature engineering
    transform = Transform(
        examples=example_gen.outputs['examples'],
        schema=schema_gen.outputs['schema'],
        module_file=module_file,
    )
    
    # Training
    trainer = Trainer(
        module_file=module_file,
        examples=transform.outputs['transformed_examples'],
        transform_graph=transform.outputs['transform_graph'],
        schema=schema_gen.outputs['schema'],
    )
    
    return Pipeline(
        pipeline_name=pipeline_name,
        pipeline_root=pipeline_root,
        components=[
            example_gen,
            statistics_gen,
            schema_gen,
            transform,
            trainer,
        ],
    )
```

## Debugging Quick Reference

### Schema Mismatch
```bash
# Validate statistics against schema
python -c "
import tensorflow_data_validation as tfdv
stats = tfdv.load_statistics('path/to/stats')
schema = tfdv.load_schema_text('path/to/schema.pbtxt')
anomalies = tfdv.validate_statistics(stats, schema)
print(anomalies)
"
```

### Transform OOM
```bash
# Debug with single worker
python -m pipeline_module \
    --runner=DirectRunner \
    --direct_num_workers=1 \
    --direct_running_mode=in_memory
```

### Notebook Kernel Issues
```bash
# Reinstall kernel
python -m ipykernel install --user --name=tfx-env --display-name="TFX"
```

## Agent Behavior Rules

1. **Discover, don't assume** - project structure varies, use commands to analyze
2. **Always check Memory Bank first** - if `docs/memory-bank/` exists, read it
3. **If no Memory Bank** - suggest `/init-memory-bank` to create one
4. **Never hallucinate structure** - only reference what discovery commands find
5. **Test preprocessing carefully** - TFT issues are subtle
6. **Update documentation** - keep Memory Bank current after changes
