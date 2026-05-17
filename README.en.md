# 🎒 Pocket Skill

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/RongchangLi/pocketskill/pulls)

The public agent skill ecosystem is growing fast, but it solves for general capabilities — it can't fully match everyone's real-world workflows. Pocket Skill focuses on personal skill management: capture your project conventions, prompt templates, workflows, judgment criteria, and hard-earned experience as reusable skills, then sync them across Claude Code, Codex, and any general agent with a single command. It doesn't replace public skill ecosystems — it sits as your personal experience layer, complementing them. Everything is stored as plain text, managed with Git, cross-platform with zero lock-in.

Specifically, Pocket Skill gives you:

- 🏗️ **Create & Manage** — Interactive skill creation with public/private modes; built-in edit, rename, and delete for full lifecycle management.
- 🔒 **Public + Private** — `my-skills` are Git-tracked and optionally shareable; `private-skills` stay local, auto-gitignored, keeping personal preferences private.
- 🔄 **One-command Sync** — A single install command registers with Claude Code and Codex; new skills auto-refresh; general agents read `SKILL.md` directly.
- 📦 **Plain Text · Versionable** — Markdown + YAML, every change tracked by Git, never locked to any platform.
- 🧩 **Complementary to Public Ecosystems** — Keep using community skills as you always have; Pocket Skill fills in your personal experience layer.

[中文](README.md)

---

## 📋 Prerequisites

| Dependency | Notes |
| --- | --- |
| **Git** | Required for installation and updates |
| **Bash** | Built-in on macOS / Linux; Windows needs WSL or Git Bash |
| **Claude Code** / **Codex** | Either one gives the best experience; works with any general agent too |

## 🚀 Install

> 💡 Preview the script first: `curl -fsSL https://raw.githubusercontent.com/RongchangLi/pocketskill/main/install.sh | less`

**One-liner:**

```bash
curl -fsSL https://raw.githubusercontent.com/RongchangLi/pocketskill/main/install.sh | bash -s -- --yes
```

This installs to `~/.pocketskill`, detects Claude Code / Codex, registers the marketplace, and enables the `my-skill` plugin — all in one shot.

**Manual:**

```bash
git clone https://github.com/RongchangLi/pocketskill.git
cd pocketskill
./install.sh
```

## ⚡ Quick Start

| Action | Claude Code | Codex |
| --- | --- | --- |
| ✨ Create a skill | `/my-skill:create-skill` | `$create-skill` |
| 🔧 Use a skill | `/my-skill:<name>` | `$<name>` |
| 📤 Share a skill | `/my-skill:share-skill` | `$share-skill` |
| 🔄 Refresh locally | `/my-skill:refresh-my-skill` | `$refresh-my-skill` |
| ⬇️ Pull latest | `/my-skill:update-my-skill` | `$update-my-skill` |

No platform lock-in for general agents — just load `SKILL.md` as a rule, system prompt, or context file:

```text
# Personal skills
plugins/my-skill/skills/my-skills/<name>/SKILL.md
plugins/my-skill/skills/private-skills/<name>/SKILL.md

# Built-in management skills
plugins/my-skill/skills/manage-skills/<name>/SKILL.md
```

## 📂 Three Skill Categories

| Directory | Description | Operations |
| --- | --- | --- |
| `private-skills/` | 🔒 Private skills, ignored by `.gitignore`, never synced to remote | Create · Edit · Delete · Rename |
| `my-skills/` | 📝 Personal skills, Git-tracked, optionally shareable | Create · Edit · Delete · Rename |
| `manage-skills/` | ⚙️ Built-in management skills, updated with Pocket Skill | Read-only |

> ⚠️ Never put secrets, tokens, or passwords in any skill.

## 🗂️ Directory Structure

```text
pocketskill/
├── .agents/plugins/marketplace.json      # Codex marketplace
├── .claude-plugin/marketplace.json       # Claude Code marketplace
├── plugins/my-skill/
│   ├── .codex-plugin/plugin.json
│   ├── .claude-plugin/plugin.json
│   └── skills/
│       ├── private-skills/               # 🔒 Private skills (gitignored)
│       ├── my-skills/                    # 📝 Personal skills (optionally public)
│       │   └── <your-skill>/
│       ├── manage-skills/                # ⚙️ Built-in management (read-only)
│       │   ├── create-skill/
│       │   ├── edit-skill/
│       │   ├── rename-skill/
│       │   ├── delete-skill/
│       │   ├── share-skill/
│       │   ├── refresh-my-skill/
│       │   ├── update-my-skill/
│       │   ├── claude-save-token/
│       │   └── codex-save-token/
├── templates/SKILL.md.template
└── install.sh
```

## 🔄 Update & Refresh

| Command | Behavior |
| --- | --- |
| `refresh-my-skill` | Local plugin refresh only, no remote contact. Runs automatically after skill creation. |
| `update-my-skill` | `git pull --ff-only origin main` + refresh. Pulls the latest built-in skills and community contributions. |

**Manual update:**

```bash
cd ~/.pocketskill && git pull --ff-only && ./install.sh --yes
```

> ℹ️ Changes may not hot-reload in the current session: restart Claude Code or open a new session; Codex picks up changes in a new session; general agents can read the updated file immediately.

## 📤 Share & Contribute

1. `create-skill` → choose `my-skills` → fill in `SKILL.md`
2. `/my-skill:share-skill` or `$share-skill` → auto-checks, branches, commits, and opens a PR

Naming: lowercase + hyphens, e.g. `code-review`, `api-design`, `git-workflow`.

## 🔌 Compatibility

| Tool | How to use |
| --- | --- |
| **Claude Code** | `install.sh` registers marketplace → `/my-skill:<name>` |
| **Codex** | `install.sh` registers marketplace → `$<name>` |
| **Cursor** | Load `SKILL.md` as a rule or project context |
| **ChatGPT Projects** | Add `SKILL.md` to project knowledge or instructions |
| **Custom Agent** | Include in system prompt, tool context, or memory |
| **Other General Agents** | Copy or reference `SKILL.md` directly |

> 🧠 Pocket Skill isn't about a specific plugin format — it's about portable skill assets you own.

## 📄 License

[MIT](LICENSE)
