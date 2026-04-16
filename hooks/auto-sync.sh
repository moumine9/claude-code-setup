#!/usr/bin/env bash
# PostToolUse hook: auto-syncs claude-code-setup to ~/.claude when a skill,
# command, or hook file is written or edited inside D:/claude-code-setup.

set -euo pipefail

input="$(cat)"

file_path="$(echo "$input" | jq -r '.tool_input.file_path // ""')"

# Normalize Windows-style paths (D:\... → /d/...)
file_path="$(echo "$file_path" | sed 's|\\\\|/|g; s|^D:|/d|i; s|^C:|/c|i')"

# Only act on changes inside the managed directories
if ! echo "$file_path" | grep -qiE "^/d/claude-code-setup/(skills|commands|hooks)/"; then
  echo '{}'
  exit 0
fi

# Run the sync and capture output
sync_output="$(bash /d/claude-code-setup/sync.sh 2>&1)" || true

# Escape the output for JSON
escaped="$(echo "$sync_output" | jq -Rs .)"

echo "{\"additionalContext\": \"claude-code-setup auto-sync ran after editing $file_path. Output: $escaped\"}"
exit 0
