# Validate Docker Compose Configuration

Validate docker-compose.yml syntax, structure, and best practices.

## Arguments
- `$ARGUMENTS`: Path to docker compose file (defaults to ./docker-compose.yml)

## Execution Steps

### Phase 1: Find and Load Compose File

```bash
COMPOSE_FILE="${ARGUMENTS:-docker-compose.yml}"

if [ ! -f "$COMPOSE_FILE" ]; then
    # Try yaml extension
    if [ -f "docker-compose.yaml" ]; then
        COMPOSE_FILE="docker-compose.yaml"
    else
        echo "Compose file not found: $COMPOSE_FILE"
        echo ""
        echo "=== Available Compose Files ==="
        find . -maxdepth 2 -name "docker-compose*.y*ml" -type f 2>/dev/null
        exit 1
    fi
fi

echo "=== Validating: $COMPOSE_FILE ==="
echo ""
cat -n "$COMPOSE_FILE"
```

### Phase 2: Syntax Validation

```bash
echo ""
echo "=== SYNTAX VALIDATION ==="

# Use docker compose config to validate
if docker compose -f "$COMPOSE_FILE" config --quiet 2>/dev/null; then
    echo "[PASS] Syntax is valid"
else
    echo "[FAIL] Syntax errors:"
    docker compose -f "$COMPOSE_FILE" config 2>&1
fi
```

### Phase 3: Structure Analysis

```bash
echo ""
echo "=== STRUCTURE ANALYSIS ==="

# Check version
VERSION=$(grep "^version:" "$COMPOSE_FILE" | head -1)
if [ -n "$VERSION" ]; then
    echo "Compose version: $VERSION"
else
    echo "[INFO] No version specified (using latest format)"
fi

# List services
echo ""
echo "Services defined:"
docker compose -f "$COMPOSE_FILE" config --services 2>/dev/null

# List volumes
echo ""
echo "Volumes defined:"
docker compose -f "$COMPOSE_FILE" config --volumes 2>/dev/null || echo "(none)"

# List networks
echo ""
echo "Networks:"
grep -A 100 "^networks:" "$COMPOSE_FILE" | grep -E "^\s{2}\w" | awk '{print $1}' | tr -d ':' || echo "(default)"
```

### Phase 4: Best Practices Check

```bash
echo ""
echo "=== BEST PRACTICES ==="

# Check for restart policies
if ! grep -q "restart:" "$COMPOSE_FILE"; then
    echo "[WARN] No restart policies defined"
fi

# Check for healthchecks
if ! grep -q "healthcheck:" "$COMPOSE_FILE"; then
    echo "[INFO] No healthchecks defined"
fi

# Check for resource limits
if ! grep -qE "(mem_limit|cpus:|memory:)" "$COMPOSE_FILE"; then
    echo "[INFO] No resource limits defined"
fi

# Check for latest tag
if grep -qE "image:.*:latest" "$COMPOSE_FILE"; then
    echo "[WARN] Using ':latest' tag - consider specific versions"
fi

# Check for hardcoded secrets
if grep -qiE "(password|secret):" "$COMPOSE_FILE" | grep -vE "(password_file|secret_file|_FILE)"; then
    echo "[WARN] Possible hardcoded secrets - consider using secrets or env_file"
fi

# Check for env_file
if grep -q "env_file:" "$COMPOSE_FILE"; then
    echo "[GOOD] Using env_file for environment variables"
fi

# Check for depends_on
if grep -q "depends_on:" "$COMPOSE_FILE"; then
    echo "[GOOD] Service dependencies defined"
    if ! grep -q "condition:" "$COMPOSE_FILE"; then
        echo "[INFO] Consider using condition: service_healthy for proper startup order"
    fi
fi
```

### Phase 5: Security Check

```bash
echo ""
echo "=== SECURITY CHECK ==="

# Check for privileged mode
if grep -q "privileged: true" "$COMPOSE_FILE"; then
    echo "[WARN] Privileged mode enabled - review necessity"
fi

# Check for host network
if grep -q "network_mode: host" "$COMPOSE_FILE"; then
    echo "[WARN] Using host network mode"
fi

# Check for volume mounts
if grep -qE "volumes:.*:.*:rw" "$COMPOSE_FILE" || grep -qE "/var/run/docker.sock" "$COMPOSE_FILE"; then
    echo "[INFO] Host volume mounts detected - verify security implications"
fi

# Check for exposed ports
PORTS=$(grep -E "^\s+- \"?[0-9]+:" "$COMPOSE_FILE" | wc -l)
echo "Exposed ports: $PORTS"
```

## Output Format

Summary report with:
1. Syntax validation result
2. Structure overview (services, volumes, networks)
3. Best practices compliance
4. Security considerations
5. Recommendations for improvements
