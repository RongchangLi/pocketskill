---
name: rename-skill
description: Rename an existing Pocket Skill directory and frontmatter safely, update obvious references, then refresh local plugin registration.
allowed-tools: [bash, git]
---

## Instructions

When the user invokes this skill, rename an existing Pocket Skill.

## Tool Expectations

This workflow may use shell commands and `git` commands such as `git mv`.

All operations must happen from the pocketskill repository root. First locate it:

- Use the current working directory if it contains `plugins/my-skill/skills/` and `install.sh`.
- Otherwise search upward from the current working directory.
- If no root is found, ask the user for the pocketskill path and stop until they provide it.

## Workflow

### 1. Collect Names

Ask for the old skill name and new skill name if missing.

Validate both base names:

- Must match `^[a-z0-9]+(-[a-z0-9]+)*$`
- Must not contain `/`, `\`, `.`, `..`, spaces, shell metacharacters, or quotes

Resolve the old path by searching `my-skills/` and `private-skills/`:

```
plugins/my-skill/skills/my-skills/<old-name>/SKILL.md
plugins/my-skill/skills/private-skills/<old-name>/SKILL.md
```

- If the old skill is in `manage-skills/`, refuse with "Built-in management skills cannot be renamed."
- Stop if the old skill does not exist or the new target already exists in either `my-skills/` or `private-skills/`.

The new skill stays in the same parent directory as the old one unless the user explicitly asks to move between `my-skills/` and `private-skills/`.

### 2. Rename Safely

- The new path is `<repo-root>/plugins/my-skill/skills/<parent-dir>/<new-name>/SKILL.md`.
- If inside a git repository and the old skill is tracked, use `git mv`.
- Otherwise use a normal directory move.
- Update the moved `SKILL.md` frontmatter `name` to the new skill name.
- Update the first Markdown heading if it is clearly derived from the old name.
- Keep `description` unchanged unless the user asked to revise it.

### 3. Update Obvious References

Search for the old name in the repository:

```
rg "<old-name>"
```

Update obvious references in docs or install output, such as README call examples and built-in skill tables. Ask before changing unrelated content.

### 4. Validate And Refresh

After renaming:

- Confirm only the new directory exists.
- Confirm `SKILL.md` frontmatter `name` equals the new skill name.
- If inside a git repository, run `git status --short`.
- Run local refresh from the pocketskill root:

```
./install.sh --yes --bump-plugin-version
```

Do not promise hot reload for the current running conversation. If the renamed skill is not visible immediately, tell the user to open a new session or restart the tool.
