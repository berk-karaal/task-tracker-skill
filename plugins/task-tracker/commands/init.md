---
description: Initialize a new tracked task — interview, scaffold .tasks/<id>/ docs, gitignore it, add an INDEX row
argument-hint: [task-id-or-ticket-key]
disable-model-invocation: true
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion
---

# Initialize a new tracked task

Follow the `task-tracking` skill conventions (file roles, thin `progress.md`, `date`
timestamps, `.tasks/` layout, the canonical skeletons). For the rest of this session,
treat the task created here as the **active task** and auto-maintain its docs as you work.

## Steps

1. **Decide the task id.**
   - If an argument was given (`$ARGUMENTS`), use it as the basis.
   - If the work has a tracker key (e.g. `PROJ-1234`), id = `KEY-short-slug` (e.g. `PROJ-1234-add-auth`).
   - Otherwise id = a kebab slug of the goal (e.g. `blog-redesign`).
   - Propose the id to the user and confirm before creating anything.

2. **Gather the definition.** Ask the user for (or read from a pasted ticket): goal, why,
   in-scope, out-of-scope, acceptance criteria, constraints, links. Do not invent — ask
   for what is missing. Keep it tight.

3. **Get the timestamp:** run `date '+%Y-%m-%d %H:%M'` and reuse its output below.

4. **Create the structure:**
   ```bash
   mkdir -p .tasks/<task-id>/notes
   ```

5. **Write `.tasks/<task-id>/task.md`** using the skill's `task.md` skeleton, filled from
   step 2.

6. **Write `.tasks/<task-id>/progress.md`** using the `progress.md` skeleton: intro with
   **Current status:** `in-progress` and a concrete **Next action**, then a first log line
   `- <timestamp> — Task created.`

7. **Ensure `.tasks/` is git-ignored** (local-only — never pushed):
   ```bash
   if [ -f .gitignore ]; then
     grep -qxF '.tasks/' .gitignore || printf '\n# local-only task-tracker docs\n.tasks/\n' >> .gitignore
   else
     printf '# local-only task-tracker docs\n.tasks/\n' > .gitignore
   fi
   ```

8. **Update `.tasks/INDEX.md`:** if it is missing, create it from the `INDEX.md` skeleton.
   Add (or update) the row for this task: id, title, `in-progress`, timestamp, and `Source`
   = `local`. The table is 5 columns (`ID | Title | Status | Last updated | Source`); if the
   existing file still has the older 4-column form, migrate it, giving every existing row
   `Source` = `local`.

9. **qmd index (optional).** Only if the `qmd` CLI is installed (`command -v qmd`); skip
   this step silently otherwise:
   ```bash
   if command -v qmd >/dev/null 2>&1; then
     cd .tasks
     [ -d .qmd ] || qmd init
     qmd collection add <task-id> --name <task-id> 2>/dev/null || true
     cd ..
   fi
   ```
   Then kick the first index build without blocking: run
   `cd .tasks && qmd update && qmd embed` as a **background** Bash task
   (`run_in_background: true`). Do not wait for it or report its output; search falls
   back to BM25 until embeddings land.

10. **Confirm:** tell the user the task id, the files created, and that `.tasks/` is
    ignored. Mention whether qmd indexing was set up for this task. State that this task
    is now the active task for the session.

Never `git add` or commit `.tasks/`.
