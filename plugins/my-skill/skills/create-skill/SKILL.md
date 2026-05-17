---
name: create-skill
description: Create a new Pocket Skill interactively; choose public/private, validate the name, and scaffold SKILL.md safely.
---

## Instructions

When the user invokes this skill, you are creating a new skill for their pocketskill library.

All skills live under `plugins/my-skill/skills/`. First locate the pocketskill repository root:

- Use the current working directory if it contains both `plugins/my-skill/skills/` and `templates/SKILL.md.template`.
- Otherwise search upward from the current working directory for those two paths.
- If the repository root cannot be found, ask the user for the pocketskill path. Do not create files in an unrelated project.

## Workflow

### 1. Ask Public Or Private

Ask one question if the user did not already specify:

```
Public or private?

1. Public - can be shared via PR to the community
2. Private - local only, never shared (gitignored)
```

Directory and skill name rules:

- Public: `<skill-name>`
- Private: `private-<skill-name>`

### 2. Collect And Validate Inputs

Ask for the skill name and one-line description if missing.

Validate the base skill name before creating anything:

- Must match `^[a-z0-9]+(-[a-z0-9]+)*$`
- Must not contain `/`, `\`, `.`, `..`, spaces, shell metacharacters, or quotes
- Must not start with `private-`; add that prefix only when the user chose Private
- If invalid, explain the rule and ask again

Trim the description. If it is empty, ask again. Keep it short because it is used for auto-trigger matching.

### 3. Create The Skill Safely

Use this target path:

```
<repo-root>/plugins/my-skill/skills/<directory-name>/SKILL.md
```

Before writing:

- If the directory or `SKILL.md` already exists, stop and ask whether the user wants to edit the existing skill. Do not overwrite.
- For private skills, confirm the path matches `plugins/my-skill/skills/private-*/` so `.gitignore` protects it.

Create `SKILL.md` from `templates/SKILL.md.template`, replacing:

- `skill-name` with the final skill name (`<skill-name>` for public, `private-<skill-name>` for private)
- `Brief description used for auto-trigger matching` with the user-provided description
- `Skill Title` with a title-cased version of the final skill name

### 4. Refresh Plugin Registration

After creating the file, automatically run the same local refresh used by `refresh-my-skill`:

```
./install.sh --yes --bump-plugin-version
```

Run it from the pocketskill repository root. This increments the `my-skill` plugin patch version, re-registers the local marketplace, and refreshes the plugin cache for detected tools when their CLIs support it.

Important:

- The version bump is intentional. It gives plugin managers a new version to install after a local skill is added.
- Do not promise that the current running Claude Code or Codex conversation will immediately see the new skill.
- If the new skill does not appear after refresh, tell the user to open a new session or restart the tool.
- General agents can use the new skill immediately by reading the created `SKILL.md` directly.

After creation and refresh, report the absolute path, whether refresh ran, and remind the user to fill in the instructions body. Do not edit unrelated files.
