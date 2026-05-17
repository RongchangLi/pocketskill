---
name: edit-skill
description: Edit an existing Pocket Skill safely, preserving metadata unless explicitly changed, then refresh local plugin registration.
allowed-tools: [bash, git]
---

## Instructions

When the user invokes this skill, edit an existing Pocket Skill in their local library.

All operations must happen from the pocketskill repository root. First locate it:

- Use the current working directory if it contains `plugins/my-skill/skills/` and `install.sh`.
- Otherwise search upward from the current working directory.
- If no root is found, ask the user for the pocketskill path and stop until they provide it.

## Workflow

### 1. Identify The Target

- If the user did not name a skill, list directories under `plugins/my-skill/skills/` that contain `SKILL.md`, then ask which one to edit.
- Skip `.DS_Store`, cache files, and directories without `SKILL.md`.
- Confirm the target path is exactly `plugins/my-skill/skills/<skill-name>/SKILL.md`.
- If the target does not exist, stop and suggest `create-skill`.

### 2. Inspect Before Editing

Read the target `SKILL.md` and identify:

- frontmatter `name`
- frontmatter `description`
- whether the body still looks like the template placeholder
- whether the skill is public or private based on a `private-` directory prefix

If the user wants to rename the skill or change the directory name, use `rename-skill` instead of editing in place.

### 3. Edit Safely

- Change only the target `SKILL.md` unless the user explicitly asks for related docs.
- Preserve frontmatter `name` unless the user explicitly asks to change display metadata without renaming the directory.
- Keep `description` short and trigger-oriented.
- Do not remove privacy safeguards from private skills.
- Do not add secrets, tokens, passwords, internal credentials, or private URLs.
- If editing a built-in Pocket Skill, keep the workflow concise and deterministic.

### 4. Validate And Refresh

After editing:

- Confirm frontmatter still contains non-empty `name` and `description`.
- If inside a git repository, run `git status --short -- plugins/my-skill/skills/<skill-name>/`.
- Run local refresh from the pocketskill root:

```
./install.sh --yes --bump-plugin-version
```

Do not promise hot reload for the current running conversation. If the edited skill is not visible immediately, tell the user to open a new session or restart the tool.
