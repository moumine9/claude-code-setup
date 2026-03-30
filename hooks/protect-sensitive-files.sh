#!/usr/bin/env bash
# =============================================================================
# protect-sensitive-files.sh
# PreToolUse hook — blocks Read/Edit/Write on sensitive files/directories
# =============================================================================
#
# Receives the tool use JSON on stdin from Claude Code.
# Exit 0  → allow
# Exit 2  → hard block (Claude Code shows the message as an error)
#
# Sensitive patterns are defined in the two arrays below — edit to customize.
# =============================================================================

INPUT=$(cat)

# ---------------------------------------------------------------------------
# JSON extraction — tries python3, then jq, then grep fallback
# ---------------------------------------------------------------------------
json_get() {
  local json="$1" keypath="$2"
  if command -v python3 &>/dev/null; then
    printf '%s' "$json" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    keys = '$keypath'.split('.')
    v = d
    for k in keys:
        v = v.get(k, {}) if isinstance(v, dict) else ''
    sys.stdout.write(str(v) if isinstance(v, str) else '')
except Exception:
    pass
" 2>/dev/null
  elif command -v jq &>/dev/null; then
    printf '%s' "$json" | jq -r ".$keypath // empty" 2>/dev/null
  else
    # Fallback: extract the last key via grep (handles simple cases)
    local key="${keypath##*.}"
    printf '%s' "$json" \
      | grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
      | head -1 \
      | grep -o '"[^"]*"$' \
      | tr -d '"'
  fi
}

TOOL_NAME=$(json_get "$INPUT" "tool_name")
FILE_PATH=$(json_get "$INPUT" "tool_input.file_path")
[[ -z "$FILE_PATH" ]] && FILE_PATH=$(json_get "$INPUT" "tool_input.path")

# Normalize Windows backslashes to forward slashes
FILE_PATH="${FILE_PATH//\\//}"

# ---------------------------------------------------------------------------
# SENSITIVE DIRECTORIES
# Any file whose path contains one of these directory segments is blocked.
# ---------------------------------------------------------------------------
SENSITIVE_DIRS=(
  deployments
  secrets
  .secrets
  .aws
  .ssh
  .gnupg
  vault
)

# ---------------------------------------------------------------------------
# SENSITIVE FILE PATTERNS (applied to the filename/basename only)
# Bash extended regex — add patterns here as needed.
# ---------------------------------------------------------------------------
SENSITIVE_FILE_PATTERNS=(
  "^\.env$"           # .env
  "^\.env\."          # .env.production, .env.local, .env.staging, etc.
  "^credentials\.json$"
  "^service-account.*\.json$"    # GCP service accounts
  "^\.npmrc$"
  "^\.netrc$"
  "^\.htpasswd$"
  "\.pem$"            # PEM certificates/keys
  "\.key$"            # Private keys
  "\.p12$"            # PKCS#12 bundles
  "\.pfx$"            # PFX certificates
  "\.jks$"            # Java keystores
  "^id_rsa"           # SSH RSA keys
  "^id_ed25519"       # SSH Ed25519 keys
  "^id_ecdsa"         # SSH ECDSA keys
  "^id_dsa"           # SSH DSA keys
  "\.secret$"         # Any *.secret file
  "kubeconfig"        # Kubernetes config files
  "vault-token"       # Vault tokens
  "^\.env$"
  "^terraform\.tfvars$"          # Terraform secret vars
  "^terraform\.tfvars\.json$"
)

# ---------------------------------------------------------------------------
# Main check
# ---------------------------------------------------------------------------
is_blocked() {
  local fp="$1"
  [[ -z "$fp" ]] && return 1

  local filename
  filename=$(basename "$fp")

  # Check each path segment against sensitive directories
  for dir in "${SENSITIVE_DIRS[@]}"; do
    if [[ "$fp" =~ (^|/)"$dir"(/|$) ]]; then
      return 0
    fi
  done

  # Check filename against sensitive patterns
  for pattern in "${SENSITIVE_FILE_PATTERNS[@]}"; do
    if [[ "$filename" =~ $pattern ]]; then
      return 0
    fi
  done

  return 1
}

if is_blocked "$FILE_PATH"; then
  echo "🔒 BLOCKED — sensitive file access denied"
  echo ""
  echo "  Tool : $TOOL_NAME"
  echo "  Path : $FILE_PATH"
  echo ""
  echo "  This file matches a protected pattern."
  echo "  To allow this specific path, add it to permissions.allow in"
  echo "  ~/.claude/settings.json or <project>/.claude/settings.local.json"
  exit 2
fi

exit 0
