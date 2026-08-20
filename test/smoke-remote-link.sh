#!/usr/bin/env bash
# Verification harness for remote (linked) task folders.
# Section A: static invariants of the plugin's command/skill docs.
# Section B: live symlink + qmd + unlink mechanics in a temp sandbox.
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CMD="$ROOT/plugins/task-tracker/commands"
SKILL="$ROOT/plugins/task-tracker/skills/task-tracking/SKILL.md"
FAILS=0

ok()   { printf '  ok   %s\n' "$1"; }
bad()  { printf '  FAIL %s\n' "$1"; FAILS=$((FAILS + 1)); }
check(){ if eval "$2" >/dev/null 2>&1; then ok "$1"; else bad "$1"; fi; }

echo "== A. doc invariants =="
check "link.md exists"                 "[ -f '$CMD/link.md' ]"
check "link.md disables model invoke"  "grep -q '^disable-model-invocation: true$' '$CMD/link.md'"
check "link.md has argument-hint"      "grep -q '^argument-hint:' '$CMD/link.md'"
check "link.md creates a symlink"      "grep -q 'ln -s' '$CMD/link.md'"
check "link.md gitignores .tasks/"     "grep -q '\.tasks/' '$CMD/link.md' && grep -q 'gitignore' '$CMD/link.md'"
check "link.md registers qmd coll."    "grep -q 'qmd collection add' '$CMD/link.md'"

check "unlink.md exists"               "[ -f '$CMD/unlink.md' ]"
check "unlink.md disables model invoke" "grep -q '^disable-model-invocation: true$' '$CMD/unlink.md'"
check "unlink.md removes collection"   "grep -q 'qmd collection remove' '$CMD/unlink.md'"
check "unlink.md never recursive-rm"   "! grep -q 'rm -r' '$CMD/unlink.md'"
check "unlink.md requires a symlink"   "grep -q '\-L ' '$CMD/unlink.md'"

check "init.md INDEX has Source col"   "grep -q '| Source' '$CMD/init.md'"
check "SKILL INDEX has Source col"     "grep -q '| Source' '$SKILL'"
check "list.md mentions Source"        "grep -q 'Source' '$CMD/list.md'"
check "update.md mentions origin INDEX" "grep -qi 'origin INDEX' '$CMD/update.md'"
check "summary.md mentions linked"     "grep -qi 'linked' '$CMD/summary.md'"
check "SKILL documents linked tasks"   "grep -qi 'linked task' '$SKILL'"
check "SKILL forbids resolved path"    "grep -qi 'never its resolved' '$SKILL'"
check "SKILL warns on logical parent"  "grep -q 'pwd -P' '$SKILL'"
check "link.md resolves before .."     "grep -q 'REMOTE=\$(cd' '$CMD/link.md'"
if grep -qF 'TASKS_DIR="${FILE%%/.tasks/*}/.tasks"' "$ROOT/plugins/task-tracker/scripts/qmd-sync.sh"
then ok "qmd-sync.sh untouched by design"; else bad "qmd-sync.sh untouched by design"; fi

echo "== B. live mechanics =="
SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT

REMOTE="$SANDBOX/task-director/.tasks/task-a"
PROJ="$SANDBOX/project-a"
mkdir -p "$REMOTE/notes" "$PROJ/.tasks"

cat > "$REMOTE/progress.md" <<'INNER'
# Progress — task-a

Remote task folder.

**Current status:** in-progress
**Next action:** verify linking

## Log

- 2026-08-20 10:00 — Task created.
INNER
echo '# task-a' > "$REMOTE/task.md"
cat > "$SANDBOX/task-director/.tasks/INDEX.md" <<'INNER'
# Tasks

| ID     | Title  | Status      | Last updated     | Source |
| ------ | ------ | ----------- | ---------------- | ------ |
| task-a | Task A | in-progress | 2026-08-20 10:00 | local  |
INNER
echo 'The zebra-striped retry loop lives at src/retry.go:88.' > "$REMOTE/notes/2026-08-20-10-00-retry.md"

BEFORE="$(cd "$REMOTE" && find . -type f -exec shasum {} + | sort)"

ln -s "$REMOTE" "$PROJ/.tasks/task-a"
check "symlink resolves to remote"   "[ \"\$(cd '$PROJ/.tasks/task-a' && pwd -P)\" = \"\$(cd '$REMOTE' && pwd -P)\" ]"
check "doc readable through link"    "grep -q 'Remote task folder' '$PROJ/.tasks/task-a/progress.md'"
check "origin INDEX detected"        "[ -f '$PROJ/.tasks/task-a/../INDEX.md' ]"
check "link is a symlink not a dir"  "[ -L '$PROJ/.tasks/task-a' ]"

if command -v qmd >/dev/null 2>&1; then
  ( cd "$PROJ/.tasks" && qmd init >/dev/null 2>&1
    qmd collection add task-a --name task-a >/dev/null 2>&1
    qmd update >/dev/null 2>&1 )
  check "qmd stored resolved path" \
    "grep -q \"\$(cd '$REMOTE' && pwd -P)\" '$PROJ/.tasks/.qmd/index.yml'"
  check "qmd finds remote-only note" \
    "( cd '$PROJ/.tasks' && qmd search 'zebra retry loop' -c task-a 2>/dev/null | grep -q 'retry' )"
  ( cd "$PROJ/.tasks" && qmd collection remove task-a >/dev/null 2>&1 )
  check "qmd collection removable" \
    "! grep -q '^  task-a:' '$PROJ/.tasks/.qmd/index.yml'"
else
  echo "  skip qmd assertions (qmd not installed)"
fi

echo 'local-index-must-not-win' > "$PROJ/.tasks/INDEX.md"
check "pwd -P reaches origin INDEX" \
  "grep -q 'task-a' \"\$(cd '$PROJ/.tasks/task-a' && pwd -P)/../INDEX.md\""
check "logical cd would read local" \
  "( cd '$PROJ/.tasks/task-a/..' && grep -q 'local-index-must-not-win' INDEX.md )"
rm "$PROJ/.tasks/INDEX.md"

rm "$PROJ/.tasks/task-a"
AFTER="$(cd "$REMOTE" && find . -type f -exec shasum {} + | sort)"
check "unlink left no local link"    "[ ! -e '$PROJ/.tasks/task-a' ]"
check "remote byte-identical"        "[ \"\$BEFORE\" = \"\$AFTER\" ]"

echo
if [ "$FAILS" -eq 0 ]; then
  echo "ALL PASS"
  exit 0
fi
echo "$FAILS FAILED"
exit 1
