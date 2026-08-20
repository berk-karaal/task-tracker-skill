---
description: List all tracked tasks and their status (renders .tasks/INDEX.md)
disable-model-invocation: true
allowed-tools: Bash, Read
disallowed-tools: Write, Edit
---

# List tracked tasks

1. If `.tasks/INDEX.md` exists, read and render it (`ID | Title | Status | Last updated |
   Source`). Older 4-column tables render as-is; treat their rows as `Source` = `local`.
2. For every row whose `Source` is not `local`, the local row is only a mirror. Resolve the
   real state before rendering:
   ```bash
   [ -L ".tasks/<id>" ] && REMOTE=$(cd ".tasks/<id>" && pwd -P)
   ```
   - `$REMOTE/../INDEX.md` exists → read `status` / `last-updated` from that origin row.
   - Otherwise → read **Current status** from `$REMOTE/progress.md`'s intro.
   - `.tasks/<id>` is a dangling symlink (`[ -L ]` true, `[ -d ]` false) → render the row as
     `broken link` and show the missing target; suggest `/task-tracker:unlink <id>`.
3. If `INDEX.md` is missing but `.tasks/` has task entries, list those names, marking which
   are symlinks and where they point, and note that `INDEX.md` is absent.
4. If `.tasks/` does not exist, tell the user there are no tracked tasks yet and suggest
   `/task-tracker:init` (local task) or `/task-tracker:link <path>` (task folder elsewhere).

Read-only — do not modify anything, including the remote folders.
