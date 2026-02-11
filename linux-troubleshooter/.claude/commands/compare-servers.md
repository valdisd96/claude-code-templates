# Compare Servers

Run the same diagnostics across multiple servers and identify drift, imbalances, or inconsistencies.

## Arguments
- `$ARGUMENTS`: Optional - specific comparison focus (e.g., "disk usage", "installed packages", "running services", "security config")

## Execution Steps

### Phase 1: Server Discovery

List all configured servers from `.mcp.json`. If only one server is configured, inform the user that comparison requires at least two servers.

For each server, collect baseline info:
```bash
cat /etc/os-release
uname -r
hostname
uptime
```

### Phase 2: Parallel Data Collection

Run the same commands on every server. Scope depends on `$ARGUMENTS`:

**Default (full comparison):**
```bash
# Resources
free -h
df -h
cat /proc/loadavg
nproc

# Services
systemctl list-units --type=service --state=running 2>/dev/null | awk '{print $1}' | sort
systemctl list-units --type=service --state=failed 2>/dev/null | awk '{print $1}' | sort

# Network
ss -tulnp | awk '{print $1, $4, $5, $7}' | sort

# Packages (count)
dpkg -l 2>/dev/null | wc -l || rpm -qa 2>/dev/null | wc -l

# Kernel
uname -r

# Security
grep -i "^PermitRootLogin" /etc/ssh/sshd_config 2>/dev/null
grep -i "^PasswordAuthentication" /etc/ssh/sshd_config 2>/dev/null
```

**If focused on a specific area**, run only the relevant subset.

### Phase 3: Diff & Analysis

Compare results across servers:
- **Resource imbalances**: Memory or CPU load significantly different between similar-role servers
- **Service drift**: Services running on one server but not another
- **Package drift**: Different package counts or kernel versions
- **Config drift**: Different SSH or security settings
- **Port differences**: Different listening ports

### Phase 4: Generate Report

```
═══════════════════════════════════════════════════════════
SERVER COMPARISON REPORT
═══════════════════════════════════════════════════════════

Servers Compared: [count]
  [server-1]: [distro] [version] | Kernel [version] | Up [uptime]
  [server-2]: [distro] [version] | Kernel [version] | Up [uptime]
  [server-3]: [distro] [version] | Kernel [version] | Up [uptime]

Resource Comparison:
                    [server-1]    [server-2]    [server-3]
  CPU cores         4             4             8
  Load (1m)         0.5           3.2 ⚠        0.8
  Memory used       62%           88% ⚠        45%
  Disk / used       72%           91% ⚠        55%
  Swap used         0%            25% ⚠        0%

Service Drift:
  Running on all:        [count] services
  Only on [server-1]:    [service list]
  Only on [server-2]:    [service list]
  Failed on [server-2]:  [service list] ⚠

Package Drift:
  [server-1]: [count] packages, kernel [version]
  [server-2]: [count] packages, kernel [version] ⚠ (different)
  [server-3]: [count] packages, kernel [version]

Network Drift:
  Ports on all:          22, 80, 443
  Only on [server-1]:    8080
  Only on [server-2]:    3306

Security Config Drift:
  PermitRootLogin:
    [server-1]: no     [server-2]: yes ⚠    [server-3]: no
  PasswordAuth:
    [server-1]: no     [server-2]: no        [server-3]: yes ⚠

Issues Found:
  [CRITICAL] [server-2] disk at 91% - significantly higher than peers
  [WARNING]  [server-2] different kernel version from fleet
  [WARNING]  [server-2] PermitRootLogin enabled (others have it disabled)

Recommendations:
  1. [Specific action to resolve drift]
  2. [Specific action for resource imbalance]
═══════════════════════════════════════════════════════════
```
