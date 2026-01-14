# Data Science Claude Code Configuration

A Claude Code configuration for data science projects, Jupyter notebooks, and EDA workflows.

## Features

- **EDA Workflows**: Automated exploratory data analysis commands
- **Notebook Best Practices**: Enforced patterns for reproducible notebooks
- **Pandas Expertise**: Optimized data manipulation patterns
- **Jupyter Integration**: MCP server for notebook interaction

## Installation

### Via Script
```bash
./apply-config.sh data-science /path/to/your/ds-project
```

### Via Plugin
```bash
/plugin marketplace add uvauchok/claude-code-templates
/plugin install data-science@claude-code-templates
```

## Available Commands

| Command | Description |
|---------|-------------|
| `/eda [dataset]` | Generate exploratory data analysis report |
| `/profile-data` | Detailed data profiling with statistics |
| `/notebook-clean` | Clean and standardize notebook outputs |

## Permissions

### Allowed
- `python`, `pip`, `pytest`
- `jupyter`, `conda`, `poetry`

### MCP Servers
- `jupyter-mcp-server` for notebook interaction

## Requirements

- Python 3.8+
- Pandas, NumPy, Matplotlib, Seaborn
- Optional: Jupyter for MCP integration

## Customization

Edit `.claude/settings.json` to:
- Configure Jupyter server URL and token
- Add project-specific Python paths
- Enable additional MCP servers

## Project Structure Suggestion

```
project/
├── data/
│   ├── raw/           # Original data (never modify)
│   ├── processed/     # Cleaned data
│   └── external/      # External sources
├── notebooks/
│   ├── 01_eda.ipynb
│   ├── 02_feature_engineering.ipynb
│   └── 03_modeling.ipynb
├── src/
│   └── utils.py       # Reusable functions
├── figures/           # Saved visualizations
├── models/            # Saved models
└── requirements.txt
```
