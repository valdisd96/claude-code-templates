# Exploratory Data Analysis

Generate a comprehensive EDA report for a dataset.

## Arguments
- `$ARGUMENTS`: Path to dataset file (CSV, Parquet, JSON) or DataFrame variable name

## Execution Steps

### Phase 1: Data Loading & Overview

```python
import pandas as pd
import numpy as np

# Load data based on file extension
data_path = "$ARGUMENTS"
if data_path.endswith('.csv'):
    df = pd.read_csv(data_path)
elif data_path.endswith('.parquet'):
    df = pd.read_parquet(data_path)
elif data_path.endswith('.json'):
    df = pd.read_json(data_path)
else:
    # Assume it's a variable name in current scope
    df = eval(data_path)

print("=" * 60)
print("DATASET OVERVIEW")
print("=" * 60)
print(f"Shape: {df.shape[0]:,} rows × {df.shape[1]} columns")
print(f"Memory Usage: {df.memory_usage(deep=True).sum() / 1e6:.2f} MB")
print(f"\nColumn Types:")
print(df.dtypes.value_counts())
```

### Phase 2: Missing Values Analysis

```python
print("\n" + "=" * 60)
print("MISSING VALUES")
print("=" * 60)

missing = df.isnull().sum()
missing_pct = (missing / len(df) * 100).round(2)
missing_df = pd.DataFrame({
    'Missing Count': missing,
    'Missing %': missing_pct
}).query('`Missing Count` > 0').sort_values('Missing %', ascending=False)

if len(missing_df) > 0:
    print(missing_df)
else:
    print("No missing values found!")

print(f"\nDuplicate Rows: {df.duplicated().sum():,}")
```

### Phase 3: Numerical Analysis

```python
print("\n" + "=" * 60)
print("NUMERICAL COLUMNS")
print("=" * 60)

numeric_cols = df.select_dtypes(include=[np.number]).columns.tolist()
print(f"Found {len(numeric_cols)} numerical columns")

if numeric_cols:
    print("\nStatistics:")
    print(df[numeric_cols].describe().round(2))

    print("\nSkewness (|skew| > 1 may need transformation):")
    skew = df[numeric_cols].skew().sort_values(key=abs, ascending=False)
    print(skew[abs(skew) > 1])
```

### Phase 4: Categorical Analysis

```python
print("\n" + "=" * 60)
print("CATEGORICAL COLUMNS")
print("=" * 60)

cat_cols = df.select_dtypes(include=['object', 'category']).columns.tolist()
print(f"Found {len(cat_cols)} categorical columns")

for col in cat_cols[:10]:  # Limit to first 10
    unique = df[col].nunique()
    print(f"\n{col}: {unique} unique values")
    if unique <= 10:
        print(df[col].value_counts())
    else:
        print(f"Top 5: {df[col].value_counts().head().to_dict()}")
```

### Phase 5: Correlations

```python
print("\n" + "=" * 60)
print("CORRELATIONS")
print("=" * 60)

if len(numeric_cols) > 1:
    corr = df[numeric_cols].corr()

    # Find high correlations (excluding diagonal)
    high_corr = []
    for i in range(len(corr.columns)):
        for j in range(i+1, len(corr.columns)):
            if abs(corr.iloc[i, j]) > 0.7:
                high_corr.append({
                    'col1': corr.columns[i],
                    'col2': corr.columns[j],
                    'correlation': round(corr.iloc[i, j], 3)
                })

    if high_corr:
        print("High correlations (|r| > 0.7):")
        for h in high_corr:
            print(f"  {h['col1']} ↔ {h['col2']}: {h['correlation']}")
    else:
        print("No high correlations found")
```

### Phase 6: Generate Report

```
═══════════════════════════════════════════════════════════
EXPLORATORY DATA ANALYSIS REPORT
═══════════════════════════════════════════════════════════

Dataset: [filename]
Records: [X,XXX rows]
Features: [XX columns]

Data Quality:
  ✓/✗ Missing values: [X columns affected]
  ✓/✗ Duplicates: [X rows]
  ✓/✗ Memory efficient: [XX MB]

Feature Summary:
  Numerical: [X columns]
  Categorical: [X columns]
  DateTime: [X columns]

Key Findings:
  - [Finding 1 from analysis]
  - [Finding 2 from analysis]
  - [Finding 3 from analysis]

Recommendations:
  1. [Handle missing values in column X]
  2. [Transform skewed column Y]
  3. [Review high cardinality in column Z]

Next Steps:
  - Run /profile-data for detailed profiling
  - Create visualizations for key relationships
═══════════════════════════════════════════════════════════
```
