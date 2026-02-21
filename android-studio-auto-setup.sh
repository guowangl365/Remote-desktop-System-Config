#!/bin/bash
set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 配置项（可根据需要修改）
AS_VERSION="2023.2.1.23"  # Android Studio 版本号
AS_DOWNLOAD_URL="https://redirector.gvt1.com/edgedl/android/studio/ide-zips/${AS_VERSION}/android-studio-${AS_VERSION}-linux.tar.gz"
AS_INSTALL_DIR="$HOME/android-studio"
VNC_DISPLAY=":1"
VNC_RESOLUTION="1280x720"
VNC_DEPTH="24"

# 日志函数
log_info() { echo -e "${GREEN}[INFO] ${1}${NC}"; }
log_warn() { echo -e "${YELLOW}[WARN] ${1}${NC}"; }
log_error() { echo -e "${RED}[ERROR] ${1}${NC}"; exit 1; }

# 检查 root 权限（部分操作需要）
check_permission() {
    if [ "$(id -u)" -eq 0 ]; then
        log_warn "不建议使用 root 用户运行，可能导致权限问题，建议使用普通用户 + sudo"
    fi
}

# 安装依赖（Java + 桌面 + VNC）
install_dependencies() {
    log_info "1/7 安装必要依赖..."
    sudo apt update -y
    sudo apt install -y openjdk-11-jdk xfce4 xfce4-goodies tightvncserver wget unzip
}

# 配置 VNC 密码（首次运行时）
config_vnc_password() {
    if [ ! -f "$HOME/.vnc/passwd" ]; then
        log_info "2/7 首次配置 VNC 密码（请设置一个用于远程连接的密码）"
        vncserver $VNC_DISPLAY -geometry $VNC_RESOLUTION -depth $VNC_DEPTH
        vncserver -kill $VNC_DISPLAY
    fi
}

# 启动 VNC 服务
start_vnc() {
    log_info "3/7 启动 VNC 服务..."
    # 先停止已运行的 VNC 实例
    if vncserver -list | grep -q "$VNC_DISPLAY"; then
        log_warn "检测到 VNC $VNC_DISPLAY 已运行，先停止..."
        vncserver -kill $VNC_DISPLAY
    fi
    # 启动 VNC
    vncserver $VNC_DISPLAY -geometry $VNC_RESOLUTION -depth $VNC_DEPTH
    # 设置 DISPLAY 环境变量
    export DISPLAY=$VNC_DISPLAY
    log_info "VNC 服务已启动，显示端口：$VNC_DISPLAY，远程连接地址：服务器IP:590${VNC_DISPLAY#:}"
}

# 检查 Android Studio 是否已安装
check_as_installed() {
    if [ -d "$AS_INSTALL_DIR" ]; then
        # 检测版本（简单校验）
        if [ -f "$AS_INSTALL_DIR/bin/studio.sh" ]; then
            log_info "4/7 检测到已安装 Android Studio，检查版本..."
            local installed_version=$(grep -oP 'version=\K.*' "$AS_INSTALL_DIR/bin/studio.sh" | head -1 || echo "unknown")
            if [[ "$installed_version" == *"$AS_VERSION"* ]]; then
                log_info "当前安装版本 $installed_version 与目标版本 $AS_VERSION 一致，无需更新"
                return 0
            else
                log_warn "当前版本 $installed_version 与目标版本 $AS_VERSION 不一致，将更新..."
                rm -rf "$AS_INSTALL_DIR"
                return 1
            fi
        else
            log_warn "检测到安装目录但文件不完整，将重新安装..."
            rm -rf "$AS_INSTALL_DIR"
            return 1
        fi
    else
        log_info "4/7 未检测到 Android Studio，开始安装..."
        return 1
    fi
}

# 下载并安装 Android Studio
install_as() {
    if check_as_installed; then
        return
    fi
    log_info "5/7 下载 Android Studio $AS_VERSION..."
    wget -O /tmp/android-studio.tar.gz "$AS_DOWNLOAD_URL" --progress=bar:force
    
    log_info "6/7 解压安装..."
    tar -xzf /tmp/android-studio.tar.gz -C "$HOME"
    rm -f /tmp/android-studio.tar.gz
    
    if [ ! -f "$AS_INSTALL_DIR/bin/studio.sh" ]; then
        log_error "Android Studio 安装失败，未找到 studio.sh"
    fi
    log_info "Android Studio 安装完成！"
}

# 启动 Android Studio
start_as() {
    log_info "7/7 启动 Android Studio（请在 VNC 客户端中查看）..."
    export DISPLAY=$VNC_DISPLAY
    cd "$AS_INSTALL_DIR/bin"
    ./studio.sh &
    log_info "====================================="
    log_info "✅ 操作完成！"
    log_info "📌 VNC 连接地址：服务器公网IP:590${VNC_DISPLAY#:}"
    log_info "📌 密码：你设置的 VNC 密码"
    log_info "📌 若无法连接，请检查服务器安全组是否开放 590${VNC_DISPLAY#:} 端口"
    log_info "====================================="
}

# 主执行流程
main() {
    log_info "开始 Android Studio 自动化部署/启动流程..."
    check_permission
    install_dependencies
    config_vnc_password
    start_vnc
    install_as
    start_as
}

# 启动主流程
main
