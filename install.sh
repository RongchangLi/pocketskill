#!/usr/bin/env bash
set -euo pipefail

DEFAULT_REPO_URL="https://github.com/RongchangLi/pocketskill.git"
INSTALL_DIR="${POCKETSKILL_HOME:-$HOME/.pocketskill}"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
CODEX_CONFIG="$HOME/.codex/config.toml"

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
    [ -d "$dir/plugins/my-skill/skills" ] && [ -f "$dir/templates/SKILL.md.template" ]
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

    # Create settings.json if it doesn't exist
    if [ ! -f "$settings" ]; then
        mkdir -p "$(dirname "$settings")"
        echo "{}" > "$settings"
    fi

    # Use python to merge JSON (safe, handles all edge cases)
    python3 - "$REPO_DIR" "$settings" << 'PYEOF'
import json, sys

repo_dir = sys.argv[1]
settings_path = sys.argv[2]

with open(settings_path) as f:
    config = json.load(f)

# Add marketplace
config.setdefault("extraKnownMarketplaces", {})
config["extraKnownMarketplaces"]["pocketskill"] = {
    "source": {
        "source": "directory",
        "path": repo_dir
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
        claude plugin marketplace add "$REPO_DIR" 2>/dev/null || true
        claude plugin install my-skill@pocketskill --scope user 2>/dev/null || true
        claude plugin update my-skill@pocketskill --scope user 2>/dev/null || true
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

    mkdir -p "$(dirname "$config")"

    if [ ! -f "$config" ]; then
        touch "$config"
    fi

    # Add marketplace section if not present
    if ! grep -q '\[marketplaces\.pocketskill\]' "$config"; then
        cat >> "$config" << EOF

[marketplaces.pocketskill]
source_type = "local"
source = "$REPO_DIR"
EOF
        echo "  ✓ 已注册 pocketskill 市场到 $config"
    else
        echo "  - pocketskill 市场已注册，跳过"
    fi

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
        codex plugin marketplace add "$REPO_DIR" 2>/dev/null || true
        codex plugin marketplace upgrade pocketskill 2>/dev/null || true
        echo "  ✓ Codex pocketskill 市场已重新注册"
        echo "  ℹ 如果当前 Codex 会话没有出现新增 skill，请开启新会话"
    fi
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
        echo "  使用  /my-skill:<技能名>       例如 /my-skill:git-workflow"
        echo "  刷新  /my-skill:refresh-my-skill 刷新本地技能库"
        echo "  更新  /my-skill:update-my-skill 从 main 拉取并刷新插件"
        echo "  分享  /my-skill:share-skill     一键提交 PR 到社区"
        echo ""
    fi

    if $has_codex; then
        echo "  ── Codex ──"
        echo "  创建  \$create-skill            交互式创建新技能"
        echo "  使用  \$<技能名>                例如 \$git-workflow"
        echo "  刷新  \$refresh-my-skill        刷新本地技能库"
        echo "  更新  \$update-my-skill         从 main 拉取并刷新插件"
        echo "  分享  \$share-skill             一键提交 PR 到社区"
        echo ""
    fi

    echo "  💡 创建时选「私有」→ 技能名前缀 private-，自动被 .gitignore 忽略。"
    echo "  💡 通用 Agent 可直接读取任意 plugins/my-skill/skills/<name>/SKILL.md。"
    echo "  💡 公开技能欢迎 PR 到 plugins/my-skill/skills/，帮助更多开发者！"
    echo ""
}

main "$@"
