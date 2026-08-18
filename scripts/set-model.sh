#!/usr/bin/env bash
# Sets the active model (and optionally the effort level) in ~/.claude/settings.json.
#
# This is the same store `/model` and `/effort` write to — verified by watching
# settings.json's mtime change the moment `/model opus` was run — so writing here
# is the supported way to switch, not a side channel.
#
#   set-model.sh <model> [effort]
#
# Model is one of the bare aliases Claude Code accepts (opus, sonnet, haiku, fable).
# Effort defaults to "medium" when not supplied.

set -euo pipefail

MODEL="${1:-}"
EFFORT_RAW="${2:-}"

VALID_MODELS="opus sonnet haiku fable"
# The effort ladder as the harness reports it. "auto" is deliberately excluded:
# it is a directive the /effort command understands, not a value that belongs in
# effortLevel — use /effort auto for that.
VALID_EFFORTS="low medium high xhigh max"

if [ -z "$MODEL" ]; then
  echo "Usage: set-model.sh <${VALID_MODELS// /|}> [${VALID_EFFORTS// /|}]" >&2
  exit 1
fi

MODEL=$(echo "$MODEL" | tr '[:upper:]' '[:lower:]')
case " $VALID_MODELS " in
  *" $MODEL "*) ;;
  *) echo "Unknown model '$MODEL'. Expected one of: ${VALID_MODELS// /, }" >&2; exit 1 ;;
esac

# The command passes "$ARGUMENTS" through verbatim, which may be empty, may carry
# surrounding whitespace, or may contain trailing prose the user tacked on. Take
# the first whitespace-separated token and validate it against the whitelist
# rather than writing arbitrary text into settings.json.
EFFORT=$(echo "$EFFORT_RAW" | tr '[:upper:]' '[:lower:]' | awk '{print $1}')
[ -z "$EFFORT" ] && EFFORT="medium"

case " $VALID_EFFORTS " in
  *" $EFFORT "*) ;;
  *) echo "Unknown effort '$EFFORT'. Expected one of: ${VALID_EFFORTS// /, }" >&2; exit 1 ;;
esac

SETTINGS="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"
[ -f "$SETTINGS" ] || { echo "settings.json not found at $SETTINGS" >&2; exit 1; }

python - "$SETTINGS" "$MODEL" "$EFFORT" <<'PY'
import json, os, shutil, sys

path, model, effort = sys.argv[1], sys.argv[2], sys.argv[3]

with open(path, encoding="utf-8") as fh:
    settings = json.load(fh)

before = (settings.get("model"), settings.get("effortLevel"))
settings["model"] = model
settings["effortLevel"] = effort

# Write to a temp file next to the target and swap it in, so an interrupted run
# can't leave a half-written settings.json behind.
shutil.copy2(path, path + ".bak-set-model")
tmp = path + ".set-model-tmp"
with open(tmp, "w", encoding="utf-8") as fh:
    json.dump(settings, fh, indent=2, ensure_ascii=False)
    fh.write("\n")
os.replace(tmp, path)

print(f"model:  {before[0]} -> {model}")
print(f"effort: {before[1]} -> {effort}")
PY

echo ""
echo "Written to $SETTINGS (backup: settings.json.bak-set-model)."
echo "Applies to new sessions. To switch the session you're in right now, run: /model $MODEL"
