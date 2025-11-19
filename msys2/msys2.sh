#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<EOF
用法: $0 <command> [options]

可用命令:
  --backup              导出已显式安装的软件包列表
  --restore <file>      从文件恢复安装软件包 (默认: pkglist.txt)
  --disable-repos       注释掉除 [msys] 和 [ucrt64] 外的仓库
  --help                显示此帮助信息

示例:
  $0 --backup
  $0 --restore pkglist.txt
  $0 --disable-repos
EOF
}

check_pacman() {
    if ! command -v pacman >/dev/null 2>&1; then
        echo "❌ pacman 未找到，请确认在 MSYS2 环境中运行。"
        exit 1
    fi
}

cmd_backup() {
    check_pacman
    TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
    FILE="pkglist.txt"
    pacman -Qqe > "$FILE"
    echo "✅ 已导出软件包列表: $FILE"
}

cmd_restore() {
    check_pacman
    FILE=${1:-pkglist.txt}
    if [[ ! -f "$FILE" ]]; then
        echo "❌ 找不到文件: $FILE"
        exit 1
    fi
    echo "📦 更新系统..."
    pacman -Syu --noconfirm
    echo "📦 开始恢复安装 (来源: $FILE)"
    pacman -S --needed - < "$FILE"
    echo "✅ 恢复完成。"
}

cmd_disable_repos() {
    CONF="/etc/pacman.conf"
    # BACKUP="${CONF}.bak.$(date +%Y%m%d-%H%M%S)"
    BACKUP="${CONF}.bak"

    if [[ ! -f "$CONF" ]]; then
        echo "❌ 找不到配置文件: $CONF"
        exit 1
    fi

    cp "$CONF" "$BACKUP"
    echo "✅ 已备份原始配置: $BACKUP"

    sed -i '
    /^\[clangarm64\]/,/^$/ s/^\([^#]\)/#\1/
    /^\[mingw32\]/,/^$/ s/^\([^#]\)/#\1/
    /^\[mingw64\]/,/^$/ s/^\([^#]\)/#\1/
    /^\[clang64\]/,/^$/ s/^\([^#]\)/#\1/
    ' "$CONF"

    echo "✅ 已禁用除 [msys] 和 [ucrt64] 以外的仓库。"
}

# --- main ---
COMMAND=${1:-help}
shift || true

case "$COMMAND" in
    --backup)          cmd_backup "$@" ;;
    --restore)         cmd_restore "$@" ;;
    --disable-repos)   cmd_disable_repos "$@" ;;
    --help)  usage ;;
    *) echo "❌ 未知命令: $COMMAND"; usage; exit 1 ;;
esac

