# Troubleshoot Disk

Diagnose disk space, inodes, I/O performance, and filesystem health.

## Arguments
- `$ARGUMENTS`: Optional - server name and/or specific issue (e.g., "server-app1 disk full", "/var running out of space")

## Execution Steps

### Phase 1: Server Selection & Disk Overview

Select the target server from `$ARGUMENTS` or ask the user.

```bash
cat /etc/os-release
df -h
df -i
lsblk
```

Identify all filesystems, their usage, and block device layout.

### Phase 2: Space Analysis

Find largest consumers on any filesystem above 80%:

```bash
du -sh /* 2>/dev/null | sort -rh | head -15
```

For the most-used filesystem (e.g., `/var`):
```bash
du -sh /var/* 2>/dev/null | sort -rh | head -15
du -sh /var/log/* 2>/dev/null | sort -rh | head -10
```

Check for large files:
```bash
find /var/log -type f -size +100M 2>/dev/null
find /tmp -type f -size +100M 2>/dev/null
```

Check for deleted-but-open files still consuming space:
```bash
lsof +L1 2>/dev/null | head -20
```

### Phase 3: Inode Analysis

If inode usage is high (>80%):
```bash
# Find directories with most files
find / -xdev -printf '%h\n' 2>/dev/null | sort | uniq -c | sort -rn | head -15
```

Common inode hogs: `/var/spool/mail`, `/tmp`, session files, cache directories.

### Phase 4: I/O Performance

```bash
iostat -xz 1 2 2>/dev/null
vmstat 1 3
cat /proc/diskstats | head -20
```

Look for: high `%util` (>80%), high `await` (>20ms), high I/O wait in vmstat.

Check for I/O-heavy processes:
```bash
iotop -b -n 1 2>/dev/null | head -15
```

### Phase 5: Filesystem Health

```bash
mount | column -t
cat /etc/fstab
dmesg -T 2>/dev/null | grep -i -E "ext4|xfs|btrfs|filesystem|I/O error" | tail -10
```

Check for read-only remounts (sign of filesystem errors):
```bash
mount | grep "ro,"
```

### Phase 6: Generate Report

```
═══════════════════════════════════════════════════════════
DISK DIAGNOSTICS: [hostname]
═══════════════════════════════════════════════════════════

Filesystem Usage:
  Filesystem    Size   Used   Avail  Use%   Inodes%  Status
  /             50G    42G    8G     84%    12%      [WARNING]
  /var          20G    19G    1G     95%    45%      [CRITICAL]
  /tmp          5G     200M   4.8G   4%     1%       [OK]

Largest Consumers:
  /var/log      12G
  /var/lib      5G
  [...]

Large Files Found:
  /var/log/app.log    2.5G
  [...]

Deleted-but-Open Files: [count] consuming [total size]

I/O Performance:
  [device]  %util=[value]  await=[value]ms  [OK/WARNING/CRITICAL]

Issues Found:
  [CRITICAL] /var at 95% - dominated by /var/log (12G)
  [WARNING]  2 deleted files still held open (3.1G reclaimable)

Recommendations:
  1. [Specific action, e.g., "Rotate /var/log/app.log (2.5G)"]
  2. [Specific action, e.g., "Restart process PID 1234 to release deleted file"]

NOTE: Cleanup commands require your confirmation before execution.
═══════════════════════════════════════════════════════════
```
