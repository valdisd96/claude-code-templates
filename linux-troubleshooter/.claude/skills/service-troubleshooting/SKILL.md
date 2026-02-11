---
description: "Activate when user mentions a service not starting, crashing, restarting repeatedly, systemd failures, process issues, or application errors on a Linux server"
---

# Service Troubleshooting

When the user reports a service problem, diagnose the service state, check logs, and investigate the process.

## Quick Status Check

```bash
systemctl status SERVICE --no-pager -l
```

This single command reveals: active/failed state, PID, memory, recent log lines, and how long it's been in that state.

## Service States & What They Mean

| State | Meaning | Next Step |
|-------|---------|-----------|
| `active (running)` | Service is up | Check if it's actually healthy (port open, responding) |
| `active (exited)` | Ran and completed | Normal for oneshot services; check if it should be long-running |
| `inactive (dead)` | Not running | Check if it's enabled: `systemctl is-enabled SERVICE` |
| `failed` | Crashed or failed to start | Check logs: `journalctl -u SERVICE --no-pager -n 50` |
| `activating (auto-restart)` | Crash loop | Service keeps crashing and restarting |

## Crash Analysis

For a failed or crash-looping service:

```bash
# Recent logs
journalctl -u SERVICE --since "10 min ago" --no-pager | tail -50

# Look for the fatal error
journalctl -u SERVICE --no-pager | grep -i -E "fatal|error|failed|exception|panic|segfault" | tail -10

# Check for OOM kills
dmesg -T 2>/dev/null | grep -i "oom\|killed process" | tail -5
journalctl -k --since "10 min ago" --no-pager 2>/dev/null | grep -i oom | tail -5

# Check exit code
systemctl show SERVICE --property=ExecMainStatus
```

## Process Investigation

If the service is running but misbehaving:

```bash
# Find PID
systemctl show SERVICE --property=MainPID

# Resource usage
ps -p PID -o pid,%cpu,%mem,vsz,rss,etime,command

# Open connections
lsof -p PID -i 2>/dev/null | head -20

# File descriptor count vs limit
ls /proc/PID/fd 2>/dev/null | wc -l
grep "open files" /proc/PID/limits 2>/dev/null
```

## Config Test Commands

Before suggesting a restart, test the config:

| Service | Config Test Command |
|---------|-------------------|
| nginx | `nginx -t` |
| apache | `apachectl configtest` or `httpd -t` |
| haproxy | `haproxy -c -f /etc/haproxy/haproxy.cfg` |
| sshd | `sshd -t` |
| postfix | `postfix check` |
| named/bind | `named-checkconf` |

## Common Patterns

**Port already in use:**
```bash
ss -tlnp | grep PORT
# Find and show what's using the port
```

**Missing dependency (library, socket, other service):**
```bash
systemctl cat SERVICE 2>/dev/null | grep -E "After=|Requires=|Wants="
journalctl -u SERVICE --no-pager | grep -i "cannot\|not found\|missing" | tail -5
```

**Permission denied:**
```bash
# Check what user the service runs as
systemctl show SERVICE --property=User,Group
# Check file ownership on config/data dirs
ls -la /etc/SERVICE/ /var/lib/SERVICE/ /var/log/SERVICE/ 2>/dev/null
```

## Never Restart Without Asking

Always present findings and ask the user before running `systemctl restart`, `systemctl stop`, or `kill`. Explain what you found and why a restart might help.
