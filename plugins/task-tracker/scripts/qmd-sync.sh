#!/usr/bin/env bash
# PostToolUse hook target for the task-tracker plugin.
# Debounced background qmd re-index of .tasks/ docs. Reads hook JSON on stdin.
# Contract: ALWAYS exit 0 fast; heavy work happens detached; silent no-op
# without qmd or without a .tasks/.qmd index.
set -u

command -v qmd >/dev/null 2>&1 || exit 0

INPUT=$(cat 2>/dev/null || true)
FILE=$(printf '%s' "$INPUT" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)

case "$FILE" in
  */.tasks/*) ;;
  *) exit 0 ;;
esac

TASKS_DIR="${FILE%%/.tasks/*}/.tasks"
QMD_DIR="$TASKS_DIR/.qmd"
[ -d "$QMD_DIR" ] || exit 0

LOCK="$QMD_DIR/sync.lock"
DIRTY="$QMD_DIR/sync.dirty"
LOG="$QMD_DIR/sync.log"
QUIET="${QMD_SYNC_QUIET:-30}"

touch "$DIRTY"

# Single runner: mkdir is the atomic lock. Losers exit — their DIRTY touch
# guarantees the running loop does another pass.
mkdir "$LOCK" 2>/dev/null || exit 0

(
  trap 'rmdir "$LOCK" 2>/dev/null' EXIT
  cd "$TASKS_DIR" || exit 0
  while [ -e "$DIRTY" ]; do
    rm -f "$DIRTY"
    sleep "$QUIET"                    # quiet period
    [ -e "$DIRTY" ] && continue       # burst still going → restart quiet period, don't sync yet
    # Prune collections whose task dirs are gone (skips paths with spaces).
    awk '/^  [A-Za-z0-9_-]+:$/ {name=$1; sub(/:$/,"",name)}
         /^    path: / {print name, $2}' "$QMD_DIR/index.yml" 2>/dev/null |
    while read -r cname cpath; do
      [ -n "$cname" ] && [ -n "$cpath" ] && [ ! -d "$cpath" ] &&
        qmd collection remove "$cname" >>"$LOG" 2>&1
    done
    {
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] sync start"
      qmd update
      qmd embed
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] sync done"
    } >>"$LOG" 2>&1
  done
) </dev/null >/dev/null 2>&1 &

exit 0
