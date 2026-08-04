# task-tracker

A local-only Claude Code plugin for **persistent task tracking**. Keeps long-running
tasks (work that spans days, sessions, or context resets) recoverable, by maintaining a
small set of markdown docs under `.tasks/` in each project. The docs are **never committed
or pushed** — they exist only for you and your coding agent, locally.

## Install

```
/plugin marketplace add berk-karaal/task-tracker-skill
/plugin install task-tracker@task-tracker-skill
```

## Commands

All commands are namespaced under the plugin, so they never collide with other plugins:

| Command | What it does |
|---|---|
| `/task-tracker:init [id]` | Interview you for the task definition, scaffold `.tasks/<id>/`, gitignore `.tasks/`, add an INDEX row. |
| `/task-tracker:update [id]` | Flush this session's work into the docs — dated `progress.md` bullets, detailed `notes/` files, INDEX bump. |
| `/task-tracker:summary [id]` | **Read-only.** Print where the task stands AND prime the agent's context to resume. Writes nothing, so you can change direction. Use this on a fresh session to pick a task back up. |
| `/task-tracker:list` | Show all tracked tasks and their status. |

While a task is active, the bundled `task-tracking` skill auto-maintains the docs as the
agent works (concise dated bullets, detail spun out to `notes/`).

## What gets created (per project)

```
.tasks/                              # git-ignored, local-only
├─ INDEX.md                          # id · title · status · last-updated
└─ <task-id>/
   ├─ task.md                        # goal · why · scope · acceptance criteria · links
   ├─ progress.md                    # thin dated timeline; links to notes/
   └─ notes/
      └─ YYYY-MM-DD-HH-mm-<slug>.md   # detailed findings / milestone write-ups
```

- `<task-id>` is a ticket key + slug (`PROJ-1234-add-auth`) when one exists, else a kebab
  slug (`blog-redesign`).
- `progress.md` stays thin — a timeline that points to detail in `notes/`.
- Timestamps come from the real `date` command, never guessed.

## Typical flow

```
/task-tracker:init PROJ-1234        # define + scaffold the task
...work; docs auto-update...
/task-tracker:update                # flush progress before stopping
# days later, fresh session:
/task-tracker:summary PROJ-1234     # read-only resume: status + context
```

## Optional: qmd search

If the [qmd](https://github.com/tobi/qmd) CLI is installed, task-tracker indexes each
task's docs into a local search engine at `.tasks/.qmd/` (git-ignored, like everything
else under `.tasks/`):

- `/task-tracker:init` creates a per-task collection automatically.
- A plugin hook re-indexes in the background after task docs change — debounced, never
  blocking.
- Agents search with `qmd query "<question>" -c <task-id>` (hybrid semantic search)
  after checking `progress.md`, and read the full matched note files.

Without qmd installed, everything behaves exactly as before — it is a purely optional
dependency.
