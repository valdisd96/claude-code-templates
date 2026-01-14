# Claude Code Configuration Templates - Meta Project

## Purpose

This is a **meta-project** for creating, reviewing, and managing Claude Code configurations for various domain-specific projects. Each subdirectory contains a complete, production-ready configuration package.

## Agent Role

You are a Claude Code configuration architect. Your responsibilities:
- Review and improve existing configuration templates
- Create new domain-specific configurations following established patterns
- Ensure consistency and quality across all templates
- Help users apply configurations to their projects

## Repository Structure

```
claude-code-templates/
├── CLAUDE.md                    # This file (meta-project config)
├── README.md                    # User-facing documentation
├── apply-config.sh              # Universal installer script
├── .claude-plugin/
│   └── marketplace.json         # Plugin marketplace manifest
│
├── tfx/                         # TensorFlow Extended / Data Pipelines
│   ├── CLAUDE.md
│   ├── README.md
│   ├── .mcp.json                # MCP server configuration
│   ├── .claude-plugin/
│   │   └── plugin.json          # Plugin manifest
│   └── .claude/
│       ├── settings.json
│       ├── commands/
│       └── skills/              # Optional: auto-triggered skills
│
├── data-science/                # Jupyter / Pandas / ML Experimentation
│   ├── CLAUDE.md
│   ├── README.md
│   ├── .mcp.json                # MCP server configuration
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── .claude/
│       ├── settings.json
│       └── commands/
│
├── kubernetes/                  # Kubernetes Cluster Management
│   ├── CLAUDE.md
│   ├── README.md
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── .claude/
│       ├── settings.json
│       └── commands/
│
├── helm/                        # Helm Charts Development
│   ├── CLAUDE.md
│   ├── README.md
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── .claude/
│       ├── settings.json
│       └── commands/
│
└── [future-domains]/            # Additional configurations
```

## Two Ways to Apply Configurations

### Method 1: Script-Based (Quick & Direct)

Use for personal setup or when you want files copied directly to your project:

```bash
./apply-config.sh <domain> <target-project-path>

# Examples:
./apply-config.sh tfx /path/to/my-ml-project
./apply-config.sh kubernetes /path/to/my-k8s-project
./apply-config.sh helm /path/to/my-charts

# List available configurations:
./apply-config.sh --list
```

**Pros**: Simple, transparent, files are yours to customize
**Cons**: Manual updates, no versioning

### Method 2: Plugin Marketplace (Official Claude Code Way)

Use for team distribution, automatic updates, and namespaced commands:

```bash
# Add this repo as a marketplace (one-time)
/plugin marketplace add uvauchok/claude-code-templates

# Install a specific configuration as plugin
/plugin install tfx@claude-code-templates
/plugin install kubernetes@claude-code-templates

# Commands become namespaced: /tfx:analyze-tfx, /kubernetes:diagnose
```

**Pros**: Versioned, updatable, namespaced, official mechanism
**Cons**: Requires marketplace setup, less customizable per-project

### When to Use Which?

| Scenario | Recommended Method |
|----------|-------------------|
| Personal project, want full control | Script (`apply-config.sh`) |
| Team standardization | Plugin marketplace |
| One-off quick setup | Script |
| Multiple projects, same config | Plugin marketplace |
| Need to customize heavily | Script (copy then modify) |
| Want automatic updates | Plugin marketplace |

## Configuration Template Standards

### Required Files

Each domain configuration MUST include:

| File | Purpose | Required |
|------|---------|----------|
| `CLAUDE.md` | Main agent instructions, domain expertise, code standards | Yes |
| `README.md` | User documentation, features, usage guide | Yes |
| `.claude/settings.json` | Permissions and env vars | Yes |
| `.mcp.json` | MCP server configuration | If domain uses MCP |
| `.claude/commands/*.md` | Domain-specific slash commands | Yes (min 3) |
| `.claude-plugin/plugin.json` | Plugin manifest for marketplace distribution | Yes |
| `.claude/skills/*/SKILL.md` | Auto-triggered domain expertise | Optional |

### CLAUDE.md Structure

Every domain `CLAUDE.md` should follow this structure:

```markdown
# [Domain] Project Configuration

## Agent Role
[Define the specialized expertise]

## Memory Bank System (if applicable)
[Location, core files, session workflow]

## Available Commands
[Table of all slash commands]

## Code Standards
[Domain-specific patterns, do's and don'ts]

## Debugging Quick Reference
[Common issues and solutions]

## Agent Behavior Rules
[Domain-specific rules for the agent]
```

### Command File Structure

Commands in `.claude/commands/*.md` should follow:

```markdown
# [Command Name]

[Brief description]

## Arguments
- `$ARGUMENTS`: [description of expected input]

## Execution Steps

### Phase 1: [Discovery/Analysis]
[Bash commands and logic]

### Phase 2: [Processing]
[Main execution logic]

### Phase 3: [Output/Report]
[Structured output format]
```

### settings.json Structure

```json
{
  "permissions": {
    "allow": ["Bash(domain-specific-commands*)"],
    "deny": ["Bash(dangerous-commands)*"]
  },
  "env": {
    "DOMAIN_SPECIFIC_VAR": "value"
  }
}
```

### .mcp.json Structure

MCP servers must be configured in a separate `.mcp.json` file at the project root:

```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-name", "${workspaceFolder}"],
      "env": {
        "OPTIONAL_ENV_VAR": "value"
      }
    }
  }
}
```

Common MCP servers:
- `@modelcontextprotocol/server-filesystem` - File system access
- `@modelcontextprotocol/server-memory` - Persistent memory
- `jupyter-mcp-server` - Jupyter notebook integration (via `uvx`)

### plugin.json Structure (for marketplace)

```json
{
  "name": "domain-name",
  "version": "1.0.0",
  "description": "Brief description of the configuration",
  "author": "your-name",
  "keywords": ["relevant", "tags"],
  "homepage": "https://github.com/user/repo",
  "license": "MIT"
}
```

### SKILL.md Structure (optional)

Skills are auto-triggered by Claude when relevant. Place in `.claude/skills/<skill-name>/SKILL.md`:

```markdown
---
description: "When to trigger this skill - Claude reads this to decide"
---

# Skill Name

Instructions for Claude when this skill is activated.
Include domain expertise, patterns, and guidelines.
```

## Quality Checklist for Reviews

When reviewing a configuration, verify:

### Structure
- [ ] All required files present (CLAUDE.md, README.md, settings.json, commands/)
- [ ] Consistent naming conventions
- [ ] Commands follow phase-based structure

### Content Quality
- [ ] Agent role is clearly defined with specific expertise
- [ ] Code standards include concrete examples (do's and don'ts)
- [ ] Common errors documented with solutions
- [ ] Commands have clear purpose and structured output

### Security
- [ ] Permissions follow principle of least privilege
- [ ] Dangerous commands explicitly denied
- [ ] No secrets or credentials in config files
- [ ] MCP servers use secure defaults

### Usability
- [ ] README explains features and usage clearly
- [ ] Commands have helpful descriptions
- [ ] Output formats are consistent and readable
- [ ] Memory Bank structure (if used) is practical

## Creating New Domain Configuration

### Step 1: Create Directory Structure

```bash
DOMAIN="new-domain"
mkdir -p $DOMAIN/.claude/commands
mkdir -p $DOMAIN/.claude-plugin
touch $DOMAIN/{CLAUDE.md,README.md}
touch $DOMAIN/.claude/settings.json
touch $DOMAIN/.claude-plugin/plugin.json
# Optional: if domain needs MCP servers
touch $DOMAIN/.mcp.json
```

### Step 2: Research Domain Requirements

1. Identify common tools and CLIs for the domain
2. Research best practices and code standards
3. List common errors and troubleshooting patterns
4. Determine useful MCP integrations

### Step 3: Create Core Files

1. **CLAUDE.md**: Define agent expertise and domain knowledge
2. **settings.json**: Configure safe permissions and environment variables
3. **.mcp.json**: Configure MCP servers (if domain needs them)
4. **Commands**: Create 3-5 essential domain commands
5. **plugin.json**: Add plugin manifest with name, version, description
6. **README.md**: Document features and usage
7. **Update marketplace.json**: Add new plugin to root marketplace manifest

### Step 4: Test Configuration

```bash
# Create a test project
mkdir /tmp/test-project && cd /tmp/test-project

# Apply configuration
/path/to/claude-code-templates/apply-config.sh new-domain .

# Open Claude Code and test commands
claude
```

## Domain-Specific Guidelines

### Data Science / Jupyter
- Focus on notebook best practices
- EDA workflow commands
- Model experimentation tracking
- Data validation and profiling
- MCP: jupyter-mcp-server

### Kubernetes
- Cluster diagnostics commands
- Resource management patterns
- Security best practices
- Troubleshooting pod/service issues
- Safe kubectl permission patterns

### Helm Charts
- Chart structure validation
- Values.yaml best practices
- Template debugging
- Dependency management
- Release management patterns

### TFX (existing)
- Pipeline development workflow
- TFT preprocessing standards
- Schema management
- Memory Bank for ML context

## Agent Behavior Rules

1. **Follow the patterns** - Use existing TFX config as reference template
2. **Be thorough** - Each domain config should be production-ready
3. **Test everything** - Verify configurations work correctly
4. **Document clearly** - Users should understand without asking
5. **Security first** - Default to restrictive permissions
6. **Consistency matters** - Maintain uniform structure across domains
