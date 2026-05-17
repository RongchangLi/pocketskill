---
name: delete-skill
description: Delete or archive an existing Pocket Skill with confirmation, private-skill safeguards, and local plugin refresh.
allowed-tools: [bash, git]
---

## Instructions

When the user invokes this skill, remove an existing Pocket Skill from their local library.

All operations must happen from the pocketskill repository root. First locate it:

- Use the current working directory if it contains `plugins/my-skill/skills/` and `install.sh`.
- Otherwise search upward from the current working directory.
- If no root is found, ask the user for the pocketskill path and stop until they provide it.

## Workflow

### 1. Identify The Target

- If the user did not name a skill, list directories under `plugins/my-skill/skills/` that contain `SKILL.md`, then ask which one to remove.
- Skip `.DS_Store`, cache files, and directories without `SKILL.md`.
- Confirm the target path is exactly `plugins/my-skill/skills/<skill-name>/`.
- If the target does not exist, stop.

### 2. Confirm Intent

Show the user:

- skill name
- absolute path
- whether it is public or private
- whether it appears tracked by git, if inside a git repository

Ask whether they want to:

1. Delete it
2. Archive it as a private skill

Never remove a skill without explicit confirmation. For built-in Pocket Skill workflows such as `create-skill`, `edit-skill`, `rename-skill`, `delete-skill`, `refresh-my-skill`, `update-my-skill`, or `share-skill`, warn that removing it changes the management tool itself and ask for a second confirmation.

### 3. Delete Or Archive

For delete:

- If inside a git repository and the skill is tracked, use `git rm -r -- plugins/my-skill/skills/<skill-name>/`.
- Otherwise remove only the exact target directory after confirmation.
- Do not use broad globs.

For archive:

- Move the directory to `plugins/my-skill/skills/private-archived-<skill-name>/`.
- If that archive target already exists, ask for a different archive name.
- Update the archived `SKILL.md` frontmatter `name` to the archive directory name.

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
