# Security Audit

Assess server security: users, SSH config, open ports, file permissions, and kernel hardening.

## Arguments
- `$ARGUMENTS`: Optional - server name or specific focus area (e.g., "server-web1", "ssh config on server-db1", "all servers")

## Execution Steps

### Phase 1: Server Selection & System Info

Select the target server from `$ARGUMENTS` or ask the user.

```bash
cat /etc/os-release
uname -r
uptime
```

### Phase 2: User & Authentication Audit

**Root and privileged users:**
```bash
# Users with UID 0 (root-level)
awk -F: '$3 == 0 {print $1}' /etc/passwd

# Users with shell access
awk -F: '$7 !~ /nologin|false|sync|shutdown|halt/ {print $1, $7}' /etc/passwd

# Users in sudo/wheel group
getent group sudo 2>/dev/null || getent group wheel 2>/dev/null

# Recently logged in users
last -10 2>/dev/null
lastlog 2>/dev/null | grep -v "Never" | head -20
```

**Failed login attempts:**
```bash
grep "Failed password" /var/log/auth.log 2>/dev/null | tail -10 || grep "Failed password" /var/log/secure 2>/dev/null | tail -10
lastb 2>/dev/null | head -10
```

### Phase 3: SSH Configuration

```bash
grep -v "^#\|^$" /etc/ssh/sshd_config 2>/dev/null
```

Check critical settings:
```bash
grep -i "^PermitRootLogin" /etc/ssh/sshd_config 2>/dev/null
grep -i "^PasswordAuthentication" /etc/ssh/sshd_config 2>/dev/null
grep -i "^PubkeyAuthentication" /etc/ssh/sshd_config 2>/dev/null
grep -i "^Port " /etc/ssh/sshd_config 2>/dev/null
grep -i "^MaxAuthTries" /etc/ssh/sshd_config 2>/dev/null
grep -i "^AllowUsers\|^AllowGroups" /etc/ssh/sshd_config 2>/dev/null
```

Check for authorized_keys:
```bash
find /home -name "authorized_keys" -type f 2>/dev/null
cat /root/.ssh/authorized_keys 2>/dev/null | wc -l
```

### Phase 4: Open Ports & Network Exposure

```bash
ss -tulnp
```

Check for unexpected external listeners (bound to 0.0.0.0 or ::):
```bash
ss -tulnp | grep -E "0\.0\.0\.0|:::" | grep -v "127\."
```

Firewall status:
```bash
iptables -L -n 2>/dev/null | head -30
ufw status verbose 2>/dev/null
firewall-cmd --list-all 2>/dev/null
nft list ruleset 2>/dev/null | head -30
```

### Phase 5: File Permissions & SUID/SGID

**SUID binaries (potential privilege escalation):**
```bash
find / -perm -4000 -type f 2>/dev/null | head -30
```

**SGID binaries:**
```bash
find / -perm -2000 -type f 2>/dev/null | head -20
```

**World-writable directories (excluding /tmp and /var/tmp):**
```bash
find / -xdev -type d -perm -0002 ! -path "/tmp*" ! -path "/var/tmp*" 2>/dev/null | head -15
```

**Sensitive file permissions:**
```bash
stat -c "%a %U %G %n" /etc/passwd /etc/shadow /etc/sudoers 2>/dev/null
stat -c "%a %U %G %n" /etc/ssh/sshd_config 2>/dev/null
```

### Phase 6: Kernel & System Hardening

```bash
# IP forwarding
cat /proc/sys/net/ipv4/ip_forward
cat /proc/sys/net/ipv6/conf/all/forwarding 2>/dev/null

# ASLR
cat /proc/sys/kernel/randomize_va_space

# SYN cookies
cat /proc/sys/net/ipv4/tcp_syncookies

# Core dumps
cat /proc/sys/kernel/core_pattern

# SELinux / AppArmor
getenforce 2>/dev/null || aa-status 2>/dev/null | head -5
```

Check for pending security updates (distro-dependent):
```bash
# Debian/Ubuntu
apt list --upgradable 2>/dev/null | grep -i securi | head -10
# RHEL/CentOS
yum updateinfo list security 2>/dev/null | head -10
```

### Phase 7: Generate Report

```
═══════════════════════════════════════════════════════════
SECURITY AUDIT: [hostname]
═══════════════════════════════════════════════════════════

System: [distro] [version] | Kernel: [version]

User Accounts:
  Root-level (UID 0):      [count]     [OK/WARNING]
  Shell access:            [count]     [INFO]
  Sudo/wheel members:      [list]
  Failed logins (24h):     [count]     [OK/WARNING/CRITICAL]

SSH Configuration:
  PermitRootLogin:         [yes/no]    [OK/CRITICAL]
  PasswordAuthentication:  [yes/no]    [OK/WARNING]
  PubkeyAuthentication:    [yes/no]    [OK/WARNING]
  Port:                    [number]    [INFO]
  MaxAuthTries:            [number]    [OK/WARNING]

Network Exposure:
  External listeners:      [count]     [INFO]
  [port]  [process]  [bound to]
  ...
  Firewall:                [active/inactive] [OK/CRITICAL]

File Permissions:
  SUID binaries:           [count]     [OK/WARNING]
  SGID binaries:           [count]     [INFO]
  World-writable dirs:     [count]     [OK/WARNING]
  /etc/shadow readable:    [yes/no]    [OK/CRITICAL]

Kernel Hardening:
  ASLR:                    [enabled/disabled]  [OK/CRITICAL]
  IP forwarding:           [on/off]    [INFO/WARNING]
  SYN cookies:             [on/off]    [OK/WARNING]
  SELinux/AppArmor:        [status]    [OK/WARNING]

Pending Security Updates:  [count]     [OK/WARNING/CRITICAL]

Issues Found:
  [CRITICAL] [description]
  [WARNING]  [description]

Recommendations:
  1. [Specific hardening action]
  2. [Specific hardening action]

NOTE: Configuration changes require your confirmation before execution.
═══════════════════════════════════════════════════════════
```
