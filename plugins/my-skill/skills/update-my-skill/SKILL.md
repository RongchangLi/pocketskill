---
name: update-my-skill
description: Update Pocket Skill from origin/main, refresh the bundled my-skill plugin, and re-register Claude Code/Codex plugin settings.
allowed-tools: [git, bash]
---

## Instructions

When the user invokes this skill, update their Pocket Skill installation and refresh the `my-skill` plugin registration.

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

After the pull succeeds, refresh the plugin registration:

```
./install.sh --yes
```

This updates the local Pocket Skill checkout, registers the marketplace, and enables the `my-skill` plugin for detected tools:

- Claude Code: `/my-skill:<skill-name>`
- Codex: `$<skill-name>`
- General agents: direct `SKILL.md` file usage

### 4. Verify

Verify the update:

- `git status --short --branch` should show the local branch tracking `origin/main`.
- Confirm `plugins/my-skill/skills/` exists.
- If Claude Code or Codex was detected by `install.sh`, report the command users can run next, for example `/my-skill:create-skill` or `$create-skill`.

Keep the final response short: report whether the pull succeeded, whether plugin registration was refreshed, and any manual action still needed.
