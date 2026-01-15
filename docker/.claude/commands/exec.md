# Execute Command in Container

Run commands inside a running Docker container.

## Arguments
- `$ARGUMENTS`: Container name followed by command to execute (e.g., "myapp ls -la" or "myapp /bin/sh")

## Execution Steps

### Phase 1: Parse Arguments

```bash
CONTAINER=$(echo "$ARGUMENTS" | awk '{print $1}')
COMMAND=$(echo "$ARGUMENTS" | cut -d' ' -f2-)

if [ -z "$CONTAINER" ]; then
    echo "=== Running Containers ==="
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
    echo ""
    echo "Usage: /exec <container> <command>"
    echo "Example: /exec myapp ls -la"
    echo "Example: /exec myapp /bin/sh (for interactive shell)"
    exit 0
fi
```

### Phase 2: Verify Container

```bash
# Check if container is running
STATUS=$(docker inspect "$CONTAINER" --format '{{.State.Status}}' 2>/dev/null)

if [ -z "$STATUS" ]; then
    echo "Container '$CONTAINER' not found"
    echo ""
    echo "=== Available Containers ==="
    docker ps -a --format "table {{.Names}}\t{{.Status}}"
    exit 1
fi

if [ "$STATUS" != "running" ]; then
    echo "Container '$CONTAINER' is not running (status: $STATUS)"
    echo "Start it with: docker start $CONTAINER"
    exit 1
fi

echo "=== Container: $CONTAINER (running) ==="
```

### Phase 3: Execute Command

```bash
# Default to shell if no command specified
if [ -z "$COMMAND" ] || [ "$COMMAND" = "$CONTAINER" ]; then
    COMMAND="/bin/sh"
fi

echo "Executing: $COMMAND"
echo "---"

# Determine if interactive
if [ "$COMMAND" = "/bin/sh" ] || [ "$COMMAND" = "/bin/bash" ] || [ "$COMMAND" = "sh" ] || [ "$COMMAND" = "bash" ]; then
    echo "Starting interactive shell..."
    docker exec -it "$CONTAINER" $COMMAND
else
    docker exec "$CONTAINER" $COMMAND
fi
```

## Common Use Cases

```bash
# List files
/exec mycontainer ls -la /app

# Check environment
/exec mycontainer env

# View process list
/exec mycontainer ps aux

# Check network
/exec mycontainer cat /etc/hosts

# Interactive shell
/exec mycontainer /bin/sh

# Run specific tool
/exec mycontainer npm run test
```

## Output Format

Show:
1. Container verification status
2. Command being executed
3. Command output
4. Exit code if non-zero
