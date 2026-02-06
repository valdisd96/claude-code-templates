# Plan: Claude Code Configuration Template for Ansible Projects

## Context

A **generic, reusable** Claude Code configuration template for any Ansible project. No assumptions about specific OS distributions, cloud providers, inventory layouts, or naming conventions. The agent discovers project-specific patterns at setup time via `/init` and encodes universal Ansible best practices in CLAUDE.md.

---

## What Will Be Created (13 files, 2 directories)

```
ansible/
├── CLAUDE.md                              # NEW - Universal Ansible best practices + discovered conventions
├── README.md                              # NEW - User documentation
├── .mcp.json                              # NEW - MCP server configuration
├── .pre-commit-config.yaml                # NEW - Linting hooks (yamllint, ansible-lint, syntax-check)
├── .ansible-lint                          # NEW - Sensible default ansible-lint config
├── .gitignore                             # NEW - Ansible/Molecule/Python/Claude ignores
├── .claude-plugin/
│   └── plugin.json                        # NEW - Plugin manifest for marketplace
├── .claude/
│   ├── settings.json                      # NEW - Permissions + hooks configuration
│   ├── hooks/
│   │   ├── post-write-lint.sh             # NEW - Auto-lint after file writes
│   │   └── pre-bash-safety.sh             # NEW - Block dangerous commands
│   └── commands/
│       ├── init.md                        # NEW - /init: discover project conventions
│       ├── new-role.md                    # NEW - /new-role slash command
│       ├── lint.md                        # NEW - /lint slash command
│       ├── test-role.md                   # NEW - /test-role slash command
│       └── validate.md                    # NEW - /validate slash command
└── .github/
    └── workflows/
        └── ansible-ci.yml                 # NEW - GitHub Actions CI/CD
```

---

## Step-by-Step Implementation

### Step 1: Create `/init` Command (`.claude/commands/init.md`)

The **most important file**. Discovers the target project's actual conventions instead of hardcoding them. Modeled after the TFX `/init-memory-bank` pattern.

**Critical rules:**
1. Always run discovery commands FIRST before generating anything
2. Never hallucinate — only document what is actually found in code
3. Mark unknowns as `[TODO]` — don't guess
4. If conventions file exists, merge don't overwrite

**Phase 1: Project Structure Discovery**
```bash
# Directory layout (roles, playbooks, inventories, group_vars, host_vars)
# Detect: role locations, playbook locations, inventory type (ini/yaml/dynamic)
# Find: ansible.cfg, requirements.yml, galaxy.yml, molecule configs
# Detect: CI/CD (GitHub Actions, GitLab CI, Jenkins)
```

**Phase 2: Convention Analysis**
```bash
# Task naming patterns — grep existing tasks for name: lines, detect format
# Variable naming — scan defaults/ and group_vars/ for naming conventions
# Tag usage — grep for tags: across roles, detect tagging strategy
# Module style — detect FQCN (ansible.builtin.*) vs short names
# File extensions — count .yml vs .yaml usage
# Platform targets — detect OS families from when: conditions and molecule platforms
# Vault patterns — find vault files, detect naming convention
# Handler patterns — analyze handlers/ for naming and options
# Jinja2 patterns — scan templates/ for header comments, spacing style
# Inventory structure — detect layout (flat, per-env, dynamic scripts)
# Playbook patterns — detect become, diff, role inclusion style
```

**Phase 3: Generate Conventions File**

Create `docs/ansible-conventions.md` (or append to project CLAUDE.md) with discovered patterns:

```markdown
# Project Conventions (Auto-Discovered)

## Structure
- Role location: [discovered path]
- Playbook location: [discovered path]
- Inventory layout: [discovered pattern]
- File extension: [.yml or .yaml — whichever is dominant]

## Naming
- Task names: [detected pattern or TODO]
- Variable prefix: [detected pattern or TODO]
- Vault files: [detected pattern or TODO]
- Tags: [detected strategy or TODO]

## Style
- Module format: [FQCN / short / mixed]
- Platform targets: [detected OS families]
- Playbook options: [detected become/diff/etc.]
- Handler style: [detected patterns]
- Jinja2 templates: [detected conventions]

## Testing
- Molecule driver: [detected or TODO]
- Molecule platforms: [detected images or TODO]
- CI/CD: [detected system or TODO]

## Collections
- [list from requirements.yml or galaxy.yml]
```

**Phase 4: Verification & Report**
```
═══════════════════════════════════════════════════════════
PROJECT INITIALIZATION COMPLETE
═══════════════════════════════════════════════════════════

Project Analysis:
  Roles: [count]
  Playbooks: [count]
  Inventories: [count]
  Collections: [count]

Discovered Conventions: [count]
Needs Manual Input: [count TODOs]

Created: docs/ansible-conventions.md

Recommended Next Steps:
  1. Review discovered conventions for accuracy
  2. Fill [TODO] items with your team's standards
  3. Run /lint to check current code health
  4. Run /validate on a playbook to test the pipeline
═══════════════════════════════════════════════════════════
```

### Step 2: Create `CLAUDE.md`

Contains **only universal Ansible best practices** — not project-specific conventions. Project-specific patterns come from `/init` discovery.

**Universal rules (always apply):**
- No hardcoded secrets — use `ansible-vault` for sensitive data
- All tasks must be idempotent
- Use FQCN (`ansible.builtin.*`) for all modules in new code
- Every task must have a descriptive `name:`
- Jinja2: `.j2` extension, `{{ variable }}` with spaces, no bare variables in `when:`
- Role structure: standard layout (`defaults/`, `tasks/`, `handlers/`, `templates/`, `meta/`, `README.md`)
- Handlers: descriptive names, use `listen` for decoupling when appropriate
- Variables: role-scoped prefixes to avoid collisions, `vault_` prefix for secrets
- Documentation: every role needs a README with variables table and example playbook
- Testing: every new role should have a Molecule scenario

**Discovered conventions section:**
- Points agent to read `docs/ansible-conventions.md` if it exists
- If it doesn't exist, suggests running `/init` first
- When editing existing files, match the surrounding code style

**Session workflow:**
```
START SESSION:
  1. Check if docs/ansible-conventions.md exists
  2. If yes → read it for project-specific conventions
  3. If no → suggest running /init

DURING SESSION:
  - Follow universal rules from CLAUDE.md
  - Follow project conventions from docs/ansible-conventions.md
  - When editing existing code, match surrounding style
```

**Available commands table** (same as other templates).

**Debugging quick reference:**
- Common ansible-lint errors and fixes
- Molecule troubleshooting
- Vault issues
- Jinja2 debugging

### Step 3: Create `.mcp.json` — MCP Servers

Two MCP servers:

1. **`mcp-ansible`** (bsahane/mcp-ansible) — primary
   - Playbook creation, validation, execution
   - Role management and scaffolding
   - Inventory parsing and operations
   - Install: `pip install mcp-ansible` / run via `uvx mcp-ansible`

2. **`ansible-dev-tools`** (Red Hat official) — secondary
   - Ansible-lint with auto-fix capability
   - Collection generation following standards
   - Best practice guidelines
   - Install: `pip install ansible-dev-tools` / run via `adt mcp`

### Step 4: Create `.claude/settings.json` + Hook Scripts

**Hooks configuration:**

- **PostToolUse (Write|Edit)**: Run `yamllint` + `ansible-lint` on the changed file
  - Non-blocking (reports errors, doesn't prevent writes)
  - Only triggers on `.yaml`/`.yml` files in Ansible directories

- **PreToolUse (Bash)**: Safety guard that blocks:
  - `ansible-playbook` against any inventory path containing `prod` (generic, not hardcoded)
  - `ansible-vault edit/decrypt` (could expose secrets)
  - `rm -rf` on critical directories (roles/, playbooks/, inventories/)

**Hook scripts** in `.claude/hooks/`:
- `post-write-lint.sh` — runs yamllint + ansible-lint on the edited file
- `pre-bash-safety.sh` — reads command from stdin, blocks dangerous patterns

### Step 5: Create `.pre-commit-config.yaml`

A **new, standalone** pre-commit config (not upgrading any existing file):

- `pre-commit-hooks` (v4.6.0): `trailing-whitespace`, `end-of-file-fixer`, `check-yaml --unsafe`, `check-merge-conflict`, `no-commit-to-branch` (protect main/master)
- **yamllint** hook (v1.35.1)
- **ansible-lint** hook (v24.10.0)
- Local **ansible-playbook --syntax-check** hook for playbook files

### Step 6: Create `.ansible-lint`

A **sensible default** config (not modifying any existing file):

- `exclude_paths`: `.cache/`, `.github/`, `molecule/*/create.yml`, `molecule/*/destroy.yml`
- `enable_list`: `yaml`, `no-changed-when`, `command-instead-of-module`
- `warn_list`: common rules that may need project tuning
- `skip_list`: empty (user adds their own)
- Comment pointing user to customize for their project

### Step 7: Create Custom Commands (`.claude/commands/`)

5 slash commands:

| Command | Purpose |
|---------|---------|
| `/init` | Discover project conventions, generate `docs/ansible-conventions.md` |
| `/new-role <name>` | Scaffold role following discovered conventions (or sensible defaults) |
| `/lint [path]` | Run full yamllint + ansible-lint, summarize findings |
| `/test-role <name>` | Run `molecule test` for a specific role |
| `/validate [playbook]` | Full pipeline: lint + syntax-check + dry-run |

The `/new-role` command should:
- Read `docs/ansible-conventions.md` if it exists to determine naming, structure, platform targets
- Fall back to generic defaults if no conventions file exists
- Scaffold Molecule scenario using project's detected driver/platforms (or Docker + generic Linux images)

### Step 8: Create Molecule Templates (generic)

Per-role molecule scenario template using:
- **Driver**: Docker (most portable default)
- **Platforms**: Generic Linux images — suggest common options but don't hardcode a specific distro
  - Template includes commented examples for Ubuntu, Debian, Rocky, RHEL, Amazon Linux
  - `/init` detects the project's actual targets and `/new-role` uses them
- **Privileged containers** with cgroup mounts (needed for systemd roles)
- **Test sequence**: dependency → lint → destroy → syntax → create → converge → **idempotence** → verify → destroy
- **converge.yml**: Standard play applying the role
- **verify.yml**: Placeholder with service facts check

### Step 9: Create GitHub Actions CI/CD

**File**: `.github/workflows/ansible-ci.yml`

Three jobs:

1. **lint** — yamllint + ansible-lint + syntax-check on all playbooks
2. **molecule** — Matrix strategy: auto-detect roles, generic platform matrix (user customizes)
3. **integration** — Optional full-stack molecule test (runs after molecule passes)

Triggers: push to main + all PRs to main.

Matrix platform is parameterized — user fills in their target distros after running `/init`.

### Step 10: Create `.gitignore`

Standard entries for Ansible projects:
- Molecule artifacts (`.molecule/`, `.cache/`)
- Python (`__pycache__/`, `*.pyc`, `.venv/`, `*.egg-info/`)
- Claude Code local settings (`.claude/settings.local.json`)
- Ansible retry files (`*.retry`)
- Vault temp files

### Step 11: Create `plugin.json` and `README.md`

- **`.claude-plugin/plugin.json`**: Standard plugin manifest (name: `ansible`, version, description, keywords)
- **`README.md`**: User documentation — features, commands, setup instructions, prerequisites

---

## Verification Plan

After implementation, verify each component:

1. **`/init`**: Run against a sample Ansible project — verify it discovers conventions accurately
2. **CLAUDE.md**: Ask Claude Code to create a test role — verify it follows universal rules and reads conventions file
3. **MCP servers**: Run `pip install mcp-ansible ansible-dev-tools` and confirm `.mcp.json` loads
4. **Hooks**: Edit a YAML file and confirm lint output appears; try `ansible-playbook -i inventories/production/hosts` in bash and confirm it's blocked
5. **Pre-commit**: Run `pre-commit run --all-files` and verify yamllint + ansible-lint execute
6. **Commands**: Test `/init`, `/new-role test-role`, `/lint`, `/validate`
7. **Molecule**: Run `molecule test` in a role directory with Docker driver
8. **GitHub Actions**: Push a branch and verify the CI pipeline runs

---

## Prerequisites (user must install)

```bash
pip install ansible-core ansible-lint yamllint molecule molecule-plugins[docker] docker mcp-ansible ansible-dev-tools
pre-commit install
```

Docker Desktop must be running for Molecule tests.
