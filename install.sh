#!/usr/bin/env bash
set -euo pipefail

DEFAULT_REPO_URL="https://github.com/RongchangLi/pocketskill.git"
INSTALL_DIR="${POCKETSKILL_HOME:-$HOME/.pocketskill}"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
CODEX_CONFIG="$HOME/.codex/config.toml"
CODEX_PLUGIN_CACHE="$HOME/.codex/plugins/cache/pocketskill/my-skill"
CLAUDE_MARKETPLACE_EXPORT="$HOME/.claude/plugins/marketplaces/pocketskill"
CODEX_MARKETPLACE_EXPORT="$HOME/.codex/plugins/marketplaces/pocketskill"

DETECTED_TOOLS=()
ASSUME_YES=false
BUMP_PLUGIN_VERSION=false
REPO_URL="$DEFAULT_REPO_URL"
REPO_DIR=""

# ── Arguments ───────────────────────────────────────────────────────────

usage() {
    cat << EOF
Pocket Skill installer

Usage:
  ./install.sh [--yes] [--install-dir PATH] [--repo-url URL]
  curl -fsSL https://raw.githubusercontent.com/RongchangLi/pocketskill/main/install.sh | bash -s -- --yes

Options:
  -y, --yes           Run non-interactively and accept defaults
  --bump-plugin-version
                      Increment the my-skill plugin patch version before refresh
  --install-dir PATH  Install/update Pocket Skill at PATH (default: ~/.pocketskill)
  --repo-url URL      Git repository to clone when running from curl
  -h, --help          Show this help
EOF
}

parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -y|--yes)
                ASSUME_YES=true
                ;;
            --bump-plugin-version)
                BUMP_PLUGIN_VERSION=true
                ;;
            --install-dir)
                INSTALL_DIR="${2:?Missing value for --install-dir}"
                shift
                ;;
            --repo-url)
                REPO_URL="${2:?Missing value for --repo-url}"
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                usage
                exit 1
                ;;
        esac
        shift
    done
}

# ── Repository bootstrap ────────────────────────────────────────────────

has_repo_layout() {
    local dir="$1"
    [ -d "$dir/plugins/my-skill/skills/manage-skills" ] && [ -f "$dir/templates/SKILL.md.template" ]
}

resolve_repo_dir() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"

    if [ -n "$script_dir" ] && has_repo_layout "$script_dir"; then
        REPO_DIR="$script_dir"
        return
    fi

    if has_repo_layout "$(pwd)"; then
        REPO_DIR="$(pwd)"
        return
    fi

    if [ -d "$INSTALL_DIR/.git" ]; then
        echo "  → 更新 Pocket Skill: $INSTALL_DIR"
        git -C "$INSTALL_DIR" pull --ff-only
        REPO_DIR="$INSTALL_DIR"
        return
    fi

    if [ -e "$INSTALL_DIR" ] && ! has_repo_layout "$INSTALL_DIR"; then
        echo "安装目录已存在但不是 Pocket Skill 仓库: $INSTALL_DIR" >&2
        echo "请使用 --install-dir 指定其他目录，或手动处理该目录。" >&2
        exit 1
    fi

    if has_repo_layout "$INSTALL_DIR"; then
        REPO_DIR="$INSTALL_DIR"
        return
    fi

    if ! command -v git &>/dev/null; then
        echo "需要 git 才能一键安装。请先安装 git，或手动下载本仓库。" >&2
        exit 1
    fi

    echo "  → 安装 Pocket Skill 到 $INSTALL_DIR"
    git clone "$REPO_URL" "$INSTALL_DIR"
    REPO_DIR="$INSTALL_DIR"
}

# ── Plugin versioning ───────────────────────────────────────────────────

bump_plugin_version() {
    python3 - "$REPO_DIR/plugins/my-skill/.codex-plugin/plugin.json" "$REPO_DIR/plugins/my-skill/.claude-plugin/plugin.json" << 'PYEOF'
import json
import re
import sys
from pathlib import Path

paths = [Path(arg) for arg in sys.argv[1:]]
versions = []

for path in paths:
    with path.open() as f:
        data = json.load(f)
    version = data.get("version", "0.0.0")
    match = re.fullmatch(r"(\d+)\.(\d+)\.(\d+)", version)
    if not match:
        raise SystemExit(f"Unsupported plugin version in {path}: {version}")
    versions.append(tuple(int(part) for part in match.groups()))

major, minor, patch = max(versions)
next_version = f"{major}.{minor}.{patch + 1}"

for path in paths:
    with path.open() as f:
        data = json.load(f)
    data["version"] = next_version
    with path.open("w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")

print(next_version)
PYEOF
}

plugin_version() {
    python3 - "$REPO_DIR/plugins/my-skill/.codex-plugin/plugin.json" << 'PYEOF'
import json
import sys

with open(sys.argv[1]) as f:
    print(json.load(f)["version"])
PYEOF
}

# ── Plugin export ───────────────────────────────────────────────────────

reset_plugin_dir() {
    local target="$1"

    case "$target" in
        "$HOME/.claude/plugins/cache/pocketskill/my-skill/"*|"$HOME/.codex/plugins/cache/pocketskill/my-skill/"*|"$HOME/.claude/plugins/marketplaces/pocketskill"*|"$HOME/.codex/plugins/marketplaces/pocketskill"*) ;;
        *)
            echo "拒绝刷新非 Pocket Skill 缓存目录: $target" >&2
            exit 1
            ;;
    esac

    rm -rf "$target"
    mkdir -p "$target"
}

copy_skill_group() {
    local group_dir="$1"
    local target_skills="$2"
    local skill_dir skill_name

    [ -d "$group_dir" ] || return 0

    for skill_dir in "$group_dir"/*; do
        [ -d "$skill_dir" ] || continue
        [ -f "$skill_dir/SKILL.md" ] || continue

        skill_name="$(basename "$skill_dir")"

        if [ -e "$target_skills/$skill_name" ]; then
            echo "发现重复 skill 名称: $skill_name" >&2
            echo "请确保 manage-skills、my-skills、private-skills 中没有重名 skill。" >&2
            exit 1
        fi

        cp -R "$skill_dir" "$target_skills/$skill_name"
    done
}

export_flat_my_skill_plugin() {
    local target="$1"
    local source="$REPO_DIR/plugins/my-skill"
    local tmp="$target.tmp.$$"

    reset_plugin_dir "$tmp"

    find "$source" -mindepth 1 -maxdepth 1 \
        ! -name "skills" \
        ! -name ".DS_Store" \
        -exec cp -R {} "$tmp/" \;

    mkdir -p "$tmp/skills"
    copy_skill_group "$source/skills/manage-skills" "$tmp/skills"
    copy_skill_group "$source/skills/my-skills" "$tmp/skills"
    copy_skill_group "$source/skills/private-skills" "$tmp/skills"

    reset_plugin_dir "$target"
    cp -R "$tmp"/. "$target/"
    rm -rf "$tmp"
}

export_claude_marketplace() {
    reset_plugin_dir "$CLAUDE_MARKETPLACE_EXPORT"
    mkdir -p "$CLAUDE_MARKETPLACE_EXPORT/.claude-plugin" "$CLAUDE_MARKETPLACE_EXPORT/plugins"
    cp "$REPO_DIR/.claude-plugin/marketplace.json" "$CLAUDE_MARKETPLACE_EXPORT/.claude-plugin/marketplace.json"
    export_flat_my_skill_plugin "$CLAUDE_MARKETPLACE_EXPORT/plugins/my-skill"
    echo "  ✓ Claude Code 扁平 marketplace 已生成"
}

export_codex_marketplace() {
    reset_plugin_dir "$CODEX_MARKETPLACE_EXPORT"
    mkdir -p "$CODEX_MARKETPLACE_EXPORT/.agents/plugins" "$CODEX_MARKETPLACE_EXPORT/plugins"
    cp "$REPO_DIR/.agents/plugins/marketplace.json" "$CODEX_MARKETPLACE_EXPORT/.agents/plugins/marketplace.json"
    export_flat_my_skill_plugin "$CODEX_MARKETPLACE_EXPORT/plugins/my-skill"
    echo "  ✓ Codex 扁平 marketplace 已生成"
}

# ── Detect installed tools ──────────────────────────────────────────────

detect_tools() {
    if command -v claude &>/dev/null || [ -d "$HOME/.claude" ]; then
        DETECTED_TOOLS+=("claude")
    fi
    if command -v codex &>/dev/null || [ -d "$HOME/.codex" ]; then
        DETECTED_TOOLS+=("codex")
    fi
}

# ── User prompts ────────────────────────────────────────────────────────

ask() {
    local prompt="$1"
    local default="$2"
    local answer

    if [ "$ASSUME_YES" = true ]; then
        return 0
    fi

    if [ "$default" = "y" ]; then
        printf "%s [Y/n] " "$prompt"
    else
        printf "%s [y/N] " "$prompt"
    fi
    read -r answer
    answer="${answer:-$default}"
    [ "$answer" = "y" ] || [ "$answer" = "Y" ]
}

# ── Claude Code setup ────────────────────────────────────────────────────

setup_claude() {
    local settings="$CLAUDE_SETTINGS"

    export_claude_marketplace

    # Create settings.json if it doesn't exist
    if [ ! -f "$settings" ]; then
        mkdir -p "$(dirname "$settings")"
        echo "{}" > "$settings"
    fi

    # Use python to merge JSON (safe, handles all edge cases)
    python3 - "$CLAUDE_MARKETPLACE_EXPORT" "$settings" << 'PYEOF'
import json, sys

marketplace_dir = sys.argv[1]
settings_path = sys.argv[2]

with open(settings_path) as f:
    config = json.load(f)

# Add marketplace
config.setdefault("extraKnownMarketplaces", {})
config["extraKnownMarketplaces"]["pocketskill"] = {
    "source": {
        "source": "directory",
        "path": marketplace_dir
    }
}

# Enable my-skill plugin
config.setdefault("enabledPlugins", {})
config["enabledPlugins"]["my-skill@pocketskill"] = True

with open(settings_path, "w") as f:
    json.dump(config, f, indent=2)
    f.write("\n")
PYEOF
    echo "  ✓ 已更新 $settings"

    # Install the plugin from marketplace
    if command -v claude &>/dev/null; then
        echo "  → 刷新 Claude Code my-skill 插件..."
        claude plugin marketplace add "$CLAUDE_MARKETPLACE_EXPORT" 2>/dev/null || true
        claude plugin marketplace update pocketskill 2>/dev/null || true
        claude plugin install my-skill@pocketskill --scope user 2>/dev/null || true
        claude plugin update my-skill@pocketskill --scope user 2>/dev/null || true
        refresh_claude_cache
        echo "  ✓ Claude Code my-skill 插件已刷新"
        echo "  ℹ Claude Code 可能需要重启或开启新会话后才能看到新增 skill"
    else
        echo "  ⚠ 未检测到 claude CLI，请在 Claude Code 中手动运行："
        echo "    /plugin install my-skill@pocketskill"
    fi
}

# ── Codex setup ─────────────────────────────────────────────────────────

setup_codex() {
    local config="$CODEX_CONFIG"

    export_codex_marketplace

    mkdir -p "$(dirname "$config")"

    if [ ! -f "$config" ]; then
        touch "$config"
    fi

    python3 - "$config" "$CODEX_MARKETPLACE_EXPORT" << 'PYEOF'
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
marketplace_dir = sys.argv[2]
lines = config_path.read_text().splitlines()

header = "[marketplaces.pocketskill]"
start = None
end = None

for index, line in enumerate(lines):
    if line.strip() == header:
        start = index
        break

if start is None:
    if lines and lines[-1].strip():
        lines.append("")
    lines.extend([
        header,
        'source_type = "local"',
        f'source = "{marketplace_dir}"',
    ])
else:
    end = len(lines)
    for index in range(start + 1, len(lines)):
        stripped = lines[index].strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            end = index
            break

    block = lines[start + 1:end]
    saw_source_type = False
    saw_source = False
    new_block = []

    for line in block:
        stripped = line.strip()
        if stripped.startswith("source_type"):
            new_block.append('source_type = "local"')
            saw_source_type = True
        elif stripped.startswith("source"):
            new_block.append(f'source = "{marketplace_dir}"')
            saw_source = True
        else:
            new_block.append(line)

    if not saw_source_type:
        new_block.append('source_type = "local"')
    if not saw_source:
        new_block.append(f'source = "{marketplace_dir}"')

    lines = lines[:start + 1] + new_block + lines[end:]

config_path.write_text("\n".join(lines) + "\n")
PYEOF
    echo "  ✓ 已注册 pocketskill 扁平市场到 $config"

    # Enable the plugin
    if ! grep -q '\[plugins."my-skill@pocketskill"\]' "$config"; then
        cat >> "$config" << EOF

[plugins."my-skill@pocketskill"]
enabled = true
EOF
        echo "  ✓ 已启用 my-skill 插件"
    else
        echo "  - my-skill 插件已启用，跳过"
    fi

    if command -v codex &>/dev/null; then
        echo "  → 重新注册 Codex pocketskill 市场..."
        codex plugin marketplace add "$CODEX_MARKETPLACE_EXPORT" 2>/dev/null || true
        codex plugin marketplace upgrade pocketskill 2>/dev/null || true
        echo "  ✓ Codex pocketskill 市场已重新注册"
        refresh_codex_cache
        echo "  ℹ 如果当前 Codex 会话没有出现新增 skill，请开启新会话"
    fi
}

refresh_codex_cache() {
    local version target
    version="$(plugin_version)"
    target="$CODEX_PLUGIN_CACHE/$version"

    export_flat_my_skill_plugin "$target"
    echo "  ✓ Codex my-skill 扁平缓存已写入: $version"
}

refresh_claude_cache() {
    local version target
    version="$(plugin_version)"
    target="$HOME/.claude/plugins/cache/pocketskill/my-skill/$version"

    export_flat_my_skill_plugin "$target"
    echo "  ✓ Claude Code my-skill 扁平缓存已写入: $version"
}

# ── Main ─────────────────────────────────────────────────────────────────

main() {
    parse_args "$@"
    resolve_repo_dir

    if [ "$BUMP_PLUGIN_VERSION" = true ]; then
        local next_version
        next_version="$(bump_plugin_version)"
        echo "  ✓ my-skill 插件版本已更新到 $next_version"
    fi

    detect_tools

    if [ ${#DETECTED_TOOLS[@]} -eq 0 ]; then
        echo "未检测到 Claude Code 或 Codex。"
        echo ""
        echo "pocketskill 技能文件为纯 Markdown + YAML，你可以手动将技能复制到任意 Agent 工具中使用。"
        exit 0
    fi

    echo ""
    echo "  🛠  检测到: ${DETECTED_TOOLS[*]}"
    echo "  📦 Pocket Skill: $REPO_DIR"
    echo ""

    if ! ask "注册 pocketskill 技能市场？" "y"; then
        echo "已取消。"
        exit 0
    fi

    echo ""
    for tool in "${DETECTED_TOOLS[@]}"; do
        case "$tool" in
            claude) setup_claude ;;
            codex) setup_codex ;;
        esac
    done

    echo ""
    echo "  ✓ 安装完成！"
    echo ""

    # Show tool-specific usage
    local has_claude=false has_codex=false
    for tool in "${DETECTED_TOOLS[@]}"; do
        case "$tool" in
            claude) has_claude=true ;;
            codex) has_codex=true ;;
        esac
    done

    if $has_claude; then
        echo "  ── Claude Code ──"
        echo "  创建  /my-skill:create-skill    交互式创建新技能"
        echo "  修改  /my-skill:edit-skill      安全修改已有技能"
        echo "  改名  /my-skill:rename-skill    安全重命名技能"
        echo "  删除  /my-skill:delete-skill    删除或归档技能"
        echo "  使用  /my-skill:<技能名>       例如 /my-skill:git-workflow"
        echo "  刷新  /my-skill:refresh-my-skill 刷新本地技能库"
        echo "  更新  /my-skill:update-my-skill 从 main 拉取并刷新插件"
        echo "  分享  /my-skill:share-skill     一键提交 PR 到社区"
        echo ""
    fi

    if $has_codex; then
        echo "  ── Codex ──"
        echo "  创建  \$create-skill            交互式创建新技能"
        echo "  修改  \$edit-skill              安全修改已有技能"
        echo "  改名  \$rename-skill            安全重命名技能"
        echo "  删除  \$delete-skill            删除或归档技能"
        echo "  使用  \$<技能名>                例如 \$git-workflow"
        echo "  刷新  \$refresh-my-skill        刷新本地技能库"
        echo "  更新  \$update-my-skill         从 main 拉取并刷新插件"
        echo "  分享  \$share-skill             一键提交 PR 到社区"
        echo ""
    fi

    echo "  💡 创建时选「私有」→ 存入 private-skills/，自动被 .gitignore 忽略。"
    echo "  💡 用户公开技能：plugins/my-skill/skills/my-skills/<name>/SKILL.md"
    echo "  💡 私有技能：plugins/my-skill/skills/private-skills/<name>/SKILL.md"
    echo "  💡 公开技能欢迎 PR 到 plugins/my-skill/skills/my-skills/，帮助更多开发者！"
    echo ""
}

main "$@"
