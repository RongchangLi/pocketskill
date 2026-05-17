# Pocket Skill

把你自己创建的 Agent Skill 管起来，并且迁移到任意 Agent。

Pocket Skill 是一个纯 Markdown + YAML 的个人技能库。你可以在 Claude Code、Codex 里一键使用，也可以把同一份 `SKILL.md` 交给任何支持提示词/规则/上下文文件的通用 Agent。

## 一键安装

适合第一次使用：

```bash
curl -fsSL https://raw.githubusercontent.com/RongchangLi/pocketskill/main/install.sh | bash -s -- --yes
```

这条命令会：

1. 把 Pocket Skill 安装到 `~/.pocketskill`
2. 自动检测 Claude Code / Codex
3. 注册本地 skill marketplace
4. 启用 `my-skill` 插件

手动安装也可以：

```bash
git clone https://github.com/RongchangLi/pocketskill.git
cd pocketskill
./install.sh
```

## 你能用它做什么

- **创建自己的 skill**：把一次经验沉淀成可复用的 Agent 指令。
- **管理公开和私有 skill**：公开 skill 可分享，私有 skill 留在本地。
- **跨 Agent 迁移**：同一份 `SKILL.md` 可用于 Claude Code、Codex、Cursor、ChatGPT Projects、自建 Agent 或任何通用 Agent。
- **持续积累**：你的工作方式、偏好、流程和判断标准都能沉淀成一个可版本化的技能库。

## 第一次使用

### Claude Code

创建 skill：

```text
/my-skill:create-skill
```

使用 skill：

```text
/my-skill:git-workflow
```

分享公开 skill：

```text
/my-skill:share-skill
```

刷新本地技能库：

```text
/my-skill:refresh-my-skill
```

更新 Pocket Skill：

```text
/my-skill:update-my-skill
```

### Codex

创建 skill：

```text
$create-skill
```

使用 skill：

```text
$git-workflow
```

分享公开 skill：

```text
$share-skill
```

刷新本地技能库：

```text
$refresh-my-skill
```

更新 Pocket Skill：

```text
$update-my-skill
```

### 通用 Agent

Pocket Skill 没有平台锁定。任意 Agent 都可以直接读取 skill 文件：

```text
请读取并遵循这个文件里的说明：
plugins/my-skill/skills/git-workflow/SKILL.md
```

如果你的 Agent 支持规则文件、项目知识库、system prompt、memory 或 context attachment，把 `SKILL.md` 放进去即可。

## Skill 是什么

一个 skill 就是一个目录，里面至少有一个 `SKILL.md`：

```text
plugins/my-skill/skills/git-workflow/
└── SKILL.md
```

`SKILL.md` 顶部是 YAML 元数据，下面是给 Agent 的工作说明：

```markdown
---
name: git-workflow
description: Use when working with my preferred Git branch, commit, and PR flow.
---

# Git Workflow

Follow these instructions when handling Git work for me...
```

因为它只是文本文件，所以可以复制、提交、同步、迁移，也可以被任何 Agent 读取。

## 公开和私有

创建 skill 时会选择 Public 或 Private：

| 类型 | 路径 | 用途 |
| --- | --- | --- |
| Public | `plugins/my-skill/skills/git-workflow/` | 可提交到 GitHub、分享给社区 |
| Private | `plugins/my-skill/skills/private-my-workflow/` | 本地使用，默认被 `.gitignore` 忽略 |

私有 skill 适合存放个人偏好、公司流程、私有路径、内部系统说明。不要把密钥、token、密码写进任何 skill。

## 内置 Skill

| Skill | 用途 | Claude Code | Codex |
| --- | --- | --- | --- |
| `create-skill` | 创建新的公开或私有 skill | `/my-skill:create-skill` | `$create-skill` |
| `edit-skill` | 安全修改已有 skill，并刷新本地库 | `/my-skill:edit-skill` | `$edit-skill` |
| `rename-skill` | 安全重命名 skill 目录和元数据 | `/my-skill:rename-skill` | `$rename-skill` |
| `delete-skill` | 删除或归档已有 skill，并刷新本地库 | `/my-skill:delete-skill` | `$delete-skill` |
| `share-skill` | 把公开 skill 通过 GitHub PR 分享出去 | `/my-skill:share-skill` | `$share-skill` |
| `refresh-my-skill` | 刷新本地 `my-skill` 插件注册，不拉取远程 | `/my-skill:refresh-my-skill` | `$refresh-my-skill` |
| `update-my-skill` | 从 `origin/main` 更新 Pocket Skill，并刷新插件注册 | `/my-skill:update-my-skill` | `$update-my-skill` |
| `claude-save-token` | 让 Claude Code 更省 token 地工作（状态：暂不满意，开发中） | `/my-skill:claude-save-token` | `$claude-save-token` |
| `codex-save-token` | 让 Codex 更省 token 地工作（状态：暂不满意，开发中） | `/my-skill:codex-save-token` | `$codex-save-token` |

## 目录结构

```text
pocketskill/
├── .agents/plugins/marketplace.json      # Codex marketplace
├── .claude-plugin/marketplace.json       # Claude Code marketplace
├── plugins/
│   └── my-skill/
│       ├── .codex-plugin/plugin.json
│       ├── .claude-plugin/plugin.json
│       └── skills/
│           ├── create-skill/
│           ├── edit-skill/
│           ├── rename-skill/
│           ├── delete-skill/
│           ├── share-skill/
│           ├── refresh-my-skill/
│           ├── update-my-skill/
│           └── private-*/                # 私有 skill，默认忽略
├── templates/
│   └── SKILL.md.template
└── install.sh
```

## 更新

如果你使用一键安装，后续可以这样更新：

Claude Code：

```text
/my-skill:update-my-skill
```

Codex：

```text
$update-my-skill
```

也可以手动更新：

```bash
cd ~/.pocketskill
git pull --ff-only
./install.sh --yes
```

如果你是手动 clone 的仓库，在仓库目录里执行同样的命令即可。

## 刷新和重启

`create-skill` 创建新 skill 后会自动运行 `refresh-my-skill` 的同等流程：`./install.sh --yes --bump-plugin-version`，提升 `my-skill` 插件 patch 版本，并刷新 Claude Code / Codex 的 marketplace 和插件注册。

你也可以手动刷新：

```text
/my-skill:refresh-my-skill
$refresh-my-skill
```

`refresh-my-skill` 只刷新本地插件库，不会拉取远程代码。`update-my-skill` 才会先从 `origin/main` 拉取，再刷新。

这通常不需要重新安装 Pocket Skill，但当前已经打开的对话不一定会热加载新增 skill：

- Claude Code 的插件更新机制可能需要重启或开启新会话后生效。
- Codex 如果当前会话没有显示新增 skill，开启新会话即可重新读取插件列表。
- 通用 Agent 不受影响，直接读取新建的 `SKILL.md` 就能使用。

## 分享你的 Skill

公开 skill 可以提交 PR：

1. 用 `create-skill` 创建 Public skill
2. 填写 `SKILL.md`
3. 用 `share-skill` 检查、建分支、提交并创建 PR

命名建议：英文小写、数字、连字符，例如 `code-review`、`api-design`、`git-workflow`。

## 兼容性

| Agent / 工具 | 推荐方式 |
| --- | --- |
| Claude Code | 通过 `install.sh` 注册 marketplace，使用 `/my-skill:<skill-name>` |
| Codex | 通过 `install.sh` 注册 marketplace，使用 `$<skill-name>` |
| Cursor | 把 `SKILL.md` 作为规则或项目上下文 |
| ChatGPT Projects | 把 `SKILL.md` 放入项目知识或指令 |
| 自建 Agent | 在 system prompt、tool context 或 memory 中加载 `SKILL.md` |
| 其他通用 Agent | 直接复制或引用 `SKILL.md` |

Pocket Skill 的核心不是某个平台的插件格式，而是你自己的可迁移技能资产。
