#!/usr/bin/env bash
# =============================================================================
# dry-run-guard.sh
# PreToolUse hook — rewrites destructive git commands to add --dry-run
# =============================================================================
#
# Intercepts Bash tool calls containing dangerous git operations and injects
# --dry-run so Claude sees what WOULD happen before actually doing it.
#
# Caught patterns:
#   - git push --force / git push -f
#   - git push --force-with-lease (still destructive)
#   - git reset --hard
#   - git clean -f
#
# Returns JSON with updatedInput to rewrite the command, or exits 0 to allow.
#
# Reference: https://buildingbetter.tech/p/i-read-the-claude-code-source-code
# =============================================================================

INPUT=$(cat)

# Only act on Bash tool calls
TOOL_NAME=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_name', ''))
except: pass
" 2>/dev/null)

[[ "$TOOL_NAME" != "Bash" ]] && exit 0

COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('command', ''))
except: pass
" 2>/dev/null)

[[ -z "$COMMAND" ]] && exit 0

# Check for destructive git patterns
NEEDS_DRYRUN=false
REASON=""

if echo "$COMMAND" | grep -qE 'git\s+push\s+.*--force|git\s+push\s+-f'; then
  NEEDS_DRYRUN=true
  REASON="force push detected"
elif echo "$COMMAND" | grep -qE 'git\s+push\s+.*--force-with-lease'; then
  NEEDS_DRYRUN=true
  REASON="force-with-lease push detected"
elif echo "$COMMAND" | grep -qE 'git\s+reset\s+--hard'; then
  NEEDS_DRYRUN=true
  REASON="hard reset detected"
elif echo "$COMMAND" | grep -qE 'git\s+clean\s+-[a-zA-Z]*f'; then
  NEEDS_DRYRUN=true
  REASON="clean -f detected"
fi

if [[ "$NEEDS_DRYRUN" == "true" ]]; then
  # For push: add --dry-run flag
  # For reset/clean: block entirely (--dry-run not always available)
  if echo "$COMMAND" | grep -qE 'git\s+push'; then
    SAFE_COMMAND=$(echo "$COMMAND" | sed -E 's/(git\s+push)/\1 --dry-run/')
    cat <<EOF
{
  "additionalContext": "DRY-RUN GUARD: ${REASON}. Command was rewritten to --dry-run. Review the output and re-run without --dry-run if the user confirms.",
  "updatedInput": {
    "command": "${SAFE_COMMAND}"
  }
}
EOF
  else
    cat <<EOF
{
  "additionalContext": "DRY-RUN GUARD: ${REASON}. This is a destructive operation. Ask the user to confirm before proceeding."
}
EOF
  fi
  exit 0
fi

exit 0
