#!/usr/bin/env bash
# =============================================================================
# session-context.sh
# SessionStart hook — injects git context and watches key config files
# =============================================================================
#
# Returns JSON with:
#   - additionalContext: git branch, uncommitted changes count, recent commits
#   - watchPaths: config files that trigger FileChanged events when modified
#
# Reference: https://buildingbetter.tech/p/i-read-the-claude-code-source-code
# =============================================================================

# Only run if inside a git repo
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  exit 0
fi

BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
UNCOMMITTED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
RECENT_COMMITS=$(git log --oneline -5 2>/dev/null | sed 's/"/\\"/g' | paste -sd '\\n' -)

# Build watch paths — only include files that exist
WATCH_PATHS=""
for f in package.json tsconfig.json .eslintrc.js .eslintrc.json .prettierrc angular.json vite.config.ts webpack.config.js; do
  if [[ -f "$f" ]]; then
    WATCH_PATHS="${WATCH_PATHS}\"${f}\","
  fi
done
# Remove trailing comma
WATCH_PATHS="${WATCH_PATHS%,}"

CONTEXT="Session started on branch '${BRANCH}' with ${UNCOMMITTED} uncommitted change(s).\\nRecent commits:\\n${RECENT_COMMITS}"

cat <<EOF
{
  "additionalContext": "${CONTEXT}",
  "watchPaths": [${WATCH_PATHS}]
}
EOF

exit 0
