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

# ── Helpers ───────────────────────────────────────────────────────────────────
link_or_copy_dir() {
  local src="$1" dst="$2" label="$3"
  [ -L "$dst" ] && rm "$dst"
  [ -d "$dst" ] && rm -rf "$dst"
  if $USE_SYMLINKS; then
    ln -s "$src" "$dst" && echo "  [symlink] $label" || { echo "  [ERROR]   $label (symlink failed)"; return 1; }
  else
    cp -r "$src" "$dst" && echo "  [copy]    $label" || { echo "  [ERROR]   $label (copy failed)"; return 1; }
  fi
  SYNCED=$((SYNCED + 1))
}

link_or_copy_file() {
  local src="$1" dst="$2" label="$3"
  [ -L "$dst" ] && rm "$dst"
  [ -f "$dst" ] && rm "$dst"
  if $USE_SYMLINKS; then
    ln -s "$src" "$dst" && echo "  [symlink] $label" || { echo "  [ERROR]   $label (symlink failed)"; return 1; }
  else
    cp "$src" "$dst" && echo "  [copy]    $label" || { echo "  [ERROR]   $label (copy failed)"; return 1; }
  fi
  SYNCED=$((SYNCED + 1))
}

# ── Skills ────────────────────────────────────────────────────────────────────
echo "Skills:"
for skill_dir in "$SETUP_DIR/skills"/*/; do
  [ -d "$skill_dir" ] || continue
  name=$(basename "$skill_dir")
  link_or_copy_dir "$skill_dir" "$CLAUDE_DIR/skills/$name" "skills/$name"
done

# ── Commands ──────────────────────────────────────────────────────────────────
echo ""
echo "Commands:"
for cmd_file in "$SETUP_DIR/commands"/*.md; do
  [ -f "$cmd_file" ] || continue
  name=$(basename "$cmd_file")
  link_or_copy_file "$cmd_file" "$CLAUDE_DIR/commands/$name" "commands/$name"
done

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "Done — $SYNCED item(s) synced, $SKIPPED skipped."
$USE_SYMLINKS || echo "Tip: enable Windows Developer Mode for real symlinks (no re-sync needed on changes)."
