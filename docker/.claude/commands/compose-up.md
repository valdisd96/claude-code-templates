# Docker Compose Up

Start services defined in docker-compose.yml with validation and monitoring.

## Arguments
- `$ARGUMENTS`: Optional: service names, or flags like "build" to rebuild

## Execution Steps

### Phase 1: Validate Configuration

```bash
COMPOSE_FILE="docker-compose.yml"
if [ ! -f "$COMPOSE_FILE" ]; then
    COMPOSE_FILE="docker-compose.yaml"
fi

if [ ! -f "$COMPOSE_FILE" ]; then
    echo "No docker-compose.yml found in current directory"
    find . -maxdepth 2 -name "docker-compose*.y*ml" -type f 2>/dev/null
    exit 1
fi

echo "=== Validating: $COMPOSE_FILE ==="
docker compose config --quiet && echo "Configuration valid" || {
    echo "Configuration errors found:"
    docker compose config 2>&1
    exit 1
}
```

### Phase 2: Show Services

```bash
echo ""
echo "=== Defined Services ==="
docker compose config --services

echo ""
echo "=== Current Status ==="
docker compose ps 2>/dev/null || echo "No containers running"
```

### Phase 3: Start Services

```bash
# Parse arguments
BUILD_FLAG=""
SERVICES=""

for arg in $ARGUMENTS; do
    if [ "$arg" = "build" ] || [ "$arg" = "--build" ]; then
        BUILD_FLAG="--build"
    else
        SERVICES="$SERVICES $arg"
    fi
done

echo ""
echo "=== Starting Services ==="

if [ -n "$BUILD_FLAG" ]; then
    echo "Rebuilding images..."
    docker compose up -d --build $SERVICES
else
    docker compose up -d $SERVICES
fi
```

### Phase 4: Verify Startup

```bash
echo ""
echo "=== Waiting for services to start ==="
sleep 3

echo ""
echo "=== Service Status ==="
docker compose ps

echo ""
echo "=== Recent Logs (last 20 lines per service) ==="
docker compose logs --tail 20
```

### Phase 5: Health Check

```bash
echo ""
echo "=== Health Status ==="
docker compose ps --format json 2>/dev/null | jq -r '.[] | "\(.Name): \(.State) \(.Health // "no healthcheck")"' 2>/dev/null || \
docker compose ps
```

## Common Operations

```bash
# Start all services
/compose-up

# Start with rebuild
/compose-up build

# Start specific services
/compose-up web db

# Start specific service with rebuild
/compose-up build web
```

## Output Format

Show:
1. Configuration validation results
2. Services defined in compose file
3. Startup progress
4. Final status of all services
5. Any errors or warnings from logs
