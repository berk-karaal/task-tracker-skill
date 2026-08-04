---
name: release
description: Use when publishing a new version of the task-tracker plugin — after changes to commands, skills, agents, or docs are done and users should be able to install the update.
---

# Release task-tracker

## How releasing works here

The plugin version lives in **one place**: `plugins/task-tracker/.claude-plugin/plugin.json` → `"version"`. `marketplace.json` has no version field — do not add one. Publishing = pushing `main` to GitHub (`berk-karaal/task-tracker-skill`); there is no build, CI, or registry. Installed users only see an update when `"version"` changes — pushing without a bump publishes nothing from their point of view.

## Steps

1. **Preflight.**
   - Confirm the change being released actually exists on disk (read the new/changed files — don't release from the conversation's claim alone).
   - On `main`, in sync with `origin/main` (fetch first), working tree clean. If unrelated uncommitted changes exist, commit or stash them separately first — `claude plugin tag` refuses uncommitted changes affecting the release.
   - Review release scope:
     ```
     last=$(git describe --tags --abbrev=0 2>/dev/null); git log ${last:+$last..}HEAD --oneline
     ```
     (full history before the first tag exists, tag-to-HEAD after).

2. **Pick the bump** (semver):
   - patch — fixes, wording, doc-only changes
   - minor — new command/skill/agent, new behavior, new frontmatter options
   - major — breaking: renamed/removed command, changed `.tasks/` layout

3. **Bump** `"version"` in `plugins/task-tracker/.claude-plugin/plugin.json`.

4. **Sync docs to the change:**
   - `README.md` — Commands table, "What gets created", "Typical flow"
   - New command files must follow the sibling conventions in `plugins/task-tracker/commands/` (all set `disable-model-invocation: true`; read-only commands set `disallowed-tools: Write, Edit`; check `argument-hint` / `allowed-tools` against comparable siblings)
   - Changed command files — frontmatter still matches the body
   - `plugins/task-tracker/skills/task-tracking/SKILL.md` — if the change touches `.tasks/` layout or the INDEX status vocabulary, the bundled skill must describe it too
   - Descriptions in `plugin.json` and the plugin's entry in `.claude-plugin/marketplace.json` — update only if plugin scope changed (they are independent texts, not required to match verbatim)

5. **Validate:**
   ```
   claude plugin validate . --strict
   claude plugin validate plugins/task-tracker --strict
   ```
   Both must exit 0. After committing (step 6), also run `claude plugin tag plugins/task-tracker --dry-run` **before** pushing — it is the only check that catches plugin.json ↔ marketplace disagreement, an already-existing tag, and uncommitted release files, and you want that before `main` is published. These check **manifests only** — they never parse `commands/*.md` or skill files, so review changed markdown yourself; for behavior changes, smoke-test the command in a throwaway project before releasing.

6. **Commit** — scoped, never `git add -A`. Stage exactly: the shipped plugin files, `plugin.json`, `README.md`, and `marketplace.json` if touched. Message: `release: task-tracker v0.2.0` (body: one line per user-visible change).

7. **Push, then tag** — branch first, so the tag never points at a commit missing from `origin/main`:
   ```
   git push origin main
   claude plugin tag plugins/task-tracker -m "task-tracker v%s" --push
   ```
   Tag format is `task-tracker--v{version}`, created by the CLI — don't hand-tag. Bad tag? Delete remotely with `git push origin :refs/tags/task-tracker--v0.2.0`, locally with `git tag -d task-tracker--v0.2.0`, fix, re-tag (`--force` skips the tag-exists check if you must re-cut the same version).

8. **Tell the user how updates reach installs** (include in your final summary):
   ```
   /plugin marketplace update task-tracker-skill
   /plugin update task-tracker@task-tracker-skill
   ```
   then restart Claude Code. New users: install per README.

## Common mistakes

| Mistake | Reality |
|---|---|
| Push without version bump | Installed users never see the update |
| Add version to marketplace.json | No such field; version is plugin.json only |
| Release before verifying the change exists on disk | You ship a bumped version documenting a phantom feature |
| Skip README table on command changes | README is the user-facing contract |
| Treat `validate --strict` as full coverage | It reads manifests only; command/skill markdown is never checked |
| `git add -A` for the release commit | Sweeps unrelated local files into the release |
| Tag before pushing `main` | Failed branch push leaves a published tag on an orphan commit |
| Hand-create the git tag | `claude plugin tag` validates plugin.json ↔ marketplace agreement — use it |
