---
name: update-my-skill
description: Pull Pocket Skill from origin/main, then refresh the bundled my-skill plugin registration.
allowed-tools: [git, bash]
---

## Instructions

When the user invokes this skill, update their Pocket Skill installation from `origin/main`, then refresh the `my-skill` plugin registration. If the user only wants to refresh local skill changes without pulling from remote, use `refresh-my-skill` instead.

All operations must happen from the pocketskill repository root. First locate it:

- Use the current working directory if it contains `plugins/my-skill/skills/` and `install.sh`.
- Otherwise search upward from the current working directory.
- If no root is found, ask the user for the pocketskill path and stop until they provide it.

## Workflow

### 1. Preflight

Before changing anything:

- Run `git rev-parse --is-inside-work-tree`; if it fails, stop and explain that updates require a git checkout.
- Run `git remote get-url origin`; if it fails, stop and ask the user to add the Pocket Skill GitHub remote.
- Run `git status --short`; if there are uncommitted changes, stop and show the changed paths. Ask the user to commit, stash, or discard them before updating. Do not overwrite local skill edits.
- Confirm `install.sh` exists and is executable. If it exists but is not executable, run `chmod +x install.sh`.

### 2. Pull From Main

Update from the remote main branch:

1. `git fetch origin main`
2. If not already on `main`, switch with `git switch main`
3. `git pull --ff-only origin main`

If switching branches or pulling fails because of local changes, stop and report the blocker. Do not use `git reset`, forced checkout, or rebase unless the user explicitly asks.

### 3. Refresh My Skill Plugin

After the pull succeeds, refresh the plugin registration without bumping the version locally:

```
./install.sh --yes
```

This registers the marketplace and enables the `my-skill` plugin for detected tools:

- Claude Code: `/my-skill:<skill-name>`
- Codex: `$<skill-name>`
- General agents: direct `SKILL.md` file usage

Do not promise hot reload for the current running conversation. If the refreshed skill list is not visible immediately, tell the user to open a new session or restart the tool.

### 4. Verify

Verify the update:

- `git status --short --branch` should show the local branch tracking `origin/main`.
- Confirm `plugins/my-skill/skills/` exists.
- If Claude Code or Codex was detected by `install.sh`, report the command users can run next, for example `/my-skill:create-skill` or `$create-skill`.

Keep the final response short: report whether the pull succeeded, whether plugin registration was refreshed, and any manual action still needed.
