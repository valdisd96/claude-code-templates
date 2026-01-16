# Docker Container Management - Claude Code Configuration

A comprehensive Claude Code configuration for managing Docker containers, optimizing Dockerfiles, and troubleshooting container issues.

## Features

- **Build Management**: Build images with detailed output and automatic error analysis
- **Dockerfile Analysis**: Best practices review, security scanning, and optimization suggestions
- **Container Operations**: Execute commands, view logs, inspect containers
- **Docker Compose**: Validate and manage multi-container applications
- **Troubleshooting**: Diagnose build failures and runtime issues with solution suggestions
- **Safe Defaults**: Dangerous commands blocked by default, BuildKit enabled
- **MCP Integration**: Direct Docker API access via docker-mcp server

## Quick Start

### Installation

```bash
# Clone the templates repository
git clone https://github.com/uvauchok/claude-code-templates.git

# Apply to your project
./claude-code-templates/apply-config.sh docker /path/to/your/project

# Or install as plugin
/plugin marketplace add uvauchok/claude-code-templates
/plugin install docker@claude-code-templates
```

### Available Commands

| Command | Purpose |
|---------|---------|
| `/build` | Build Docker image with detailed output |
| `/analyze-dockerfile` | Review Dockerfile for best practices |
| `/troubleshoot` | Diagnose Docker issues |
| `/logs [container]` | View container logs |
| `/exec [container] [cmd]` | Run command in container |
| `/compose-up` | Start docker compose services |
| `/compose-validate` | Validate docker-compose.yml |

## Usage Examples

### Build an Image

```bash
# Build with default settings
/build

# Build with custom name
/build myapp:v1.0

# Build from specific Dockerfile
/build Dockerfile.prod
```

### Analyze Dockerfile

```bash
# Analyze default Dockerfile
/analyze-dockerfile

# Analyze specific file
/analyze-dockerfile Dockerfile.prod
```

### Troubleshoot Issues

```bash
# General diagnostics
/troubleshoot

# Troubleshoot specific container
/troubleshoot mycontainer

# Troubleshoot build issues
/troubleshoot build
```

### Container Operations

```bash
# View logs
/logs mycontainer
/logs mycontainer 500  # Last 500 lines

# Execute commands
/exec mycontainer ls -la
/exec mycontainer /bin/sh  # Interactive shell
```

### Docker Compose

```bash
# Start all services
/compose-up

# Start with rebuild
/compose-up build

# Validate configuration
/compose-validate
```

## Permissions

### Allowed (Auto-approved)

- All `docker build`, `docker run`, `docker exec` commands
- Container management: start, stop, restart, logs, inspect
- Image operations: list, tag, pull, push
- Docker Compose operations
- Basic file operations: ls, cat, grep, find

### Blocked (Safety)

- `rm -rf`, `rm -r` (recursive delete)
- `docker system prune -a` (removes all unused data)
- `docker volume prune/rm` (data loss)
- `docker kill`, `docker rmi -f` (force operations)
- System commands: sudo, shutdown, reboot
- Dangerous patterns: fork bombs, pipe to shell

## MCP Servers

This configuration includes three MCP servers for enhanced Docker management:

### docker-mcp

Direct Docker API access without shell commands:

| Tool | Description |
|------|-------------|
| `create-container` | Create standalone containers with image, ports, env config |
| `deploy-compose` | Deploy Docker Compose stacks from YAML configuration |
| `get-logs` | Retrieve container logs directly via API |
| `list-containers` | List all containers with status information |

**Prerequisites**: `uv` package manager, Docker running

### filesystem

Navigate and manage project files:
- Read/write Dockerfiles, docker-compose.yml, .dockerignore
- Browse project directory structure
- Access configuration files without shell commands

### memory

Persistent memory across sessions:
- Remember build configurations and preferences
- Track container states and troubleshooting history
- Store project-specific Docker context

### MCP Configuration

The `.mcp.json` file configures the servers:

```json
{
  "mcpServers": {
    "docker": {
      "command": "uvx",
      "args": ["docker-mcp"]
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "."]
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    }
  }
}
```

## Configuration Files

```
your-project/
├── CLAUDE.md           # Agent instructions (don't edit)
├── .mcp.json           # MCP server configuration
├── .claude/
│   ├── settings.json   # Permissions and env vars
│   └── commands/       # Slash commands
│       ├── build.md
│       ├── analyze-dockerfile.md
│       ├── troubleshoot.md
│       ├── logs.md
│       ├── exec.md
│       ├── compose-up.md
│       └── compose-validate.md
└── .claude-plugin/
    └── plugin.json     # Plugin manifest
```

## Environment Variables

The configuration sets these environment variables:

```json
{
  "DOCKER_BUILDKIT": "1",
  "COMPOSE_DOCKER_CLI_BUILD": "1"
}
```

This enables BuildKit for faster, more efficient builds.

## Best Practices Enforced

### Dockerfile Standards

- Use specific image tags (not `latest`)
- Run as non-root user
- Clean up package manager caches
- Use multi-stage builds for smaller images
- Order COPY instructions for cache efficiency

### Security

- Never expose secrets in Dockerfiles
- Use `.dockerignore` to exclude sensitive files
- Prefer COPY over ADD for local files
- Define resource limits in compose

### Optimization

- Combine RUN commands to reduce layers
- Use Alpine or slim base images
- Leverage build cache effectively

## Customization

### Adding Commands

Create new `.md` files in `.claude/commands/`:

```markdown
# My Custom Command

Description of what this command does.

## Arguments
- `$ARGUMENTS`: Description

## Execution Steps

### Phase 1: Setup
\`\`\`bash
# Your bash commands here
\`\`\`
```

### Modifying Permissions

Edit `.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "Bash(your-safe-command*)"
    ],
    "deny": [
      "Bash(dangerous-command*)"
    ]
  }
}
```

## Troubleshooting

### "Cannot connect to Docker daemon"

Docker is not running. Start it:
- macOS: Open Docker Desktop
- Linux: `sudo systemctl start docker`

### "Permission denied"

Add your user to the docker group:
```bash
sudo usermod -aG docker $USER
# Log out and back in
```

### Build context too large

Create or update `.dockerignore`:
```
.git
node_modules
*.log
```

## Contributing

Improvements welcome! See the main [claude-code-templates](https://github.com/uvauchok/claude-code-templates) repository.

## License

MIT
