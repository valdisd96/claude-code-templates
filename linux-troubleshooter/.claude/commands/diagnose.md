# Diagnose Linux Server

Full system health check across CPU, memory, disk, network, and services.

## Arguments
- `$ARGUMENTS`: Optional - server name (e.g., "server-web1") or "all" for every configured server

## Execution Steps

### Phase 1: Server Selection & Distro Detection

If `$ARGUMENTS` specifies a server, use that server's MCP tools. If "all" or empty, ask the user which server(s) to check.

On each target server, run:
```bash
cat /etc/os-release
uname -r
uptime
hostname
```

Identify the distribution and package manager for distro-specific commands later.

### Phase 2: Resource Health

Run these commands via the server's `exec` MCP tool:

**CPU & Load:**
```bash
nproc
cat /proc/loadavg
ps aux --sort=-%cpu | head -10
```

Classify load average: OK (< nproc), WARNING (1-2x nproc), CRITICAL (> 2x nproc).

**Memory:**
```bash
free -h
ps aux --sort=-%mem | head -10
```

Classify memory: OK (< 80% used), WARNING (80-90%), CRITICAL (> 90%).

**Disk:**
```bash
df -h
df -i
```

Classify per-filesystem: OK (< 80%), WARNING (80-90%), CRITICAL (> 90%). Check inodes too.

### Phase 3: Network & Services

**Network:**
```bash
ip addr show
ss -tulnp
ping -c 2 -W 2 8.8.8.8
```

Flag: interfaces down, no external connectivity, unexpected listening ports.

**Services:**
```bash
systemctl list-units --type=service --state=failed 2>/dev/null
systemctl list-units --type=service --state=running 2>/dev/null | wc -l
```

Flag any failed services as CRITICAL.

### Phase 4: Recent Errors

```bash
journalctl -p err --since "1 hour ago" --no-pager 2>/dev/null | tail -20
dmesg -T 2>/dev/null | tail -15
```

Look for OOM kills, hardware errors, segfaults, or filesystem errors.

### Phase 5: Generate Report

```
═══════════════════════════════════════════════════════════
LINUX SERVER DIAGNOSIS: [hostname]
═══════════════════════════════════════════════════════════

System: [distro] [version] | Kernel: [version] | Uptime: [time]

Resource Summary:
  CPU Load:    [value] / [nproc] cores    [OK/WARNING/CRITICAL]
  Memory:      [used] / [total]           [OK/WARNING/CRITICAL]
  Swap:        [used] / [total]           [OK/WARNING/CRITICAL]

Disk Usage:
  /            [used%]                    [OK/WARNING/CRITICAL]
  /var         [used%]                    [OK/WARNING/CRITICAL]
  [other]      [used%]                    [OK/WARNING/CRITICAL]

Network:
  Interfaces:  [count] up, [count] down
  Connectivity: [OK/FAILED]
  Listening:    [count] ports

Services:
  Running:     [count]
  Failed:      [count]                    [OK/CRITICAL]
  [list failed services if any]

Recent Errors: [count in last hour]
  [top 3 error summaries if any]

Issues Found:
  [CRITICAL] [description]
  [WARNING]  [description]

Recommendations:
  1. [Action based on findings]
  2. [Action based on findings]

Next Steps:
  - /troubleshoot-disk for disk issues
  - /troubleshoot-network for network issues
  - /troubleshoot-service [name] for service failures
  - /analyze-logs for detailed log analysis
═══════════════════════════════════════════════════════════
```
