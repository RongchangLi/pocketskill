---
name: share-skill
description: Share public Pocket Skills through a GitHub PR with git/gh preflight checks, clean commits, and private-skill safeguards.
allowed-tools: [git, gh]
---

## Instructions

When the user invokes this skill, you are helping them share a skill to the community via GitHub PR.

All operations must happen from the pocketskill repository root. First locate it:

- Use the current working directory if it contains `plugins/my-skill/skills/`.
- Otherwise search upward from the current working directory.
- If no root is found, ask the user for the pocketskill path and stop until they provide it.

## Workflow

### 1. Preflight

Run checks before listing or committing:

- `git rev-parse --is-inside-work-tree` must succeed. If not, tell the user this directory is not a git repository and provide setup commands instead of continuing.
- `git remote get-url origin` must succeed. If not, stop and ask the user to add a GitHub remote.
- `gh auth status` must succeed before creating a PR. If `gh` is missing or unauthenticated, still prepare the git commands but tell the user the exact `gh auth login` / `gh pr create` commands to run manually.
- Inspect `git status --short`. Never use plain `git commit` if unrelated staged changes exist.

### 2. Find Shareable Skills

List only changed public skill directories under `plugins/my-skill/skills/`.

Rules:

- Include directories with untracked, modified, or staged changes shown by `git status --short -- plugins/my-skill/skills`.
- Exclude any directory whose name starts with `private-`.
- Exclude `.DS_Store`, editor files, cache files, and directories without `SKILL.md`.
- Do not list unchanged built-in skills unless the user explicitly asks to share an existing committed skill.
- If nothing is shareable, say so and stop.

Show the candidate names and ask the user to choose one or `all`.

### 3. Review Before Sharing

For every selected skill, review `SKILL.md` before committing:

- Frontmatter must include non-empty `name` and `description`.
- Public skill names must match `^[a-z0-9]+(-[a-z0-9]+)*$` and must not start with `private-`.
- The body must contain real instructions, not just the template placeholder.
- Check for obvious secrets or private material: API keys, tokens, passwords, personal paths, private repo URLs, or private-skill references.

If a problem is found, stop and report what must be fixed. Never share private or suspicious content.

### 4. Commit On A PR Branch

Create a dedicated branch before committing:

- For one skill: `share/<skill-name>`
- For multiple skills: `share/multiple-skills`
- If the branch already exists, append a short timestamp or suffix.

Use path-limited staging and committing so unrelated user changes are not included:

1. `git switch -c <branch-name>`
2. `git add -- plugins/my-skill/skills/<skill-name>/` for each selected skill
3. Review `git diff --cached --name-only` and confirm every staged path is inside a selected public skill directory
4. `git commit -m "share: add <skill-name> skill" -- plugins/my-skill/skills/<skill-name>/` for one skill
5. For multiple skills, use `git commit -m "share: add community skills" -- <selected skill dirs>`

If unrelated paths are staged, do not run plain `git commit`; either commit with the selected pathspecs above or ask the user how to handle the staged changes.

### 5. Push And Open PR

Push the branch:

```
git push -u origin HEAD
```

Create the PR:

```
gh pr create --title "share: add <skill-name> skill" --body "## Description

Add community skill: **<skill-name>**.

## Review Notes

- Public skill only
- Frontmatter checked
- No private-skill directory included"
```

For multiple skills, use the title `share: add community skills` and list the skill names in the PR body.

Report the PR URL when done. If any command fails, report the current branch, whether a commit was created, and the exact next command the user should run.
