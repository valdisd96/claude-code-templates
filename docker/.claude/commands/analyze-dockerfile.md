# Analyze Dockerfile

Review a Dockerfile for best practices, security issues, and optimization opportunities.

## Arguments
- `$ARGUMENTS`: Path to Dockerfile (defaults to ./Dockerfile)

## Execution Steps

### Phase 1: Load Dockerfile

```bash
DOCKERFILE="${ARGUMENTS:-Dockerfile}"

if [ ! -f "$DOCKERFILE" ]; then
    echo "Dockerfile not found: $DOCKERFILE"
    echo ""
    echo "=== Available Dockerfiles ==="
    find . -maxdepth 2 -name "Dockerfile*" -type f 2>/dev/null
    exit 1
fi

echo "=== Analyzing: $DOCKERFILE ==="
echo ""
cat -n "$DOCKERFILE"
```

### Phase 2: Security Analysis

```bash
echo ""
echo "=== SECURITY ANALYSIS ==="

# Check for root user
if ! grep -q "^USER " "$DOCKERFILE"; then
    echo "[WARN] No USER instruction - container runs as root"
fi

# Check for latest tag
if grep -qE "FROM .+:latest" "$DOCKERFILE"; then
    echo "[WARN] Using ':latest' tag - builds may be unpredictable"
fi

# Check for hardcoded secrets
if grep -qiE "(password|secret|key|token)=" "$DOCKERFILE"; then
    echo "[CRITICAL] Possible hardcoded secrets detected"
fi

# Check for sensitive file copies
if grep -qE "COPY.*(\.env|credentials|\.pem|\.key)" "$DOCKERFILE"; then
    echo "[WARN] Copying potentially sensitive files"
fi

# Check for privilege escalation
if grep -q "sudo" "$DOCKERFILE"; then
    echo "[WARN] sudo usage detected - review necessity"
fi
```

### Phase 3: Best Practices Analysis

```bash
echo ""
echo "=== BEST PRACTICES ==="

# Check for .dockerignore
if [ ! -f .dockerignore ]; then
    echo "[WARN] No .dockerignore - build context may include unnecessary files"
fi

# Check for ADD vs COPY
if grep -q "^ADD " "$DOCKERFILE" && ! grep -qE "^ADD .*(http|\.tar|\.gz)" "$DOCKERFILE"; then
    echo "[INFO] Using ADD for local files - consider COPY instead"
fi

# Check for package cache cleanup
if grep -q "apt-get install" "$DOCKERFILE" && ! grep -q "rm -rf /var/lib/apt/lists" "$DOCKERFILE"; then
    echo "[WARN] apt-get without cache cleanup - increases image size"
fi

# Check for combined RUN commands
RUN_COUNT=$(grep -c "^RUN " "$DOCKERFILE")
if [ "$RUN_COUNT" -gt 5 ]; then
    echo "[INFO] $RUN_COUNT RUN commands - consider combining to reduce layers"
fi

# Check for WORKDIR
if ! grep -q "^WORKDIR " "$DOCKERFILE"; then
    echo "[INFO] No WORKDIR set - using default /"
fi

# Check for HEALTHCHECK
if ! grep -q "^HEALTHCHECK " "$DOCKERFILE"; then
    echo "[INFO] No HEALTHCHECK defined"
fi
```

### Phase 4: Optimization Analysis

```bash
echo ""
echo "=== OPTIMIZATION OPPORTUNITIES ==="

# Check for multi-stage build
if grep -c "^FROM " "$DOCKERFILE" | grep -q "^1$"; then
    echo "[INFO] Single-stage build - consider multi-stage for smaller images"
fi

# Check COPY order (dependencies before source)
COPY_LINES=$(grep -n "^COPY " "$DOCKERFILE")
echo "COPY instruction order:"
echo "$COPY_LINES"

# Check for npm ci vs npm install
if grep -q "npm install" "$DOCKERFILE" && ! grep -q "npm ci" "$DOCKERFILE"; then
    echo "[INFO] Using 'npm install' - consider 'npm ci' for reproducible builds"
fi

# Analyze base image
BASE_IMAGE=$(grep "^FROM " "$DOCKERFILE" | head -1 | awk '{print $2}')
echo ""
echo "Base image: $BASE_IMAGE"
case "$BASE_IMAGE" in
    *alpine*) echo "[GOOD] Using Alpine-based image (smaller size)" ;;
    *slim*) echo "[GOOD] Using slim variant" ;;
    *) echo "[INFO] Consider Alpine or slim variant for smaller image" ;;
esac
```

### Phase 5: Summary

Generate a summary with:
1. Critical issues (must fix)
2. Warnings (should fix)
3. Suggestions (nice to have)
4. Estimated optimization potential
5. Recommended changes with code examples
