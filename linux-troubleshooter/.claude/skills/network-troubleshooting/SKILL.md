---
description: "Activate when user mentions network issues, connectivity problems, DNS resolution failures, firewall blocking, port unreachable, timeout errors, or routing problems on a Linux server"
---

# Network Troubleshooting

When the user reports a network problem, diagnose systematically from the bottom of the OSI model up.

## Diagnostic Ladder (Bottom-Up)

### Layer 1-2: Link & Interface
```bash
ip link show
ip addr show
```
Check: Are interfaces UP? Do they have IP addresses?

### Layer 3: IP & Routing
```bash
ip route show
ping -c 2 -W 2 GATEWAY_IP
ping -c 2 -W 2 8.8.8.8
```
Check: Is the default route present? Can we reach the gateway? Can we reach the internet?

### Layer 4: DNS
```bash
cat /etc/resolv.conf
dig +short google.com 2>/dev/null || nslookup google.com 2>/dev/null
```
Check: Are DNS servers configured? Do they respond?

### Layer 5-7: Application
```bash
ss -tulnp
curl -s -o /dev/null -w "%{http_code}" http://TARGET 2>/dev/null
```
Check: Is the service listening? Does it respond?

## Common Issues Table

| Symptom | Likely Cause | Diagnostic |
|---------|-------------|------------|
| No route to host | Missing route or interface down | `ip route show`, `ip link show` |
| Connection refused | Service not listening on that port | `ss -tlnp \| grep PORT` |
| Connection timed out | Firewall blocking or host down | `iptables -L -n`, `ping HOST` |
| Name resolution failed | DNS misconfigured | `cat /etc/resolv.conf`, `dig HOST` |
| Intermittent connectivity | Packet loss or MTU issues | `ping -c 20 HOST`, `ip link show` (check MTU) |
| Slow connections | Network saturation or high latency | `ping HOST` (check RTT), `ss -s` (check socket stats) |

## Firewall Checks

Detect which firewall is active:
```bash
# Check in order
iptables -L -n 2>/dev/null | head -5
nft list ruleset 2>/dev/null | head -5
ufw status 2>/dev/null
firewall-cmd --state 2>/dev/null
```

To check if a specific port is allowed:
```bash
iptables -L -n 2>/dev/null | grep PORT
```

## Port Connectivity Test

Test if a remote port is reachable from the server:
```bash
timeout 5 bash -c "echo >/dev/tcp/HOST/PORT" 2>/dev/null && echo "OPEN" || echo "CLOSED/FILTERED"
```

Or with netcat if available:
```bash
nc -zv -w5 HOST PORT 2>&1
```

## DNS Deep Dive

If DNS is the problem:
```bash
# Check configured resolvers
cat /etc/resolv.conf

# Test each resolver
dig @RESOLVER_IP google.com +short +time=2

# Check /etc/hosts for overrides
grep -v "^#\|^$" /etc/hosts

# Check nsswitch order
grep "^hosts:" /etc/nsswitch.conf
```

## Always Use ssh-mcp

All network diagnostics on remote servers must go through the server's `exec` MCP tool. Never use local `ssh` or `scp` commands.
