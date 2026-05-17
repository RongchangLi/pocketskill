---
name: delete-skill
description: Delete or archive an existing Pocket Skill with confirmation, private-skill safeguards, and local plugin refresh.
allowed-tools: [bash, git]
---

## Instructions

When the user invokes this skill, remove an existing Pocket Skill from their local library.

## Tool Expectations

This workflow may use shell commands and `git` commands such as `git rm`.

All operations must happen from the pocketskill repository root. First locate it:

- Use the current working directory if it contains `plugins/my-skill/skills/` and `install.sh`.
- Otherwise search upward from the current working directory.
- If no root is found, ask the user for the pocketskill path and stop until they provide it.

## Workflow

### 1. Identify The Target

- If the user did not name a skill, list directories under `plugins/my-skill/skills/my-skills/` and `plugins/my-skill/skills/private-skills/` that contain `SKILL.md`, then ask which one to remove.
- Never list or offer skills from `plugins/my-skill/skills/manage-skills/`. Built-in management skills cannot be deleted through this skill.
- Skip `.DS_Store`, cache files, and directories without `SKILL.md`.
- If the user explicitly names a skill in `manage-skills/`, refuse with the message "Built-in management skills cannot be deleted."
- Confirm the target path is `<repo-root>/plugins/my-skill/skills/<parent-dir>/<skill-name>/` where `<parent-dir>` is `my-skills` or `private-skills`.
- If the target does not exist, stop.

### 2. Confirm Intent

Show the user:

- skill name
- absolute path
- whether it is public (`my-skills/`) or private (`private-skills/`)
- whether it appears tracked by git, if inside a git repository

Ask whether they want to:

1. Delete it
2. Archive it (move to `private-skills/`)

Never remove a skill without explicit confirmation.

### 3. Delete Or Archive

For delete:

- If inside a git repository and the skill is tracked, use `git rm -r -- plugins/my-skill/skills/<parent-dir>/<skill-name>/`.
- Otherwise remove only the exact target directory after confirmation.
- Do not use broad globs.

For archive:

- If the skill is already in `private-skills/`, tell the user it is already private.
- Otherwise move the directory to `plugins/my-skill/skills/private-skills/<skill-name>/`.
- If that archive target already exists, ask for a different name.

### 4. Clean References

Search for the removed skill name:

```
rg "<skill-name>"
```

Update obvious references in README or built-in tables only when they point to the removed skill. Ask before editing unrelated content.

### 5. Refresh

After deletion or archive:

- If inside a git repository, run `git status --short`.
- Run local refresh from the pocketskill root:

```
./install.sh --yes --bump-plugin-version
```

Do not promise hot reload for the current running conversation. If the removed skill still appears immediately, tell the user to open a new session or restart the tool.
