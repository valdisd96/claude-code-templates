# Troubleshoot Network

Diagnose network connectivity, DNS, ports, routing, and firewall issues.

## Arguments
- `$ARGUMENTS`: Optional - server name and/or specific issue (e.g., "server-web1 cannot reach db", "dns resolution failing")

## Execution Steps

### Phase 1: Server Selection & Interface Discovery

Select the target server from `$ARGUMENTS` or ask the user.

```bash
cat /etc/os-release
ip addr show
ip link show
```

Identify all interfaces, their states (UP/DOWN), and IP addresses.

### Phase 2: Connectivity Tests

**Local network:**
```bash
ip route show
ip neigh show
```

**External connectivity:**
```bash
ping -c 3 -W 2 8.8.8.8
ping -c 3 -W 2 1.1.1.1
```

**DNS resolution:**
```bash
cat /etc/resolv.conf
dig +short google.com 2>/dev/null || nslookup google.com 2>/dev/null
dig +short +trace google.com 2>/dev/null | tail -5
```

If the user reported a specific target, test connectivity to that target:
```bash
ping -c 3 -W 2 TARGET
traceroute -n -m 15 TARGET 2>/dev/null || tracepath TARGET 2>/dev/null
```

### Phase 3: Port Analysis

```bash
ss -tulnp
ss -tnp state established | head -20
```

If a specific port is mentioned:
```bash
ss -tlnp | grep PORT
```

Test if a remote port is reachable:
```bash
timeout 5 bash -c "echo >/dev/tcp/HOST/PORT" 2>/dev/null && echo "OPEN" || echo "CLOSED"
```

### Phase 4: Routing & Firewall

```bash
ip route show
ip rule show 2>/dev/null
```

Firewall rules (distro-dependent):
```bash
# Try in order
iptables -L -n -v 2>/dev/null | head -40
nft list ruleset 2>/dev/null | head -40
ufw status verbose 2>/dev/null
firewall-cmd --list-all 2>/dev/null
```

### Phase 5: Generate Report

```
═══════════════════════════════════════════════════════════
NETWORK DIAGNOSTICS: [hostname]
═══════════════════════════════════════════════════════════

Interfaces:
  [name]  [state]  [ip/mask]  [OK/DOWN]

Connectivity:
  Default gateway: [ip]          [REACHABLE/UNREACHABLE]
  Internet (8.8.8.8):            [OK/FAILED]
  DNS resolution:                [OK/FAILED]
  [Custom target]:               [OK/FAILED]

Listening Ports:
  [port]  [proto]  [process]
  ...

Firewall: [active/inactive/not-installed]
  [summary of rules if active]

Issues Found:
  [CRITICAL/WARNING] [description]

Diagnosis:
  [Root cause analysis based on findings]

Recommendations:
  1. [Fix based on findings]
  2. [Fix based on findings]
═══════════════════════════════════════════════════════════
```
