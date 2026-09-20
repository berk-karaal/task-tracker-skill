---
name: Release
description: Publish a new version of the task-tracker plugin for Claude Code and OpenCode V2 after its commands, skill, hook, tests, and docs are ready.
---

# Release task-tracker

Keep the versions in `package.json`, `package-lock.json`, and
`plugins/task-tracker/.claude-plugin/plugin.json` identical. Publishing means pushing `main`
and a matching `v<version>` Git tag to `berk-karaal/task-tracker-skill`; Claude Code consumes
the marketplace plugin and OpenCode consumes the Git package from the same commit.

## Steps

1. Confirm the release changes exist on disk. Fetch first, verify `main` is in sync with
   `origin/main`, and keep unrelated uncommitted changes out of the release.
2. Review changes since the latest tag:
   ```sh
   last=$(git describe --tags --abbrev=0 2>/dev/null); git log ${last:+$last..}HEAD --oneline
   ```
3. Choose the SemVer bump:
   - patch: fixes and wording or documentation changes
   - minor: a new command, skill, hook, or backward-compatible behavior
   - major: removed or renamed commands, incompatible `.tasks/` changes, or other breaks
4. Update the npm package version without creating a commit or tag, then set the same version
   in the Claude plugin manifest:
   ```sh
   npm version <patch|minor|major> --no-git-tag-version
   ```
5. Keep `README.md`, command files under `plugins/task-tracker/commands/`, and
   `plugins/task-tracker/skills/task-tracking/SKILL.md` consistent with the shipped behavior.
6. Validate:
   ```sh
   npm test
   npm pack --dry-run
   claude plugin validate . --strict
   claude plugin validate plugins/task-tracker --strict
   ```
   In a clean temporary project, load this checkout as a local package and confirm through
   OpenCode's `/api/plugin`, `/api/command`, and `/api/skill` endpoints that the plugin is
   active and its registrations are present.
7. Commit only the release files with `release: task-tracker v<version>` and a short body of
   user-visible changes.
8. Push `main`, create an annotated `v<version>` tag on that commit, and push the tag:
   ```sh
   git push origin main
   git tag -a v<version> -m "task-tracker v<version>"
   git push origin v<version>
   ```
9. Tell users to update and restart OpenCode:
   ```sh
   opencode plugin update github:berk-karaal/task-tracker-skill
   opencode service restart
   ```
   Claude Code users update with:
   ```text
   /plugin marketplace update task-tracker-skill
   /plugin update task-tracker@task-tracker-skill
   ```

Do not release with mismatched package/plugin versions, a dirty tree, skipped validation, a
hand-edited `package-lock.json`, or a moved published tag. Make a new patch release to fix a
bad release.
