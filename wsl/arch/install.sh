#!/usr/bin/env bash
set -euo pipefail

# 参数处理
MODE=${1:-}
SCRIPT_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

# 用户管理配置
user_management() {
    echo "=== 执行用户管理配置 ==="

    # 1. 获取用户名和密码参数
    local username=${2:-}
    local password=${3:-}

    if [[ -z "$username" ]]; then
        read -p "请输入用户名: " username
    fi

    if [[ -z "$password" ]]; then
        read -sp "请输入密码: " password
        echo
    fi

    # 2. 检查用户是否存在
    if id -u "$username" >/dev/null 2>&1; then
        echo "用户 $username 已存在，跳过创建"
        return 0
    fi

    # 3. 创建用户
    echo "创建用户 $username..."
    useradd -m -G wheel -s /bin/bash "$username"
    echo "$username:$password" | chpasswd

    # 4. 配置 sudo 权限
    echo "配置 sudo 权限..."
    echo "$username ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/wsl_$username
    chmod 440 /etc/sudoers.d/wsl_$username

    # 5. 复制配置文件到新用户目录
    local user_home=$(eval echo "~$username")
    echo "为用户 $username 配置环境..."
    mkdir -p "$user_home/.config"
    chown -R "$username:$username" "$user_home"

    # 6. 以新用户身份执行用户配置
    echo "执行用户级配置..."
    su - "$username" -c "bash '$SCRIPT_DIR/$(basename ${BASH_SOURCE[0]})' --user"

    echo "用户 $username 配置完成 ✅"
}

# 系统级配置 (root)
root_config() {
    echo "=== 执行系统级配置 ==="

    # 1. 设置 archlinuxcn 源
    if ! grep -q '^\[archlinuxcn\]' /etc/pacman.conf; then
        echo "添加 archlinuxcn 源..."
        echo -e "\n[archlinuxcn]\nServer = https://mirrors.ustc.edu.cn/archlinuxcn/\$arch" >> /etc/pacman.conf
    fi

    # 2. 初始化 keyring
    pacman-key --init
    pacman-key --populate archlinux
    pacman -Sy --noconfirm archlinux-keyring
    pacman-key --lsign-key "farseerfc@archlinux.org"
    pacman -S --needed --noconfirm archlinuxcn-keyring

    # 3. 安装基础软件包
    if [[ -f "$SCRIPT_DIR/packages.txt" ]]; then
        echo "安装系统软件包..."
        # pacman -S --needed --noconfirm --disable-download-timeout - < "$SCRIPT_DIR/packages.txt"
        # 使用 xargs 分批处理
        cat "$SCRIPT_DIR/packages.txt" | xargs -n 1 -I {} sh -c 'sudo pacman -S --needed --noconfirm "{}" || echo "Failed: {}"'
    fi

    # 4. 配置 zsh (系统级)
    if command -v zsh &> /dev/null; then
        local zsh_path=$(command -v zsh)
        if ! grep -q "^$zsh_path$" /etc/shells; then
            echo "$zsh_path" >> /etc/shells
        fi
    fi

    echo "系统级配置完成 ✅"
}

# 用户级配置
user_config() {
    echo "=== 执行用户级配置 ==="

    # 1. 链接配置文件
    ln -sf "$SCRIPT_DIR/zshrc" "$HOME/.zshrc"
    ln -sf "$SCRIPT_DIR/shell_title.zsh" "$HOME/shell_title.zsh"
    ln -sf "$SCRIPT_DIR/p10k.zsh" "$HOME/.p10k.zsh"
    cp -f "$SCRIPT_DIR/../clang-format" "$HOME/.clang-format"

    # 2. 配置 Git
    if command -v git &> /dev/null; then
        git config --global user.name "$(whoami)"
        git config --global user.email "$(whoami)@localhost"
    fi

    # 3. 运行其他安装脚本
    local vim_install="$SCRIPT_DIR/../../vim/install.sh"
    local git_install="$SCRIPT_DIR/../../git/install.sh"

    [[ -f "$vim_install" ]] && bash "$vim_install"
    [[ -f "$git_install" ]] && bash "$git_install"

    # 4. 切换默认 shell 到 zsh
    if command -v zsh &> /dev/null; then
        sudo usermod -s $(command -v zsh) $USER
    fi
}

# 主逻辑
case "$MODE" in
    --root)
        root_config
        ;;
    --user)
        user_config
        ;;
    --add-user)
        user_management "$@"
        ;;
    *)
        echo "Usage: $0 [--root|--user|--add-user [username] [password]]"
        exit 1
        ;;
esac
