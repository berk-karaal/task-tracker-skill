---
description: List all tracked tasks and their status (renders .tasks/INDEX.md)
disable-model-invocation: true
allowed-tools: Bash, Read
disallowed-tools: Write, Edit
---

# List tracked tasks

1. If `.tasks/INDEX.md` exists, read and render it (the id / title / status / last-updated
   table).
2. If it is missing but `.tasks/` has task folders, list those folder names and note that
   `INDEX.md` is absent.
3. If `.tasks/` does not exist, tell the user there are no tracked tasks yet and suggest
   `/task-tracker:init`.

Read-only — do not modify anything.
