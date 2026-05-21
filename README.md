# 🎒 Pocket Skill

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/RongchangLi/pocketskill/pulls)

公开的 Agent Skill 生态正在快速丰富，但它们解决的是通用能力，很难 100% 匹配每个人真实的工作习惯。Pocket Skill 专注于个人 Skill 管理：把你的项目规范、提示词模板、工作流、判断标准和长期经验沉淀为可复用的 Skill，并一键同步到 Claude Code、Codex 及任意通用 Agent。它不替代公开 Skill 生态，而是作为你的个人经验层，与现有 Skill 互补。所有内容都以纯文本存储，可用 Git 版本管理，跨平台、无锁定。

具体来说，Pocket Skill 有以下能力：

- 🏗️ **创建与管理** — 交互式创建 Skill，支持公开和私有；内置编辑、重命名、删除，全生命周期管理。
- 🔒 **公开 + 私有** — `my-skills` 可版本管理、可选择分享；`private-skills` 本地存储、自动 gitignore，个人偏好不外泄。
- 🔄 **一键同步** — 一条安装命令注册到 Claude Code 和 Codex，新增 Skill 自动刷新，通用 Agent 直接读 `SKILL.md`。
- 📦 **纯文本 · 可版本** — Markdown + YAML，Git 追踪每一次变更，不受任何平台绑定。
- 🧩 **与公开生态互补** — 社区 Skill 照用，Pocket Skill 补齐属于你自己的经验层。

[English](README.en.md)

---

## 📋 前置依赖

| 依赖 | 说明 |
| --- | --- |
| **Git** | 安装和更新需要 |
| **Bash** | macOS / Linux 自带，Windows 需 WSL 或 Git Bash |
| **Claude Code** / **Codex** | 二选一即可，没有也能通过通用 Agent 方式使用 |

## 🚀 安装

> 💡 建议先预览脚本：`curl -fsSL https://raw.githubusercontent.com/RongchangLi/pocketskill/main/install.sh | less`

**一键安装：**

```bash
curl -fsSL https://raw.githubusercontent.com/RongchangLi/pocketskill/main/install.sh | bash -s -- --yes
```

自动完成：安装到 `~/.pocketskill` → 检测 Claude Code / Codex → 注册 marketplace → 启用 `my-skill` 插件。

**手动安装：**

```bash
git clone https://github.com/RongchangLi/pocketskill.git
cd pocketskill
./install.sh
```

## ⚡ 快速开始

| 操作 | Claude Code | Codex |
| --- | --- | --- |
| ✨ 创建 skill | `/my-skill:create-skill` | `$create-skill` |
| 🔧 使用 skill | `/my-skill:<name>` | `$<name>` |
| 📤 分享 skill | `/my-skill:share-skill` | `$share-skill` |
| 🔄 刷新本地库 | `/my-skill:refresh-my-skill` | `$refresh-my-skill` |
| ⬇️ 拉取远端更新 | `/my-skill:update-my-skill` | `$update-my-skill` |

通用 Agent 也无平台锁定 —— 直接把 `SKILL.md` 作为规则、system prompt 或上下文加载：

```text
# 个人 skill
plugins/my-skill/skills/my-skills/<name>/SKILL.md
plugins/my-skill/skills/private-skills/<name>/SKILL.md

# 内置管理 skill
plugins/my-skill/skills/manage-skills/<name>/SKILL.md
```

## 📂 三类 Skill

| 目录 | 说明 | 可执行操作 |
| --- | --- | --- |
| `private-skills/` | 🔒 私有 Skill，`.gitignore` 自动忽略，不同步到远端 | 创建 · 编辑 · 删除 · 重命名 |
| `my-skills/` | 📝 个人 Skill，Git 版本管理，可选择公开分享 | 创建 · 编辑 · 删除 · 重命名 |
| `manage-skills/` | ⚙️ 内置管理 Skill，随 Pocket Skill 更新 | 只读 |

Claude Code 和 Codex 的插件系统会扫描 `skills/<name>/SKILL.md`。Pocket Skill 保留上面的三类源码目录用于管理，但安装和刷新时会自动导出扁平 marketplace / 插件缓存，所以 `/my-skill:create-skill`、`$create-skill` 这类命令仍然可以直接使用。

> ⚠️ 不要将密钥、token、密码写入任何 skill。

## 🗂️ 目录结构

```text
pocketskill/
├── .agents/plugins/marketplace.json      # Codex marketplace
├── .claude-plugin/marketplace.json       # Claude Code marketplace
├── plugins/my-skill/
│   ├── .codex-plugin/plugin.json
│   ├── .claude-plugin/plugin.json
│   └── skills/
│       ├── private-skills/               # 🔒 私有 Skill（gitignore）
│       ├── my-skills/                    # 📝 个人 Skill（可公开分享）
│       │   └── <your-skill>/
│       ├── manage-skills/                # ⚙️ 内置管理 Skill（只读）
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

## 🔄 更新与刷新

| 命令 | 行为 |
| --- | --- |
| `refresh-my-skill` | 仅刷新本地插件注册并重新生成扁平 marketplace / 插件缓存，不碰远端。创建新 skill 后自动执行。 |
| `update-my-skill` | `git pull --ff-only origin main` + 刷新。拉取最新内置 skill 和社区贡献，并重新生成扁平 marketplace / 插件缓存。 |

**手动更新：**

```bash
cd ~/.pocketskill && git pull --ff-only && ./install.sh --yes
```

> ℹ️ 当前会话不一定热加载变更：Claude Code 建议重启或开新会话；Codex 开新会话即可；通用 Agent 不受影响。

## 📤 分享与贡献

1. `create-skill` → 选择 `my-skills` → 填写 `SKILL.md`
2. `/my-skill:share-skill` 或 `$share-skill` → 自动检查、建分支、提交、创建 PR

命名建议：英文小写 + 连字符，如 `code-review`、`api-design`、`git-workflow`。

## 🔌 兼容性

| 工具 | 使用方式 |
| --- | --- |
| **Claude Code** | `install.sh` 注册 marketplace → `/my-skill:<name>` |
| **Codex** | `install.sh` 注册 marketplace → `$<name>` |
| **Cursor** | 将 `SKILL.md` 作为规则或项目上下文 |
| **ChatGPT Projects** | 将 `SKILL.md` 放入项目知识或指令 |
| **自建 Agent** | 在 system prompt、tool context 或 memory 中加载 |
| **其他通用 Agent** | 直接复制或引用 `SKILL.md` |

> 🧠 核心不是某个平台的插件格式，而是你自己的可迁移技能资产。

## 📄 License

[MIT](LICENSE)
