---
name: task-tracking
description: Conventions and auto-maintenance for local-only persistent task docs under .tasks/. Use while working any tracked task to keep progress.md, notes/, and INDEX.md fresh as work proceeds, so the task survives context resets and fresh sessions.
when_to_use: When a task is being tracked under .tasks/, when the user mentions task progress / task docs / resuming a task, after /task-tracker:init or /task-tracker:summary has set an active task, or before doing substantial work that should be recoverable in a later session.
---

# Task Tracking

Local-only, persistent task documentation under `.tasks/`. Keeps long-running work
recoverable across sessions and context resets. Follow these conventions whenever a
tracked task is active.

## Where docs live

`.tasks/` at the repo root, **git-ignored** (never committed, never pushed):

```
.tasks/
├─ INDEX.md          # cross-task table
└─ <task-id>/
   ├─ task.md        # definition (living — evolves as the task takes shape)
   ├─ progress.md    # thin dated timeline (living)
   └─ notes/
      └─ YYYY-MM-DD-HH-mm-<slug>.md   # detail
```

`<task-id>` = ticket key + slug when a key exists (`PROJ-1234-add-auth`), else a kebab
slug (`blog-redesign`).

## Timestamps — always from `date`, never guessed

- In-doc timestamps + `INDEX.md` `last-updated`: `date '+%Y-%m-%d %H:%M'` → `2026-06-21 14:30`
- `notes/` filenames: `date '+%Y-%m-%d-%H-%M'` → `2026-06-21-14-30-summary.md`
  (minute precision so multiple notes in the same hour stay ordered)

## File roles

**task.md** — the definition. Goal, why, scope (in/out), acceptance criteria,
constraints, links. Written at init, but **not locked**: tasks often start without solid
grounding and sharpen during the work. When scope or direction genuinely changes,
update the affected sections so task.md always reflects the *current* definition, append
a dated entry to the `## Changelog` section in the same file (what changed + why), and
log the change as a milestone bullet in `progress.md`. All three happen together — a
scope change recorded in only one place is a violation.

**progress.md** — KEPT THIN, **milestone-level only**. A short intro (1-line description +
**Current status** + **Next action**), then a chronological **milestone** log. Each log item
is a `YYYY-MM-DD HH:MM` timestamp + one concise line, with a link to a `notes/` file when
there are details necessary. It is a milestone timeline/index, NOT a running changelog of single operation
and NOT a content dump. Reading it is how you discover the state of the task and what to do next.

The intro stays small: **1 line of description, one Current status line, one Next action
line.** If it starts growing into stacked banners or multi-line status, that is a smell — the
detail belongs in `notes/`, not the intro.

**notes/<YYYY-MM-DD-HH-MM>-<summary>.md** — where detail lives: findings, milestone write-ups, data,
`file:line` references, dead ends. Real work done that should be recoverable in a later session goes here.
Keep it granular, but do not let it bloat.

**INDEX.md** — one row per task: id, title, status, last-updated. Status vocabulary:
`active` / `in-progress` / `paused` / `blocked` / `done`.

## Auto-maintenance (while a tracked task is active)

Keep `notes/` fresh continuously, but keep `progress.md` **milestone-level**. Writing a note
or editing a doc does NOT by itself earn a `progress.md` bullet — decouple the two.

- **`notes/` — update freely.** As work proceeds, capture findings, data, `file:line`
  refs, decisions-in-flight, and dead ends in `notes/<date>-<slug>.md`. This is where the
  granular record lives.
- **`progress.md` — append ONLY on a milestone.** A milestone is one of:
  - a phase / meaningful step started, completed, waiting for review from other parties etc.
  - a PR is opened, merged, or closed,
  - a **scope or direction change** (approach abandoned/replaced/shifted, scope grew or
    shrank) — also update `task.md` and its `## Changelog` (see File roles),
  - a **blocker** hit or cleared,
  - a decision **LOCKED** (finalized — not every candidate or reversible decision),
  - the task **done**.
    On a milestone: append ONE concise dated bullet, link the relevant `notes/` file, and
    refresh the intro's **Current status** / **Next action**.
    (The initial `- <timestamp> — Task created.` bullet written at init is the one bootstrap
    entry that predates any milestone — expected, not a violation.)
- **Do NOT append a progress bullet for:** routine note/doc edits, intermediate findings,
  small or reversible decisions, minor scope tweaks, or "context is filling up." Those go
  to `notes/` only. If several micro-steps happened, fold them into the next milestone
  bullet rather than logging each.
- Keep `INDEX.md` `status` / `last-updated` current for the task.
- Never inline large content into `progress.md`; it stays a thin milestone timeline.

## Finding information in a tracked task

When you need to re-find information, findings, or decisions from earlier in the task
(especially past sessions), search in this order:

1. **`progress.md` first** — the intro + milestone log is the map; follow its links
   into `notes/`.
2. **qmd, if installed** (`command -v qmd`) and `.tasks/.qmd/` exists — preferred over
   manually scanning `notes/`:
   ```bash
   cd .tasks && qmd query "<what you are looking for>" -c <task-id>
   ```
   If models/embeddings are not ready yet (query errors or returns nothing after a
   fresh init), fall back to keyword search: `qmd search "<terms>" -c <task-id>`.
   If the active task has no collection yet (pre-qmd task), add it lazily:
   `cd .tasks && qmd collection add <task-id> --name <task-id>` and use `qmd search`
   until the background embed lands.
3. **Hits are locators, not answers.** When a result looks related, Read the whole
   note file it points to (`.tasks/<task-id>/<relpath from the qmd:// URI>`) before
   using its content. Never answer from snippets alone.
4. **No qmd?** Scan `notes/` directly (filenames are dated + slugged; grep content).

Index freshness is handled for you: a plugin hook re-indexes in the background
(~30–60s after writes). Never run `qmd update`/`qmd embed` in the foreground to
"make sure"; at most, note that a just-written file may not be indexed yet — it is
still in your context anyway.

## Hard rules

- Timestamps come from the real `date` command. Never invent them.
- Never let `progress.md` bloat — detail belongs in `notes/`.
- Never `git add` / commit / push `.tasks/`. It is local-only by design.

## Canonical file skeletons

### task.md

```markdown
# <Task title> (<task-id>)

## Goal

<what we are doing>

## Why

<motivation / value>

## Scope

**In:** <in scope>
**Out:** <explicitly out of scope>

## Acceptance criteria

- [ ] <criterion>

## Constraints

- <constraint, or "none">

## Links

- <Jira / PR / doc, or "none">

## Changelog

<!-- dated entries appended when scope/direction changes; empty at init -->
```

### progress.md

```markdown
# Progress — <task-id>

<1-line task description>

**Current status:** <status>
**Next action:** <the very next concrete step>

## Log

- <YYYY-MM-DD HH:MM> — Task created.
```

### INDEX.md

```markdown
# Tasks

| ID        | Title   | Status      | Last updated       |
| --------- | ------- | ----------- | ------------------ |
| <task-id> | <title> | in-progress | <YYYY-MM-DD HH:MM> |
```
