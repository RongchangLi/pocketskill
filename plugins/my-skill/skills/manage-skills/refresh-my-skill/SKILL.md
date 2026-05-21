---
name: refresh-my-skill
description: Refresh the local my-skill plugin registration after adding or editing skills, without pulling from remote.
allowed-tools: [bash, git]
---

## Instructions

When the user invokes this skill, refresh the local Pocket Skill plugin registration. Do not pull, fetch, or update from remote. Use `update-my-skill` when the user wants to pull from `origin/main` first.

## Tool Expectations

This workflow may use shell commands and `git` status checks.

All operations must happen from the pocketskill repository root. First locate it:

- Use the current working directory if it contains `plugins/my-skill/skills/` and `install.sh`.
- Otherwise search upward from the current working directory.
- If no root is found, ask the user for the pocketskill path and stop until they provide it.

## Workflow

### 1. Preflight

- Confirm `install.sh` exists.
- If `install.sh` is not executable, run `chmod +x install.sh`.
- If inside a git repository, run `git status --short` and note any existing changes. Do not require a clean tree; refresh is commonly used after local skill edits.

### 2. Refresh Local Plugin Registration

Run this from the pocketskill repository root:

```
./install.sh --yes --bump-plugin-version
```

This increments the `my-skill` plugin patch version, re-registers the local marketplace, exports the categorized source directories into a flat `skills/<name>/SKILL.md` plugin cache, and asks Claude Code / Codex plugin managers to refresh their installed library.

This skill must not run:

- `git fetch`
- `git pull`
- `git switch`
- `git reset`
- any remote update command

### 3. Verify

- Confirm `plugins/my-skill/skills/` and its subdirectories (`my-skills/`, `manage-skills/`, `private-skills/`) still exist.
- Confirm the refreshed Claude Code / Codex cache contains flat paths such as `skills/create-skill/SKILL.md`, not only `skills/manage-skills/create-skill/SKILL.md`.
- If inside a git repository, run `git status --short --branch`.
- If plugin manifest files changed because the version was bumped, report that clearly.

Do not promise hot reload for the current running conversation. If the refreshed skill list is not visible immediately, tell the user to open a new session or restart the tool. General agents can use any skill immediately by reading the relevant `SKILL.md` file.
