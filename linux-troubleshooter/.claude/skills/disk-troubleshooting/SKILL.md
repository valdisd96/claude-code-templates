---
description: "Activate when user mentions disk full, no space left on device, inode exhaustion, mount issues, filesystem errors, or storage problems on a Linux server"
---

# Disk Troubleshooting

When the user reports a disk or storage problem, follow this quick triage before suggesting fixes.

## Quick Triage Sequence

Run these in order on the affected server via its `exec` MCP tool:

```bash
df -h
df -i
```

This immediately tells you: is it a space problem or an inode problem?

## Space Problem (df -h shows >90%)

Find what's consuming space:
```bash
du -sh /* 2>/dev/null | sort -rh | head -10
```

Then drill into the largest directory. Common culprits:

| Location | Typical Cause | Quick Check |
|----------|---------------|-------------|
| `/var/log` | Unrotated logs | `du -sh /var/log/* \| sort -rh \| head -5` |
| `/var/lib/docker` | Docker images/volumes | `docker system df 2>/dev/null` |
| `/tmp` | Abandoned temp files | `find /tmp -mtime +7 -type f 2>/dev/null \| head -20` |
| `/home` | User data | `du -sh /home/* 2>/dev/null \| sort -rh` |
| `/var/lib/mysql` | Database growth | `du -sh /var/lib/mysql/* 2>/dev/null \| sort -rh` |

### Deleted-but-Open Files

A common gotcha: files deleted from disk but still held open by a process. They consume space until the process releases them.

```bash
lsof +L1 2>/dev/null | head -20
```

Fix: restart the process holding the file, or truncate it (requires confirmation):
```bash
# Show the file - requires user confirmation to truncate
truncate -s 0 /path/to/file
```

## Inode Problem (df -i shows >90%)

Find directories with the most files:
```bash
find / -xdev -printf '%h\n' 2>/dev/null | sort | uniq -c | sort -rn | head -10
```

Common inode hogs:
- PHP session files in `/tmp` or `/var/lib/php/sessions`
- Mail queue in `/var/spool`
- Cache directories with millions of small files

## Filesystem Errors

Check kernel logs:
```bash
dmesg -T 2>/dev/null | grep -i -E "ext4|xfs|filesystem|I/O error|read-only" | tail -10
```

If filesystem remounted read-only, this is critical - likely hardware or filesystem corruption. Recommend:
1. Check `smartctl -a /dev/sdX` for disk health (requires sudo)
2. Schedule `fsck` during maintenance window
3. Consider migrating data if disk is failing

## Always Confirm Before Cleanup

Never delete files or truncate logs without asking the user first. Present findings and proposed actions, then wait for approval.
