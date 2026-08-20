---
description: Remove a linked remote task from this project — deletes the symlink, INDEX row and qmd collection, never the remote docs
argument-hint: <task-id>
disable-model-invocation: true
allowed-tools: Bash, Read, Edit
---

# Unlink a remote task

Detach a linked task from this project. The remote folder and everything in it is left
byte-for-byte untouched — this command only removes local references.

## Steps

1. **Resolve the id** from `$ARGUMENTS`; if absent, read `.tasks/INDEX.md`, show the linked
   rows (`Source` other than `local`), and ask which one.

2. **Refuse anything that is not a link:**
   ```bash
   [ -L ".tasks/<id>" ] || echo "not a linked task"
   ```
   If `.tasks/<id>` is a real directory it is a local task — stop and say so. Deleting local
   task docs is not this command's job.

3. **Report the target before removing it:**
   ```bash
   cd ".tasks/<id>" && pwd -P
   ```
   Show the user the remote path that will be detached. If the link is dangling (`[ -L ]`
   true, `[ -d ]` false), say so and continue — removing a dangling link is exactly what
   this command is for.

4. **Remove the symlink — and only the symlink:**
   ```bash
   rm ".tasks/<id>"
   ```
   Never use a recursive delete and never add a trailing slash to that path; either one
   would delete the user's real task docs through the link.

5. **Drop the local INDEX row.** Edit `.tasks/INDEX.md` and remove this task's row. Leave
   every other row and the table header intact. The origin tasks root's own `INDEX.md`,
   if any, is not touched.

6. **Drop the qmd collection** (only if `command -v qmd` succeeds and `.tasks/.qmd` exists):
   ```bash
   cd .tasks && qmd collection remove <id>
   ```
   The collection points at the remote path, which still exists, so the background sync's
   prune will never clean it up on its own — this step is how it goes away.

7. **Confirm:** list what was removed locally (symlink, INDEX row, qmd collection) and state
   explicitly that the remote folder was not modified.

## Hard rules

- Only `.tasks/<id>` itself is deleted. Nothing inside the remote folder is ever removed.
- Never `git add`, commit, or push as part of unlinking.
