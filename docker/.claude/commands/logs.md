# View Container Logs

View and analyze Docker container logs with filtering options.

## Arguments
- `$ARGUMENTS`: Container name or ID, optionally followed by flags like "100" for tail lines

## Execution Steps

### Phase 1: Identify Container

```bash
CONTAINER=$(echo "$ARGUMENTS" | awk '{print $1}')

if [ -z "$CONTAINER" ]; then
    echo "=== Running Containers ==="
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
    echo ""
    echo "Specify a container name to view logs"
    exit 0
fi

# Verify container exists
docker inspect "$CONTAINER" > /dev/null 2>&1 || {
    echo "Container '$CONTAINER' not found"
    echo ""
    echo "=== Available Containers ==="
    docker ps -a --format "table {{.Names}}\t{{.Status}}"
    exit 1
}
```

### Phase 2: Get Container Info

```bash
echo "=== Container: $CONTAINER ==="
docker inspect "$CONTAINER" --format '
Image: {{.Config.Image}}
Status: {{.State.Status}}
Started: {{.State.StartedAt}}
Restarts: {{.RestartCount}}
' 2>/dev/null
```

### Phase 3: Fetch Logs

```bash
# Parse optional line count from arguments
LINES=$(echo "$ARGUMENTS" | grep -oE '[0-9]+' | head -1)
LINES=${LINES:-100}

echo ""
echo "=== Last $LINES Log Lines (with timestamps) ==="
docker logs --tail "$LINES" --timestamps "$CONTAINER" 2>&1
```

### Phase 4: Error Analysis

```bash
echo ""
echo "=== Error Summary ==="
docker logs "$CONTAINER" 2>&1 | grep -iE "(error|exception|fatal|failed|panic|crash)" | tail -20

echo ""
echo "=== Warning Summary ==="
docker logs "$CONTAINER" 2>&1 | grep -iE "(warn|warning)" | tail -10
```

## Output Format

Provide:
1. Container status and metadata
2. Recent log output
3. Highlighted errors and warnings
4. Analysis of any issues found
5. Suggestions based on log patterns
