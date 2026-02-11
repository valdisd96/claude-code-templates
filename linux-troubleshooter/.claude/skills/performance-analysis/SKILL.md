---
description: "Activate when user mentions slow server, high load, performance problems, bottlenecks, high CPU, high memory usage, or server lagging on a Linux server"
---

# Performance Analysis

When the user reports performance problems, use the USE method (Utilization, Saturation, Errors) to systematically identify bottlenecks.

## USE Method Overview

For each resource (CPU, memory, disk, network), check:
- **Utilization**: How busy is the resource? (percentage used)
- **Saturation**: Is work queuing up? (queue lengths, wait times)
- **Errors**: Are there failures? (dropped packets, I/O errors, OOM kills)

## CPU Analysis

```bash
# Utilization
uptime                          # Load averages (1/5/15 min)
nproc                           # Number of cores
top -bn1 | head -5              # CPU breakdown (us/sy/wa/id)

# Saturation
cat /proc/loadavg               # Load > nproc means saturated
vmstat 1 3                      # Check 'r' column (run queue)

# Errors
dmesg -T 2>/dev/null | grep -i "mce\|hardware error" | tail -5
```

**Interpretation:**
- Load average < nproc: CPU is fine
- Load average 1-2x nproc: Moderate pressure
- Load average > 2x nproc: CPU saturated, processes queuing
- High `%wa` in top: CPU waiting on I/O (disk bottleneck, not CPU)

**Top CPU consumers:**
```bash
ps aux --sort=-%cpu | head -15
```

## Memory Analysis

```bash
# Utilization
free -h                         # Used vs available
cat /proc/meminfo | grep -E "MemTotal|MemAvailable|SwapTotal|SwapFree|Buffers|Cached"

# Saturation
vmstat 1 3                      # Check 'si'/'so' columns (swap in/out)
cat /proc/vmstat | grep -E "pgpgin|pgpgout|pswpin|pswpout"

# Errors
dmesg -T 2>/dev/null | grep -i "oom\|out of memory" | tail -5
```

**Interpretation:**
- `MemAvailable` is the real indicator (not `MemFree`)
- Active swapping (`si`/`so` > 0 in vmstat): Memory saturated
- OOM kills in dmesg: Critical memory pressure

**Top memory consumers:**
```bash
ps aux --sort=-%mem | head -15
```

## Disk I/O Analysis

```bash
# Utilization
iostat -xz 1 2 2>/dev/null     # %util per device

# Saturation
iostat -xz 1 2 2>/dev/null     # avgqu-sz (queue size), await (wait time)

# Errors
dmesg -T 2>/dev/null | grep -i "I/O error\|read error\|write error" | tail -5
```

**Interpretation:**
- `%util` > 80%: Disk is busy
- `await` > 20ms (HDD) or > 5ms (SSD): High latency
- `avgqu-sz` > 1: I/O requests queuing

**Top I/O consumers (if iotop available):**
```bash
iotop -b -n 1 2>/dev/null | head -15
```

## Network Analysis

```bash
# Utilization (rough check)
cat /proc/net/dev | column -t

# Saturation
ss -s                           # Socket statistics (overflows, drops)
netstat -s 2>/dev/null | grep -i -E "drop|overflow|retransmit" | head -10

# Errors
ip -s link show                 # Per-interface errors, drops
dmesg -T 2>/dev/null | grep -i "network\|link\|eth\|NIC" | tail -5
```

## Common Performance Patterns

| Symptom | Likely Bottleneck | Key Diagnostic |
|---------|------------------|----------------|
| High load, high `%us` | CPU-bound process | `ps aux --sort=-%cpu` |
| High load, high `%wa` | Disk I/O bottleneck | `iostat -xz 1 2` |
| High load, high `%sy` | Kernel overhead (many syscalls) | Check for fork storms, heavy I/O |
| Server responsive but slow | Memory pressure / swapping | `vmstat 1 3` (check si/so) |
| Intermittent slowness | Periodic job consuming resources | `atop` history or cron schedule |
| Everything slow | Network saturation | `ss -s`, `ip -s link show` |

## Quick One-Liner Summary

Get a fast performance snapshot:
```bash
uptime && free -h && df -h / && iostat -xz 1 1 2>/dev/null | tail -5
```

## Always Diagnose Before Recommending

Run the diagnostics above first. Don't suggest killing processes or restarting services until you've identified the actual bottleneck. Present findings with data, then propose actions and wait for user confirmation.
