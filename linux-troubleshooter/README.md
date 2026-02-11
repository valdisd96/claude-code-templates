# Linux Troubleshooter - Claude Code Configuration

Remote Linux server diagnostics and troubleshooting via SSH with multi-server support.

## Features

- **Full system diagnostics**: CPU, memory, disk, network, services, logs, security
- **Multi-server support**: Connect to multiple servers simultaneously, compare across hosts
- **Read-only by default**: `--disableSudo` prevents privileged commands; fixes require explicit confirmation
- **Cross-distro compatible**: Debian/Ubuntu, RHEL/CentOS, Alpine, SUSE
- **7 slash commands**: Structured diagnostic workflows with severity-rated reports
- **4 auto-triggered skills**: Claude automatically applies domain expertise when you describe problems

## Prerequisites

- **Node.js** (for ssh-mcp MCP server via npx)
- **SSH key-based access** to your target servers
- Servers must be reachable from your machine on port 22

## Installation

### Method 1: Script-Based

```bash
./apply-config.sh linux-troubleshooter /path/to/your-project
```

### Method 2: Plugin Marketplace

```bash
/plugin marketplace add uvauchok/claude-code-templates
/plugin install linux-troubleshooter@claude-code-templates
```

## Configuration

### Setting Up Your Servers

Edit `.mcp.json` to configure your servers. Each server is a separate MCP server instance:

```json
{
  "mcpServers": {
    "server-web1": {
      "command": "npx",
      "args": [
        "-y",
        "ssh-mcp",
        "--host=web1.example.com",
        "--username=deploy",
        "--key=~/.ssh/id_ed25519",
        "--timeout=30000",
        "--maxChars=none",
        "--disableSudo"
      ]
    }
  }
}
```

**Parameters:**
| Parameter | Description | Default |
|-----------|-------------|---------|
| `--host` | Server hostname or IP | Required |
| `--username` | SSH username | Required |
| `--key` | Path to SSH private key | `~/.ssh/id_ed25519` |
| `--timeout` | Command timeout in ms | `30000` (30s) |
| `--maxChars` | Max output characters | `none` (unlimited) |
| `--disableSudo` | Remove sudo capability | Present (safe default) |

### Enabling Sudo

To allow privileged commands on a specific server, remove `--disableSudo` from that server's args in `.mcp.json`. This enables the `sudo-exec` MCP tool for that server only.

### Adding More Servers

Copy any server block in `.mcp.json` and change the name, host, and username. Restart Claude Code to pick up the changes.

## Available Commands

| Command | Purpose |
|---------|---------|
| `/diagnose` | Full system health check with threshold-based severity ratings |
| `/troubleshoot-network` | Network connectivity, DNS, ports, routing, and firewall diagnostics |
| `/troubleshoot-disk` | Disk space, inodes, I/O performance, and filesystem health |
| `/troubleshoot-service [name]` | Service status, logs, process resources, and config checks |
| `/analyze-logs` | Log discovery, error extraction, and pattern detection |
| `/security-audit` | Users, SSH config, open ports, file permissions, kernel hardening |
| `/compare-servers` | Cross-server comparison for drift and resource imbalances |

## Auto-Triggered Skills

These activate automatically when you describe a problem in natural language:

| Skill | Triggers When You Mention |
|-------|---------------------------|
| Disk Troubleshooting | "disk full", "no space left", inode/mount issues |
| Network Troubleshooting | connectivity problems, DNS, firewall, timeouts |
| Service Troubleshooting | service not starting, crashing, systemd failures |
| Performance Analysis | slow server, high load, bottlenecks, high CPU/memory |

## Safety Model

1. **All remote commands go through ssh-mcp** - local `ssh`/`scp` commands are denied in settings.json
2. **`--disableSudo` is the default** - completely removes privileged command capability
3. **Read-only diagnostics** - all commands in the diagnostic workflows only read system state
4. **Confirm before fixing** - the agent always presents findings and asks before making changes
5. **Dangerous commands blocked** - `rm -rf`, `mkfs`, `dd`, `shutdown` are explicitly denied

## Customization

### Adjusting Timeouts

For servers with slow storage or network, increase the timeout:
```
"--timeout=60000"
```

### Restricting Commands

Edit `.claude/settings.json` to add more denied commands or restrict allowed ones.

### Adding Custom Commands

Create new `.md` files in `.claude/commands/` following the phase-based structure of existing commands.

## License

MIT
