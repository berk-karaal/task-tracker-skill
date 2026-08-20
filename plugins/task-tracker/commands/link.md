---
description: Link a task folder that lives outside this project into .tasks/ so every task-tracker command works on it here
argument-hint: <path-to-task-folder> [task-id]
disable-model-invocation: true
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion
---

# Link a remote task folder

Make a task whose docs live outside this project usable from here. The task folder is
symlinked into `.tasks/`, so every other command, the `task-tracking` skill, and qmd search
address it exactly like a local task: `.tasks/<id>/progress.md`, `.tasks/<id>/notes/`,
`qmd query "..." -c <id>`.

Never copy the remote docs, and never modify anything in the remote folder during linking.

## Steps

1. **Resolve the path.** Take the first argument from `$ARGUMENTS`, expand `~`, make it
   absolute:
   ```bash
   ABS=$(cd "<path>" 2>/dev/null && pwd -P)
   ```
   Abort with a clear message if the path is not a directory, or if `$ABS/task.md` is
   missing — a task folder without `task.md` is not a task.

2. **Decide the id.** Use the second argument if given, else `basename "$ABS"`. If
   `.tasks/<id>` already exists (file, directory, symlink, or a row in `.tasks/INDEX.md`),
   ask the user for a distinct id and use that; never overwrite an existing entry.

3. **Prepare the local tasks dir:**
   ```bash
   mkdir -p .tasks
   if [ -f .gitignore ]; then
     grep -qxF '.tasks/' .gitignore || printf '\n# local-only task-tracker docs\n.tasks/\n' >> .gitignore
   else
     printf '# local-only task-tracker docs\n.tasks/\n' > .gitignore
   fi
   ```

4. **Create the link:**
   ```bash
   ln -s "$ABS" ".tasks/<id>"
   ```

5. **Detect the origin tasks root.** Resolve the real location first, then look next to it:
   ```bash
   REMOTE=$(cd ".tasks/<id>" && pwd -P)
   [ -f "$REMOTE/../INDEX.md" ]
   ```
   Always go through `pwd -P`. `cd .tasks/<id>/..` lands in the **local** `.tasks/`, not the
   remote parent, so it would read the wrong INDEX.

   If that file exists, the remote folder belongs to another tasks root and its `INDEX.md`
   is **authoritative** for this task's status and last-updated — read the task's row from
   it. If it does not exist, read **Current status** from the remote `progress.md` intro
   instead.

6. **Get the timestamp:** `date '+%Y-%m-%d %H:%M'`.

7. **Update the local `.tasks/INDEX.md`:**
   - create it from the `task-tracking` skill's `INDEX.md` skeleton if missing;
   - if it is an older 4-column table, migrate it to 5 columns, giving every existing row
     `Source` = `local`;
   - add this task's row: id, title (from the remote `task.md` heading), status and
     last-updated copied from the source found in step 5, `Source` = `$ABS`.

8. **qmd index (optional).** Only if `command -v qmd` succeeds; skip silently otherwise:
   ```bash
   if command -v qmd >/dev/null 2>&1; then
     cd .tasks
     [ -d .qmd ] || qmd init
     qmd collection add <id> --name <id> 2>/dev/null || true
     cd ..
   fi
   ```
   Then run `cd .tasks && qmd update && qmd embed` as a **background** Bash task
   (`run_in_background: true`). Do not wait for it. qmd stores the resolved remote path, so
   notes written directly in the remote folder are indexed too.

9. **Confirm:** report the id, the remote path, whether an origin `INDEX.md` governs its
   status, and whether qmd indexing was set up. State that this task is now the **active
   task** for the session, and that its docs live outside this project.

## Hard rules

- Address the task as `.tasks/<id>/...` from now on — never by its resolved remote path
  (the qmd re-index hook only fires for paths under `.tasks/`).
- Never `git add`, commit, or push `.tasks/` or the remote folder.
- Linking never writes inside the remote folder.
