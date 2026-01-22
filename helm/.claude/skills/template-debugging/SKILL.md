---
description: "Activate when user encounters Go template errors, asks about Helm templating, or has issues with {{ }} syntax, sprig functions, or template rendering failures"
---

# Helm Template Debugging Expert

You are an expert in Helm's Go templating system. When this skill is activated, provide deep expertise on debugging and writing Helm templates.

## Core Knowledge

### Template Syntax Fundamentals

```yaml
# Action delimiters
{{ .Values.key }}           # Standard - includes whitespace
{{- .Values.key }}          # Trim left whitespace
{{ .Values.key -}}          # Trim right whitespace
{{- .Values.key -}}         # Trim both sides

# Comments
{{/* This is a comment */}}
{{- /* Comment with whitespace control */ -}}
```

### Common Error Patterns & Solutions

#### 1. Nil Pointer / Map Has No Entry

**Error**: `nil pointer evaluating interface {}.fieldName`

**Cause**: Accessing a field that doesn't exist in values

**Solutions**:
```yaml
# Option 1: Use 'default'
{{ .Values.missing.field | default "fallback" }}

# Option 2: Check with 'if'
{{- if .Values.optional }}
value: {{ .Values.optional.field }}
{{- end }}

# Option 3: Use 'dig' for deep access (Helm 3.6+)
{{ dig "deep" "nested" "key" "default" .Values }}

# Option 4: Use 'hasKey'
{{- if hasKey .Values "optionalSection" }}
...
{{- end }}
```

#### 2. Wrong Type Errors

**Error**: `expected string; got int` or vice versa

**Solutions**:
```yaml
# Convert to string
{{ .Values.port | toString }}
{{ printf "%d" .Values.port }}

# Convert to int
{{ .Values.count | int }}
{{ .Values.count | int64 }}

# Convert to float
{{ .Values.ratio | float64 }}

# Quote strings in YAML
key: {{ .Values.stringVal | quote }}
```

#### 3. Indentation Issues

**Error**: YAML parsing fails, unexpected indentation

**Solutions**:
```yaml
# Use nindent for proper indentation
metadata:
  labels:
    {{- include "mychart.labels" . | nindent 4 }}

# Use indent for inline content
data: |
  {{ .Values.config | indent 2 }}

# Control with toYaml
resources:
  {{- toYaml .Values.resources | nindent 2 }}
```

#### 4. Range/Loop Scope Issues

**Error**: `can't evaluate field X in type interface {}`

**Cause**: Inside `range`, `.` refers to the loop item, not root context

**Solutions**:
```yaml
# Save root context before range
{{- $root := . -}}
{{- range .Values.items }}
  name: {{ .name }}
  chart: {{ $root.Chart.Name }}    # Access chart via saved context
  release: {{ $root.Release.Name }}
{{- end }}

# Or use $ (always refers to root)
{{- range .Values.items }}
  name: {{ .name }}
  chart: {{ $.Chart.Name }}
  release: {{ $.Release.Name }}
{{- end }}
```

#### 5. Whitespace in Output

**Problem**: Extra blank lines or spaces in rendered YAML

**Solutions**:
```yaml
# Bad - leaves blank lines
{{ if .Values.enabled }}
key: value
{{ end }}

# Good - controls whitespace
{{- if .Values.enabled }}
key: value
{{- end }}

# For lists, be careful
{{- range .Values.items }}
- {{ . }}
{{- end }}
```

### Sprig Functions Reference

#### String Functions
```yaml
{{ trim "  hello  " }}                    # "hello"
{{ trimPrefix "pre-" "pre-value" }}       # "value"
{{ trimSuffix "-suf" "value-suf" }}       # "value"
{{ lower "HELLO" }}                        # "hello"
{{ upper "hello" }}                        # "HELLO"
{{ title "hello world" }}                  # "Hello World"
{{ replace "old" "new" "old string" }}    # "new string"
{{ contains "sub" "substring" }}           # true
{{ hasPrefix "pre" "prefix" }}             # true
{{ hasSuffix "fix" "suffix" }}             # true
{{ quote "value" }}                        # "\"value\""
{{ squote "value" }}                       # "'value'"
{{ cat "a" "b" "c" }}                      # "a b c"
{{ nospace "a b c" }}                      # "abc"
{{ trunc 5 "hello world" }}                # "hello"
{{ abbrev 10 "hello world" }}              # "hello w..."
{{ substr 0 5 "hello world" }}             # "hello"
{{ split "," "a,b,c" }}                    # [a b c]
{{ splitList "," "a,b,c" }}                # list
{{ join "," (list "a" "b" "c") }}          # "a,b,c"
```

#### List Functions
```yaml
{{ list "a" "b" "c" }}                     # Create list
{{ first (list 1 2 3) }}                   # 1
{{ last (list 1 2 3) }}                    # 3
{{ rest (list 1 2 3) }}                    # [2 3]
{{ initial (list 1 2 3) }}                 # [1 2]
{{ append (list 1 2) 3 }}                  # [1 2 3]
{{ prepend (list 2 3) 1 }}                 # [1 2 3]
{{ concat (list 1) (list 2) }}             # [1 2]
{{ reverse (list 1 2 3) }}                 # [3 2 1]
{{ uniq (list 1 1 2) }}                    # [1 2]
{{ has "item" (list "a" "item" "b") }}    # true
{{ without (list 1 2 3) 2 }}               # [1 3]
{{ slice (list 1 2 3 4) 1 3 }}             # [2 3]
```

#### Dict/Map Functions
```yaml
{{ dict "key1" "val1" "key2" "val2" }}    # Create dict
{{ get .Values "key" }}                    # Get value
{{ set .Values "key" "value" }}            # Set value (mutates!)
{{ unset .Values "key" }}                  # Remove key
{{ hasKey .Values "key" }}                 # Check existence
{{ keys .Values }}                         # List of keys
{{ values .Values }}                       # List of values
{{ pick .Values "key1" "key2" }}           # Subset dict
{{ omit .Values "key1" "key2" }}           # Dict without keys
{{ merge (dict) .Values .Defaults }}       # Merge dicts
{{ dig "a" "b" "default" .Values }}        # Deep get with default
```

#### Flow Control
```yaml
# Ternary
{{ ternary "yes" "no" .Values.enabled }}

# Default with type coercion
{{ .Values.count | default 1 }}
{{ .Values.name | default "app" | quote }}

# Coalesce (first non-empty)
{{ coalesce .Values.a .Values.b "default" }}

# Required (fail if empty)
{{ required "A name is required!" .Values.name }}

# Fail explicitly
{{ fail "This should not happen" }}
```

#### Type Conversion
```yaml
{{ toJson .Values.config }}                # Convert to JSON
{{ toYaml .Values.config }}                # Convert to YAML
{{ fromJson .Values.jsonString }}          # Parse JSON
{{ fromYaml .Values.yamlString }}          # Parse YAML
{{ toToml .Values.config }}                # Convert to TOML
{{ toPrettyJson .Values.config }}          # Pretty JSON
```

#### Cryptographic
```yaml
{{ sha256sum "input" }}                    # SHA256 hash
{{ sha1sum "input" }}                      # SHA1 hash
{{ b64enc "hello" }}                       # Base64 encode
{{ b64dec "aGVsbG8=" }}                    # Base64 decode
{{ randAlphaNum 10 }}                      # Random string
{{ randAlpha 10 }}                         # Random letters
{{ randNumeric 10 }}                       # Random numbers
{{ uuidv4 }}                               # Generate UUID
```

### Named Templates Best Practices

```yaml
# _helpers.tpl

# Define a template
{{- define "mychart.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

# Use in templates
metadata:
  name: {{ include "mychart.fullname" . }}

# Template vs Include
# 'template' - outputs directly, can't pipe
{{ template "mychart.labels" . }}

# 'include' - returns string, can pipe (preferred)
{{- include "mychart.labels" . | nindent 4 }}
```

### Debug Techniques

```bash
# Render all templates with debug info
helm template release ./chart --debug

# Render single template
helm template release ./chart -s templates/deployment.yaml

# Show computed values
helm template release ./chart --debug 2>&1 | head -50

# Dry-run with verbose output
helm install release ./chart --dry-run --debug

# Check specific values
helm template release ./chart --set key=value --debug
```

### Template Debugging in YAML

```yaml
# Print variable for debugging (remove before production!)
# DEBUG: {{ .Values.someVar | toYaml }}

# Use printf for complex debugging
# {{ printf "DEBUG: type=%T value=%v" .Values.item .Values.item }}

# Check type
# {{ kindOf .Values.item }}
# {{ typeOf .Values.item }}
```

## When Helping Users

1. **Identify the exact error message** - Different errors need different solutions
2. **Check the context** - Is this inside a range? What's the scope?
3. **Verify values exist** - Use `helm template --debug` to see computed values
4. **Test incrementally** - Render single templates, not the whole chart
5. **Watch whitespace** - 90% of YAML issues are indentation
6. **Remember scope** - `.` changes meaning inside `range` and `with`
