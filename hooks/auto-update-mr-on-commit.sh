#!/usr/bin/env bash
# =============================================================================
# auto-update-mr-on-commit.sh
# PostToolUse hook — delegates /update-merge-request to a background haiku
# agent after a git commit when an open MR exists for the current branch.
# =============================================================================
#
# Flow:
#   1. Only act on Bash tool calls
#   2. Check the command was a git commit
#   3. Look up the current branch for an open MR via glab
#   4. If found, emit additionalContext telling Claude to spawn the
#      'update-merge-request' agent (haiku, effort low) in the background
#
# Fails silently (exit 0, no output) when:
#   - Not a git commit command
#   - Not inside a git repo
#   - No open MR for the current branch
#   - glab is unavailable or unauthenticated
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

# Extract the command that was run
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('command', ''))
except: pass
" 2>/dev/null)

# Only proceed if the command was a git commit
if ! echo "$COMMAND" | grep -qE '(^|&&|\|)\s*git\s+commit'; then
  exit 0
fi

# Must be inside a git repo
git rev-parse --is-inside-work-tree &>/dev/null || exit 0

# Get current branch
BRANCH=$(git branch --show-current 2>/dev/null)
[[ -z "$BRANCH" ]] && exit 0

# Check for an open MR — silent, only care about web_url
MR_URL=$(glab mr view "$BRANCH" --output json 2>/dev/null | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    if d.get('state') == 'opened':
        print(d.get('web_url', ''))
except:
    pass
" 2>/dev/null)

# No open MR — nothing to do
[[ -z "$MR_URL" ]] && exit 0

# Open MR found — ask Claude to delegate to the background haiku agent
python3 -c "
import json
msg = {
    'additionalContext': (
        'A commit was just made on branch \\'${BRANCH}\\' and an open MR exists (${MR_URL}). '
        'Use the Agent tool to delegate this to the \\'update-merge-request\\' sub-agent '
        '(model: haiku, run_in_background: true). '
        'Do not handle it yourself — spawn the agent and continue.'
    )
}
print(json.dumps(msg))
"

exit 0
