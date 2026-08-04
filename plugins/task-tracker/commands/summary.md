---
description: Read-only status report for a task AND context priming to resume work — writes nothing
argument-hint: [task-id]
disable-model-invocation: true
allowed-tools: Bash, Read, Glob
disallowed-tools: Write, Edit
---

# Summarize task (read-only)

This command has two jobs and **writes nothing**, so the user can change direction freely
afterward:

1. **Report** the current state to the user.
2. **Prime your own context** to continue the task in this session.

## Steps

1. **Resolve the task.** Use `$ARGUMENTS` if given; else the active task; else read
   `.tasks/INDEX.md`, show it, and ask which task.

2. **Read, most-recent-relevant first:**
   - `.tasks/<id>/task.md` — the definition
   - `.tasks/<id>/progress.md` — the timeline + **Current status** / **Next action**
   - `notes/` files, latest dates first. Start with the ones referenced by recent progress
     bullets, then **glob `.tasks/<id>/notes/` directly** to catch recent notes that no
     milestone bullet links (the progress log is milestone-only, so non-milestone findings
     live only in `notes/`).
   - If `qmd` is installed and `.tasks/.qmd/` exists, note in your report that task-doc
     search is available (`cd .tasks && qmd query "..." -c <id>`) and prefer it over
     manual `notes/` scanning for anything you cannot find via `progress.md`.

3. **Print a report** covering: the goal (1 line), what is **done**, what is **in
   progress**, what is **left**, and the **next action**. Cite note files where useful.

4. **Do not write, edit, or create any file.** No progress bullet, no notes, no INDEX
   change, no commit. This command is read-only by contract.
