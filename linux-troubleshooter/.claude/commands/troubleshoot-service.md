# Troubleshoot Service

Diagnose a specific service: status, logs, resource usage, and configuration.

## Arguments
- `$ARGUMENTS`: Required - service name and optional server (e.g., "nginx", "server-web1 postgresql", "docker on server-app1")

## Execution Steps

### Phase 1: Server Selection & Service Discovery

Parse `$ARGUMENTS` for service name and server. If no server specified, ask the user.

```bash
cat /etc/os-release
```

Detect init system:
```bash
ps -p 1 -o comm= 2>/dev/null
```

### Phase 2: Service Status

For systemd:
```bash
systemctl status SERVICE --no-pager -l
systemctl is-enabled SERVICE
systemctl show SERVICE --property=ActiveState,SubState,MainPID,ExecStart,Restart,RestartSec
```

For OpenRC (Alpine):
```bash
rc-status
rc-service SERVICE status
```

Check if the service binary exists:
```bash
which SERVICE 2>/dev/null || command -v SERVICE 2>/dev/null
```

### Phase 3: Service Logs

Recent logs:
```bash
journalctl -u SERVICE --since "30 min ago" --no-pager 2>/dev/null | tail -50
```

If journalctl unavailable, check common log locations:
```bash
ls -la /var/log/SERVICE* 2>/dev/null
tail -50 /var/log/SERVICE/*.log 2>/dev/null
tail -50 /var/log/SERVICE.log 2>/dev/null
```

Look for crash patterns:
```bash
journalctl -u SERVICE --no-pager 2>/dev/null | grep -i -E "error|fatal|failed|crash|segfault|killed|oom" | tail -20
```

Check for OOM kills:
```bash
dmesg -T 2>/dev/null | grep -i "oom.*SERVICE\|killed process" | tail -5
```

### Phase 4: Process & Resource Analysis

If the service is running, check its resource usage:
```bash
# Find the PID
systemctl show SERVICE --property=MainPID 2>/dev/null
# Or find by name
pgrep -a SERVICE | head -5

# Resource usage
ps -p PID -o pid,ppid,%cpu,%mem,vsz,rss,stat,start,time,command 2>/dev/null

# Open files and connections
lsof -p PID 2>/dev/null | wc -l
lsof -p PID -i 2>/dev/null | head -20

# File descriptor count
ls /proc/PID/fd 2>/dev/null | wc -l
cat /proc/PID/limits 2>/dev/null | grep "open files"
```

### Phase 5: Configuration Check

Check for config syntax (service-specific):
```bash
# Nginx
nginx -t 2>&1
# Apache
apachectl configtest 2>&1 || httpd -t 2>&1
# PostgreSQL
pg_isready 2>/dev/null
# MySQL
mysqladmin status 2>/dev/null
# Docker
docker info 2>/dev/null | head -10
```

Check service config file location:
```bash
systemctl cat SERVICE 2>/dev/null | head -20
```

### Phase 6: Generate Report

```
═══════════════════════════════════════════════════════════
SERVICE DIAGNOSTICS: [service] on [hostname]
═══════════════════════════════════════════════════════════

Status:        [active (running) / failed / inactive]
Enabled:       [yes/no]
PID:           [pid]
Uptime:        [since when]
Restart Policy: [always/on-failure/no]

Resource Usage:
  CPU:     [%cpu]
  Memory:  [rss] ([%mem])
  FDs:     [count] / [limit]

Recent Errors (last 30 min):
  [timestamp] [error message]
  [...]

Config Test: [PASS/FAIL]
  [error details if failed]

Issues Found:
  [CRITICAL/WARNING] [description]

Root Cause Analysis:
  [Explanation based on findings]

Recommendations:
  1. [Specific fix]
  2. [Specific fix]

NOTE: Service restart/modification requires your confirmation.
═══════════════════════════════════════════════════════════
```
