#!/usr/bin/env bash
# PostToolUse hook: auto-syncs claude-code-setup to ~/.claude when a skill,
# command, or hook file is written or edited inside D:/claude-code-setup.

set -euo pipefail

input="$(cat)"

# jq isn't guaranteed to be on PATH (e.g. plain Git Bash on Windows without
# it installed). Fall back to a plain grep/sed extraction of the file_path
# field so the hook still works without jq — it only needs to pull one
# simple string field out of a flat JSON object.
if command -v jq >/dev/null 2>&1; then
  file_path="$(echo "$input" | jq -r '.tool_input.file_path // ""')"
else
  # The trailing `|| true` matters: under `set -euo pipefail` a no-match from
  # grep fails the whole pipeline, and because this is a command substitution
  # in an assignment that aborts the hook outright, instead of falling through
  # to the graceful `echo '{}'` below. Yield "" instead, matching the jq branch.
  # The extraction pulls the RAW JSON value, so a Windows path arrives with its
  # backslashes still JSON-doubled ("D:\repo\x"). Collapse them back to single
  # before the tr below, otherwise tr turns each doubled pair into "//" and the
  # directory guard never matches -- the hook would exit quietly and never sync.
  # jq decodes this itself, which is why the bug only shows on the fallback path.
  file_path="$(echo "$input" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"file_path"[[:space:]]*:[[:space:]]*"([^"]*)"/\1/' | sed 's/\\\\/\\/g' || true)"
fi

# Normalize Windows-style paths (D:\... → /d/...). `tr` swaps every single
# backslash for a forward slash — a prior sed pattern here required two
# consecutive backslashes to match, which never fires on a normal
# single-backslash Windows path and silently left it unnormalized.
file_path="$(echo "$file_path" | tr '\\' '/' | sed 's|^[Dd]:|/d|; s|^[Cc]:|/c|')"

# Only act on changes inside the managed directories
if ! echo "$file_path" | grep -qiE "^/d/claude-code-setup/(skills|commands|hooks)/"; then
  echo '{}'
  exit 0
fi

# Run the sync and capture output
sync_output="$(bash /d/claude-code-setup/sync.sh 2>&1)" || true

# Escape the output for embedding inside the already-quoted JSON string
# below (note: no surrounding quotes on $escaped itself — the "Output: ...\"}"
# line already opened and will close the string). Same jq-optional approach
# as the file_path extraction above.
if command -v jq >/dev/null 2>&1; then
  quoted="$(echo "$sync_output" | jq -Rs .)"
  escaped="${quoted#\"}"
  escaped="${escaped%\"}"
else
  escaped="$(printf '%s' "$sync_output" | sed ':a;N;$!ba; s/\\/\\\\/g; s/"/\\"/g; s/\n/\\n/g')"
fi

echo "{\"additionalContext\": \"claude-code-setup auto-sync ran after editing $file_path. Output: $escaped\"}"
exit 0
