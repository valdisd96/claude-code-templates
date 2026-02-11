# Analyze Logs

Discover log sources, extract errors, and detect patterns.

## Arguments
- `$ARGUMENTS`: Optional - server name, service name, time range, or keyword (e.g., "server-web1 nginx last 2 hours", "OOM errors on server-db1")

## Execution Steps

### Phase 1: Log Source Discovery

Select the target server from `$ARGUMENTS` or ask the user.

```bash
cat /etc/os-release
```

Discover available log sources:
```bash
# System journal
journalctl --disk-usage 2>/dev/null

# Log files
ls -lhS /var/log/*.log /var/log/*/*.log 2>/dev/null | head -20

# Identify active logs (modified in last 24h)
find /var/log -name "*.log" -mtime -1 -type f 2>/dev/null | head -20
```

### Phase 2: Error Extraction

If a specific service is mentioned, focus on that. Otherwise scan broadly:

**System-wide errors (last hour by default):**
```bash
journalctl -p err --since "1 hour ago" --no-pager 2>/dev/null | tail -50
```

**Kernel errors:**
```bash
dmesg -T 2>/dev/null | grep -i -E "error|fail|warn|oom|segfault|bug" | tail -20
```

**Syslog/messages:**
```bash
tail -200 /var/log/syslog 2>/dev/null || tail -200 /var/log/messages 2>/dev/null | grep -i -E "error|fail|crit|alert|emerg" | tail -30
```

**Auth/security logs:**
```bash
tail -100 /var/log/auth.log 2>/dev/null || tail -100 /var/log/secure 2>/dev/null | grep -i -E "fail|denied|invalid|error" | tail -20
```

If a specific service is mentioned:
```bash
journalctl -u SERVICE --since "1 hour ago" --no-pager 2>/dev/null | grep -i -E "error|fail|crit|warn" | tail -30
```

### Phase 3: Pattern & Frequency Analysis

Count error types:
```bash
journalctl -p err --since "1 hour ago" --no-pager 2>/dev/null | awk '{for(i=5;i<=NF;i++) printf "%s ", $i; print ""}' | sort | uniq -c | sort -rn | head -15
```

Check for repeated patterns (e.g., service crash loops):
```bash
journalctl --since "1 hour ago" --no-pager 2>/dev/null | grep -i "started\|stopped\|failed" | grep -i SERVICE | tail -20
```

Time-based analysis (error rate):
```bash
journalctl -p err --since "1 hour ago" --no-pager 2>/dev/null | awk '{print $1, $2, substr($3,1,5)}' | uniq -c | sort -rn | head -10
```

### Phase 4: Generate Report

```
═══════════════════════════════════════════════════════════
LOG ANALYSIS: [hostname]
═══════════════════════════════════════════════════════════

Time Range: [start] to [end]
Sources Analyzed: [list of log sources]

Error Summary:
  Total errors (last hour):  [count]
  Unique error types:        [count]

Top Errors by Frequency:
  [count]x  [error pattern]
  [count]x  [error pattern]
  [count]x  [error pattern]

Error Timeline:
  [time]  [count] errors  [spike indicator if applicable]
  [time]  [count] errors
  ...

Critical Findings:
  [CRITICAL] [description with timestamp and context]
  [WARNING]  [description]

Patterns Detected:
  - [Pattern description, e.g., "nginx 502 errors correlate with app1 OOM kills"]
  - [Pattern description]

Recommendations:
  1. [Action based on log findings]
  2. [Action based on log findings]

Next Steps:
  - /troubleshoot-service [name] for service-specific investigation
  - /security-audit if auth failures detected
═══════════════════════════════════════════════════════════
```
