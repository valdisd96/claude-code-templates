# Analyze Helm Dependencies

Deep analysis of chart dependencies, subcharts, version compatibility, and dependency health.

## Arguments
- `$ARGUMENTS`: Optional - path to chart directory (default: current directory)

## Execution Steps

### Phase 1: Dependency Discovery

```bash
CHART_PATH="${ARGUMENTS:-.}"

echo "═══════════════════════════════════════════════════════════"
echo "HELM DEPENDENCY ANALYZER"
echo "═══════════════════════════════════════════════════════════"

# Find Chart.yaml
if [ ! -f "$CHART_PATH/Chart.yaml" ]; then
    CHART_PATH=$(find . -name "Chart.yaml" -type f -exec dirname {} \; | head -1)
fi

if [ -z "$CHART_PATH" ] || [ ! -f "$CHART_PATH/Chart.yaml" ]; then
    echo "❌ ERROR: No Chart.yaml found"
    exit 1
fi

echo "📦 Chart: $CHART_PATH"
grep -E "^name:|^version:" "$CHART_PATH/Chart.yaml" | sed 's/^/   /'

echo ""
echo "=== Declared Dependencies ==="
grep -A 100 "^dependencies:" "$CHART_PATH/Chart.yaml" 2>/dev/null | while read line; do
    # Stop at next top-level key
    if [[ "$line" =~ ^[a-zA-Z] ]] && [[ ! "$line" =~ ^dependencies ]]; then
        break
    fi
    echo "$line"
done
```

### Phase 2: Dependency Details

```bash
CHART_PATH="${ARGUMENTS:-.}"

echo ""
echo "=== Dependency Breakdown ==="

# Parse dependencies from Chart.yaml
grep -A 100 "^dependencies:" "$CHART_PATH/Chart.yaml" 2>/dev/null | grep -E "^\s*-\s*name:|version:|repository:|condition:|alias:" | while read line; do
    if [[ "$line" =~ "name:" ]]; then
        echo ""
        echo "📦 ${line##*: }"
    else
        echo "   $line"
    fi
done

# Check if dependencies are downloaded
echo ""
echo "=== Downloaded Dependencies ==="
if [ -d "$CHART_PATH/charts" ]; then
    ls -la "$CHART_PATH/charts/" 2>/dev/null | grep -v "^total"

    # Check each subchart
    for subchart in "$CHART_PATH"/charts/*/; do
        if [ -f "$subchart/Chart.yaml" ]; then
            name=$(grep "^name:" "$subchart/Chart.yaml" | awk '{print $2}')
            version=$(grep "^version:" "$subchart/Chart.yaml" | awk '{print $2}')
            echo "   ✓ $name @ $version"
        fi
    done
else
    echo "   ○ No charts/ directory - run 'helm dependency update'"
fi
```

### Phase 3: Lock File Analysis

```bash
CHART_PATH="${ARGUMENTS:-.}"

echo ""
echo "=== Chart.lock Analysis ==="

if [ -f "$CHART_PATH/Chart.lock" ]; then
    echo "🔒 Chart.lock present"
    echo ""
    cat "$CHART_PATH/Chart.lock"

    # Compare lock vs declared
    echo ""
    echo "=== Lock vs Declared Comparison ==="

    # Extract versions from both files
    DECLARED=$(grep -A 3 "^\s*- name:" "$CHART_PATH/Chart.yaml" 2>/dev/null | grep -E "name:|version:" | paste - - | sort)
    LOCKED=$(grep -A 2 "^\s*- name:" "$CHART_PATH/Chart.lock" 2>/dev/null | grep -E "name:|version:" | paste - - | sort)

    if [ "$DECLARED" != "$LOCKED" ]; then
        echo "⚠️  Lock file may be out of sync with Chart.yaml"
        echo "   Run: helm dependency update $CHART_PATH"
    else
        echo "✓ Lock file is in sync"
    fi
else
    echo "○ No Chart.lock found"
    echo "   Run: helm dependency update $CHART_PATH"
fi
```

### Phase 4: Repository Health Check

```bash
CHART_PATH="${ARGUMENTS:-.}"

echo ""
echo "=== Repository Status ==="

# Extract unique repositories
REPOS=$(grep -A 100 "^dependencies:" "$CHART_PATH/Chart.yaml" 2>/dev/null | grep "repository:" | awk '{print $2}' | tr -d '"' | sort -u)

for repo in $REPOS; do
    echo ""
    echo "🌐 $repo"

    # Check if repo is added
    repo_name=$(helm repo list 2>/dev/null | grep "$repo" | awk '{print $1}')
    if [ -n "$repo_name" ]; then
        echo "   ✓ Added as: $repo_name"

        # Check last update
        helm repo list 2>/dev/null | grep "$repo" | awk '{print "   Last update: " $3 " " $4}'
    else
        echo "   ○ Repository not added"
        echo "   Add with: helm repo add [name] $repo"
    fi
done

# Suggest repo update
echo ""
echo "💡 To refresh all repositories: helm repo update"
```

### Phase 5: Version Analysis

```bash
CHART_PATH="${ARGUMENTS:-.}"

echo ""
echo "=== Version Compatibility Analysis ==="

# Check for version constraints
grep -A 100 "^dependencies:" "$CHART_PATH/Chart.yaml" 2>/dev/null | grep -E "version:" | while read line; do
    version="${line##*: }"
    version=$(echo "$version" | tr -d '"' | tr -d "'")

    # Detect version constraint type
    if [[ "$version" =~ ^\~ ]]; then
        echo "   📌 $version (tilde: patch updates only)"
    elif [[ "$version" =~ ^\^ ]]; then
        echo "   📌 $version (caret: minor updates allowed)"
    elif [[ "$version" =~ \* ]]; then
        echo "   ⚠️  $version (wildcard: may cause instability)"
    elif [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "   🔒 $version (pinned: exact version)"
    elif [[ "$version" =~ ^[0-9]+\.x ]]; then
        echo "   📌 $version (minor range)"
    else
        echo "   ❓ $version (custom constraint)"
    fi
done

# Check for available updates
echo ""
echo "=== Available Updates ==="
helm dependency list "$CHART_PATH" 2>/dev/null | tail -n +2 | while read name version repo status; do
    if [ -n "$name" ] && [ "$name" != "NAME" ]; then
        echo "   📦 $name: $version ($status)"

        # Try to find latest version (if repo is added)
        if [ -n "$repo" ] && [ "$repo" != "unpacked" ]; then
            latest=$(helm search repo "$name" --version ">$version" 2>/dev/null | tail -n +2 | head -1 | awk '{print $2}')
            if [ -n "$latest" ] && [ "$latest" != "$version" ]; then
                echo "      ⬆️  Latest: $latest"
            fi
        fi
    fi
done
```

### Phase 6: Subchart Values Analysis

```bash
CHART_PATH="${ARGUMENTS:-.}"

echo ""
echo "=== Subchart Values Configuration ==="

# Check how subcharts are configured in values.yaml
if [ -f "$CHART_PATH/values.yaml" ]; then
    # Get dependency names
    grep -A 100 "^dependencies:" "$CHART_PATH/Chart.yaml" 2>/dev/null | grep "name:" | awk '{print $2}' | tr -d '"' | while read dep; do
        echo ""
        echo "📦 $dep configuration:"

        # Check if configured in values.yaml
        if grep -q "^${dep}:" "$CHART_PATH/values.yaml" 2>/dev/null; then
            echo "   ✓ Configured in values.yaml"
            grep -A 10 "^${dep}:" "$CHART_PATH/values.yaml" | head -12 | sed 's/^/   /'
        else
            echo "   ○ Using subchart defaults"
        fi

        # Check for alias
        alias=$(grep -A 5 "name: $dep" "$CHART_PATH/Chart.yaml" 2>/dev/null | grep "alias:" | awk '{print $2}')
        if [ -n "$alias" ]; then
            echo "   📛 Aliased as: $alias"
            echo "   Configure with: $alias: {...} in values.yaml"
        fi
    done
fi
```

### Phase 7: Generate Report

```
═══════════════════════════════════════════════════════════
DEPENDENCY ANALYSIS REPORT
═══════════════════════════════════════════════════════════

Chart: [name] v[version]
Path: [chart path]

Dependencies Summary:
  📦 Total declared: [count]
  ✓ Downloaded: [count]
  ○ Missing: [count]

Lock Status:
  [✓/○] Chart.lock: [present/missing]
  [✓/⚠️] Sync status: [in sync/out of sync]

Repositories:
| Repository | Status | Last Update |
|------------|--------|-------------|
| [url] | [added/missing] | [date] |

Dependencies:
| Name | Declared | Locked | Latest | Status |
|------|----------|--------|--------|--------|
| [dep] | [ver] | [ver] | [ver] | [✓/⬆️] |

Version Constraints:
  🔒 Pinned: [count]
  📌 Range: [count]
  ⚠️  Wildcard: [count]

Subchart Configuration:
  ✓ Configured: [list]
  ○ Using defaults: [list]

Issues Found:
  - [Issue 1]
  - [Issue 2]

Recommendations:
  1. Run 'helm dependency update' to sync
  2. Pin wildcard versions for stability
  3. Configure [subchart] values explicitly

Commands:
  # Update dependencies
  helm dependency update $CHART_PATH

  # List dependency status
  helm dependency list $CHART_PATH

  # Search for updates
  helm search repo [name] --versions

Next Steps:
  - Run /validate-chart to verify after update
  - Configure subchart values in values.yaml
  - Update Chart.lock before committing
═══════════════════════════════════════════════════════════
```
