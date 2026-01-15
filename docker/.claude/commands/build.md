# Build Docker Image

Build a Docker image from a Dockerfile with detailed output and error analysis.

## Arguments
- `$ARGUMENTS`: Optional: image name:tag, Dockerfile path, or build arguments

## Execution Steps

### Phase 1: Discovery

Find Dockerfile and analyze build context:

```bash
# Find Dockerfiles in current directory
find . -maxdepth 2 -name "Dockerfile*" -type f 2>/dev/null

# Check for .dockerignore
if [ -f .dockerignore ]; then
    echo "=== .dockerignore exists ==="
    cat .dockerignore
else
    echo "WARNING: No .dockerignore found - build context may be large"
fi

# Estimate build context size (excluding .git)
echo "=== Build context size ==="
du -sh --exclude='.git' . 2>/dev/null || du -sh . 2>/dev/null
```

### Phase 2: Analyze Dockerfile

Review the Dockerfile before building:

```bash
# Display Dockerfile content
DOCKERFILE="${ARGUMENTS:-Dockerfile}"
if [ -f "$DOCKERFILE" ]; then
    echo "=== Dockerfile: $DOCKERFILE ==="
    cat "$DOCKERFILE"
else
    echo "Dockerfile not found: $DOCKERFILE"
    exit 1
fi
```

### Phase 3: Build Image

Execute the build with progress output:

```bash
# Parse arguments for image name or use default
IMAGE_NAME=$(echo "$ARGUMENTS" | grep -oE '[a-zA-Z0-9_-]+:[a-zA-Z0-9_.-]+' | head -1)
if [ -z "$IMAGE_NAME" ]; then
    IMAGE_NAME="app:latest"
fi

# Build with BuildKit and plain progress for full logs
DOCKER_BUILDKIT=1 docker build \
    --progress=plain \
    -t "$IMAGE_NAME" \
    -f "${DOCKERFILE:-Dockerfile}" \
    .
```

### Phase 4: Verify Build

Confirm the image was created successfully:

```bash
# Show image details
docker images "$IMAGE_NAME"

# Display image history/layers
docker history "$IMAGE_NAME"
```

## Output Format

Report should include:
1. Build context analysis
2. Dockerfile review notes
3. Build output with timing
4. Final image size and layer count
5. Any warnings or optimization suggestions
