# TFX Claude Code Configuration Package

A comprehensive Claude Code configuration for TensorFlow Extended (TFX) and Jupyter notebook development workflows.

## Features

- **Memory Bank System**: Persistent project documentation that survives across sessions
- **Auto-initialization**: Analyze existing projects and generate documentation automatically
- **TFX-specific tooling**: Deep analysis of pipelines, components, and preprocessing functions
- **Jupyter integration**: Notebook validation, documentation, and best practices
- **Smart troubleshooting**: Error classification and solution database

## Quick Start

### Installation

```bash
# Clone or download this configuration
# Then run setup in your project:

./setup.sh /path/to/your/tfx-project
```

### First Use

After installation, open Claude Code in your project and run:

```
/init-memory-bank
```

This will analyze your project and create the Memory Bank documentation structure.

## Included Commands

| Command | Description |
|---------|-------------|
| `/init-memory-bank` | Analyze project and generate Memory Bank documentation |
| `/update-memory-bank` | Update documentation after code changes |
| `/analyze-tfx` | Deep analysis of TFX pipeline structure |
| `/analyze-notebooks` | Validate and document Jupyter notebooks |
| `/troubleshoot [error]` | Diagnose errors with solution suggestions |

## Memory Bank Structure

After initialization, your project will have:

```
docs/
└── memory-bank/
    ├── projectbrief.md      # Project foundation & requirements
    ├── productContext.md    # Business context & goals
    ├── systemPatterns.md    # Architecture & design patterns
    ├── techContext.md       # Tech stack & dependencies
    ├── activeContext.md     # Current session notes
    └── progress.md          # Completed & pending work
```

### How Memory Bank Works

1. **Session Start**: Claude reads `activeContext.md` and `progress.md` to understand current state
2. **During Work**: Claude references relevant docs when making decisions
3. **Session End**: Update `activeContext.md` with session notes for continuity

### Keeping Memory Bank Current

Run `/update-memory-bank` after:
- Adding new features or components
- Changing architecture
- Updating dependencies
- Completing milestones

## Configuration Files

### CLAUDE.md

Main configuration file containing:
- Project context and conventions
- Code style guidelines for TFX/TFT
- Testing strategies
- Common troubleshooting patterns

### .claude/settings.json

Permissions and environment configuration:
- Allowed bash commands
- Denied dangerous operations
- Environment variables for TensorFlow

## Customization

### Adding Project-Specific Context

Edit `CLAUDE.md` to add:
- Your team's specific conventions
- Custom pipeline patterns
- Integration details for your infrastructure

### Adding Custom Commands

Create new `.md` files in `.claude/commands/`:

```markdown
# Your Custom Command

Description of what this command does.

## Execution Steps
1. Step one
2. Step two
...
```

### Extending Troubleshooting

The `/troubleshoot` command uses a knowledge base. Add your own patterns:

1. Run `/troubleshoot` when you encounter new errors
2. Document solutions in `docs/memory-bank/troubleshooting.md`
3. Future troubleshooting will reference your solutions

## Best Practices

### For TFX Development

1. Always use TensorFlow ops in `preprocessing_fn` (never numpy)
2. Keep schema definitions in sync with preprocessing
3. Test components individually before pipeline integration
4. Use `DirectRunner` with `--direct_num_workers=1` for debugging

### For Notebooks

1. Clear outputs before committing
2. Use `%autoreload` for development
3. Extract reusable code to `.py` modules
4. Document purpose in first markdown cell

### For Memory Bank

1. Update `activeContext.md` at end of each session
2. Keep `progress.md` current with completed work
3. Document architectural decisions in `systemPatterns.md`
4. Review and update docs during major refactors

## Troubleshooting

### Claude doesn't find Memory Bank

Ensure `docs/memory-bank/` exists. Run `/init-memory-bank` if not.

### Commands not appearing

Check that `.claude/commands/` contains the `.md` files.
Restart Claude Code if needed.

### Permission errors

Review `.claude/settings.json` and add required commands to `allow` list.

## File Structure

```
tfx-claude-config/
├── CLAUDE.md                          # Main configuration
├── README.md                          # This file
├── setup.sh                           # Installation script
└── .claude/
    ├── settings.json                  # Permissions config
    └── commands/
        ├── init-memory-bank.md        # Initialize Memory Bank
        ├── update-memory-bank.md      # Update documentation
        ├── analyze-tfx.md             # TFX pipeline analysis
        ├── analyze-notebooks.md       # Notebook documentation
        └── troubleshoot.md            # Error diagnosis
```

## License

MIT - Use freely in your projects.

## Contributing

Feel free to extend this configuration for your needs. Common additions:
- Team-specific conventions
- CI/CD integration commands
- Custom analysis for your data domain