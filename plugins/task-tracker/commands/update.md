---
description: Flush the current session's work into the active task's docs (progress.md, notes/, INDEX.md)
argument-hint: [task-id]
disable-model-invocation: true
allowed-tools: Bash, Read, Write, Edit
---

# Update task docs

Persist what happened in this session into the tracked task's docs, following the
`task-tracking` skill conventions. Keep `progress.md` thin; push detail to `notes/`.

## Steps

1. **Resolve the task.** Use `$ARGUMENTS` if given; else the active task for this session;
   else read `.tasks/INDEX.md` and ask the user which task.

2. **Get timestamps:** `date '+%Y-%m-%d %H:%M'` for bullets / INDEX, and — only if you
   will create a note — `date '+%Y-%m-%d-%H-%M'` for the filename.

3. **Append to `progress.md` — milestones only.** Add a concise dated bullet only for a
   real milestone, applying the `task-tracking` skill's milestone bar (see its
   Auto-maintenance section for the milestone list and the "do NOT log" exclusions — do not
   restate them here). Fold routine edits and small/reversible changes into the next
   milestone bullet or leave them in `notes/` — do NOT log one bullet per change. Update the
   intro's **Current status** and **Next action**, keeping the intro thin (1-line desc + one
   status line + one next-action line).

4. **Spin out detail when needed.** For any milestone with real detail — or any finding you
   want recoverable later, even if it is not itself a milestone — create
   `.tasks/<id>/notes/<YYYY-MM-DD-HH-mm>-<slug>.md` and put the detail there. When it
   accompanies a milestone, link it from that milestone's progress bullet, e.g.
   `- 2026-06-21 14:30 — Mapped the auth flow (→ notes/2026-06-21-14-30-auth-flow.md).`
   Non-milestone notes need no progress bullet; `/task-tracker:summary` finds them by
   scanning `notes/` directly.

5. **Patch `task.md`** only if scope / direction / acceptance criteria actually changed.
   If so, follow the skill's rule: update the affected sections, append a dated entry to
   task.md's `## Changelog`, and log the change as a milestone bullet in `progress.md`.

6. **Bump `INDEX.md`:** update this task's `status` and `last-updated`.

7. **Confirm** what you wrote (files touched, any new notes). Never `git add` or commit
   `.tasks/`.
