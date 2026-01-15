# Troubleshoot Docker Issues

Diagnose Docker build failures, container issues, or runtime problems with solution suggestions.

## Arguments
- `$ARGUMENTS`: Error message, container name, or "build" for build issues

## Execution Steps

### Phase 1: Gather System Information

```bash
echo "=== Docker System Status ==="
docker version --format 'Client: {{.Client.Version}}, Server: {{.Server.Version}}' 2>&1 || echo "Docker daemon may not be running"

echo ""
echo "=== Docker Disk Usage ==="
docker system df 2>/dev/null

echo ""
echo "=== Running Containers ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null

echo ""
echo "=== Recent Container Exits ==="
docker ps -a --filter "status=exited" --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" | head -10
```

### Phase 2: Analyze Specific Issue

If troubleshooting a container:

```bash
CONTAINER="$ARGUMENTS"
if [ -n "$CONTAINER" ] && [ "$CONTAINER" != "build" ]; then
    echo "=== Container Details: $CONTAINER ==="
    docker inspect "$CONTAINER" --format '
    Status: {{.State.Status}}
    Exit Code: {{.State.ExitCode}}
    Error: {{.State.Error}}
    OOMKilled: {{.State.OOMKilled}}
    Started: {{.State.StartedAt}}
    Finished: {{.State.FinishedAt}}
    ' 2>/dev/null

    echo ""
    echo "=== Last 50 Log Lines ==="
    docker logs --tail 50 "$CONTAINER" 2>&1
fi
```

If troubleshooting build issues:

```bash
if [ "$ARGUMENTS" = "build" ] || [ -z "$ARGUMENTS" ]; then
    echo "=== Checking Dockerfile ==="
    if [ -f Dockerfile ]; then
        # Check for common issues
        echo "Analyzing Dockerfile for common problems..."

        # Check for latest tag
        grep -n "FROM.*:latest" Dockerfile && echo "WARNING: Using :latest tag"

        # Check for ADD instead of COPY
        grep -n "^ADD " Dockerfile && echo "WARNING: Consider using COPY instead of ADD for local files"

        # Check for missing USER instruction
        grep -q "^USER " Dockerfile || echo "WARNING: No USER instruction - container will run as root"

        # Check for apt-get without cleanup
        grep -n "apt-get install" Dockerfile | grep -v "rm -rf" && echo "WARNING: apt-get without cleanup"
    fi
fi
```

### Phase 3: Network and Resource Check

```bash
echo "=== Docker Networks ==="
docker network ls

echo ""
echo "=== Port Bindings ==="
docker ps --format "{{.Names}}: {{.Ports}}" | grep -v "^: $"

echo ""
echo "=== Resource Usage ==="
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null | head -10
```

### Phase 4: Provide Solutions

Based on the analysis, provide:
1. Root cause identification
2. Specific fix recommendations
3. Commands to resolve the issue
4. Prevention tips for future

## Common Solutions Reference

| Symptom | Likely Cause | Solution |
|---------|--------------|----------|
| "Cannot connect to Docker daemon" | Docker not running | `systemctl start docker` or start Docker Desktop |
| "no space left on device" | Disk full | `docker system prune` (after confirmation) |
| "port already allocated" | Port conflict | Stop conflicting container or use different port |
| "OOMKilled: true" | Out of memory | Increase container memory limit |
| "exec format error" | Architecture mismatch | Build with `--platform linux/amd64` |
| Build hangs at apt-get | DNS issues | Add `--network=host` to build |
