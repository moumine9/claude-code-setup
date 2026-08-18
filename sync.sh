#!/usr/bin/env bash
# Syncs D:/claude-code-setup skills and commands to ~/.claude/
# Uses symlinks when possible (requires Windows Developer Mode), falls back to copies.

set -euo pipefail

SETUP_DIR="/d/claude-code-setup"
CLAUDE_DIR="$HOME/.claude"

# ── Detect symlink support ────────────────────────────────────────────────────
can_symlink() {
  local probe="$CLAUDE_DIR/.symlink_probe_$$"
  ln -s "$SETUP_DIR" "$probe" 2>/dev/null || { return 1; }
  if [ -L "$probe" ]; then
    rm "$probe"
    return 0
  fi
  rm -rf "$probe" 2>/dev/null
  return 1
}

USE_SYMLINKS=false
can_symlink && USE_SYMLINKS=true

MODE=$( $USE_SYMLINKS && echo "symlinks" || echo "copies" )
echo "claude-code-setup sync  [mode: $MODE]"
echo "  source : $SETUP_DIR"
echo "  target : $CLAUDE_DIR"
echo ""

SYNCED=0
SKIPPED=0
PRUNED=0
ERRORS=0

# Manifest of items this script installed on the last run. Pruning is driven
# strictly by this file so we only ever remove things we put there ourselves —
# skills and commands installed from plugins or by hand are never touched.
MANIFEST="$CLAUDE_DIR/.claude-code-setup-manifest"
NEW_MANIFEST="$(mktemp)"
trap 'rm -f "$NEW_MANIFEST"' EXIT

# ── Helpers ───────────────────────────────────────────────────────────────────
# Both helpers stage the new symlink/copy at a temp path next to the
# destination, and only remove the old destination after the staging step
# succeeds. That way a failed copy (source missing, disk full, etc.) leaves
# the previous destination untouched instead of deleting it first and then
# discovering the copy can't be made.
link_or_copy_dir() {
  local src="$1" dst="$2" label="$3"
  local staging="${dst}.syncing_$$"
  # Glob-clean, not just our own PID: a run that died mid-install would
  # otherwise leave "<dst>.syncing_<oldpid>" behind forever, invisible to the
  # prune step because it was never recorded in the manifest.
  rm -rf "${dst}".syncing_* 2>/dev/null || true

  if $USE_SYMLINKS; then
    if ! ln -s "$src" "$staging"; then
      echo "  [ERROR]   $label (symlink failed)"
      return 1
    fi
  else
    if ! cp -r "$src" "$staging"; then
      echo "  [ERROR]   $label (copy failed)"
      rm -rf "$staging" 2>/dev/null
      return 1
    fi
  fi

  # These run with errexit suppressed (the callers invoke the helper inside an
  # `if`), so every step has to be checked by hand. An unchecked `mv` that fails
  # -- e.g. the destination is locked by a running process on Windows -- would
  # otherwise fall straight through to the success line, inflate SYNCED, and
  # leave ERRORS at 0, which in turn lets the prune step run as if all were well.
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if ! rm -rf "$dst"; then
      echo "  [ERROR]   $label (could not replace existing destination)"
      return 1
    fi
  fi
  if ! mv "$staging" "$dst"; then
    echo "  [ERROR]   $label (install failed)"
    rm -rf "$staging" 2>/dev/null
    return 1
  fi
  echo "  [$( $USE_SYMLINKS && echo symlink || echo copy )]    $label"
  SYNCED=$((SYNCED + 1))
}

link_or_copy_file() {
  local src="$1" dst="$2" label="$3"
  local staging="${dst}.syncing_$$"
  rm -rf "${dst}".syncing_* 2>/dev/null || true

  if $USE_SYMLINKS; then
    if ! ln -s "$src" "$staging"; then
      echo "  [ERROR]   $label (symlink failed)"
      return 1
    fi
  else
    if ! cp "$src" "$staging"; then
      echo "  [ERROR]   $label (copy failed)"
      rm -f "$staging" 2>/dev/null
      return 1
    fi
  fi

  # Clear whatever is at $dst, whatever kind of thing it is. Testing only for
  # -f here would skip a stray directory, and `mv file dir/` then SUCCEEDS by
  # moving the file inside it -- a silent wrong install that still reports OK.
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if ! rm -rf "$dst"; then
      echo "  [ERROR]   $label (could not replace existing destination)"
      return 1
    fi
  fi
  if ! mv "$staging" "$dst"; then
    echo "  [ERROR]   $label (install failed)"
    rm -f "$staging" 2>/dev/null
    return 1
  fi
  echo "  [$( $USE_SYMLINKS && echo symlink || echo copy )]    $label"
  SYNCED=$((SYNCED + 1))
}

# ── Guard: source must actually be there ──────────────────────────────────────
# If the source drive is not mounted the two loops below match nothing, the new
# manifest comes out empty, and the prune step would then delete every skill and
# command a previous run installed. Refuse to run at all in that case.
for required in "$SETUP_DIR/skills" "$SETUP_DIR/commands"; do
  if [ ! -d "$required" ]; then
    echo "ERROR: $required not found — is the source drive mounted?" >&2
    echo "Refusing to sync (pruning could delete everything already installed)." >&2
    exit 1
  fi
done

# ── Skills ────────────────────────────────────────────────────────────────────
echo "Skills:"
for skill_dir in "$SETUP_DIR/skills"/*/; do
  [ -d "$skill_dir" ] || continue
  name=$(basename "$skill_dir")
  # Only record what actually synced — a failed item must not be treated as
  # "still present" on the next run, nor as "removed from source" either.
  if link_or_copy_dir "$skill_dir" "$CLAUDE_DIR/skills/$name" "skills/$name"; then
    echo "skills/$name" >> "$NEW_MANIFEST"
  else
    ERRORS=$((ERRORS + 1))
  fi
done

# ── Commands ──────────────────────────────────────────────────────────────────
echo ""
echo "Commands:"
for cmd_file in "$SETUP_DIR/commands"/*.md; do
  [ -f "$cmd_file" ] || continue
  name=$(basename "$cmd_file")
  if link_or_copy_file "$cmd_file" "$CLAUDE_DIR/commands/$name" "commands/$name"; then
    echo "commands/$name" >> "$NEW_MANIFEST"
  else
    ERRORS=$((ERRORS + 1))
  fi
done

# ── Prune ─────────────────────────────────────────────────────────────────────
# Anything listed in the previous manifest but absent from this run's manifest
# was deleted from the source repo, so remove it from ~/.claude too.
if [ ! -s "$NEW_MANIFEST" ]; then
  # Nothing synced at all. Whatever the cause, "the source is now empty" is the
  # one conclusion we must not draw — that would prune everything.
  echo ""
  echo "WARNING: nothing was synced; skipping prune and leaving the manifest alone." >&2
elif [ "$ERRORS" -gt 0 ]; then
  echo ""
  echo "WARNING: $ERRORS item(s) failed to sync; skipping prune to stay on the safe side." >&2
elif [ -f "$MANIFEST" ]; then
  echo ""
  echo "Prune:"
  while IFS= read -r entry; do
    [ -n "$entry" ] || continue
    grep -Fxq "$entry" "$NEW_MANIFEST" && continue
    target="$CLAUDE_DIR/$entry"
    if [ -L "$target" ] || [ -e "$target" ]; then
      rm -rf "$target"
      echo "  [removed] $entry"
      PRUNED=$((PRUNED + 1))
    fi
  done < "$MANIFEST"
  [ "$PRUNED" -eq 0 ] && echo "  (nothing to prune)"
fi

# Only record the new state once we know the run was clean, so a partial run
# can't erase the record of what a previous good run installed.
if [ -s "$NEW_MANIFEST" ] && [ "$ERRORS" -eq 0 ]; then
  cp "$NEW_MANIFEST" "$MANIFEST"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "Done — $SYNCED item(s) synced, $PRUNED pruned, $SKIPPED skipped, $ERRORS error(s)."
[ "$ERRORS" -gt 0 ] && exit 1
$USE_SYMLINKS || echo "Tip: enable Windows Developer Mode for real symlinks (no re-sync needed on changes)."
