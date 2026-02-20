#!/bin/bash
set -e  # 遇到错误立即退出

# 定义颜色输出（增强可读性）
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # 重置颜色

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO] ${1}${NC}"
}

log_warn() {
    echo -e "${YELLOW}[WARN] ${1}${NC}"
}

log_error() {
    echo -e "${RED}[ERROR] ${1}${NC}"
    exit 1
}

# 检查是否为 root 权限
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log_error "请使用 root 权限运行此脚本（添加 sudo）"
    fi
}

# 系统更新与依赖安装
system_update() {
    log_info "1/6 开始更新系统源并安装基础依赖..."
    apt update -y && apt upgrade -y
    # 安装必要工具
    apt install -y wget curl apt-transport-https ca-certificates
}

# 安装 Wine 环境（核心：支持 Windows EXE）
install_wine() {
    log_info "2/6 开始安装 Wine 环境（支持 Windows EXE）..."
    # 添加 32 位支持
    dpkg --add-architecture i386 || log_warn "32位架构已添加，跳过"
    apt update -y
    # 安装 Wine 核心组件
    apt install -y wine64 wine32 winetricks
    # 验证 Wine 安装
    if wine --version >/dev/null 2>&1; then
        log_info "Wine 安装成功，版本：$(wine --version)"
    else
        log_error "Wine 安装失败，请检查系统环境"
    fi
}

# 安装轻量级桌面环境（XFCE4）
install_desktop() {
    log_info "3/6 开始安装轻量级桌面环境 XFCE4..."
    # 安装 XFCE4 最小化组件（适配云服务器，减少资源占用）
    apt install -y xfce4 xfce4-goodies xfce4-terminal
}

# 配置 XRDP 远程桌面
config_xrdp() {
    log_info "4/6 开始配置 XRDP 远程桌面..."
    # 安装 XRDP
    apt install -y xrdp
    # 配置 XFCE4 为默认桌面
    echo "xfce4-session" > /etc/skel/.xsession
    echo "xfce4-session" > ~/.xsession
    # 重启 XRDP 服务
    systemctl restart xrdp
    systemctl enable xrdp  # 设置开机自启
    # 验证 XRDP 状态
    if systemctl is-active --quiet xrdp; then
        log_info "XRDP 服务已启动并设置开机自启"
    else
        log_error "XRDP 服务启动失败"
    fi
}

# 配置防火墙
config_firewall() {
    log_info "5/6 开始配置防火墙（开放 3389 远程桌面端口）..."
    # 检查 ufw 是否安装
    if ! command -v ufw &> /dev/null; then
        apt install -y ufw
    fi
    # 开放 3389 端口
    ufw allow 3389/tcp || log_warn "3389 端口已开放，跳过"
    # 启用防火墙（如果未启用）
    if ! ufw status | grep -q "active"; then
        ufw enable -y
    fi
    log_info "防火墙配置完成，3389 端口已开放"
}

# 输出使用指南
print_guide() {
    log_info "6/6 配置全部完成！🎉"
    echo -e "\n${YELLOW}===== 使用指南 =====${NC}"
    echo "1. 远程桌面连接："
    echo "   - 本地打开「远程桌面连接」（mstsc）"
    echo "   - 输入云服务器公网 IP"
    echo "   - 登录账号：你的 Ubuntu 普通用户（非 root）"
    echo "   - 登录密码：你的 Ubuntu 用户密码"
    echo "2. 运行 Windows EXE 游戏："
    echo "   - 把游戏 EXE 文件传到服务器"
    echo "   - 右键 EXE 文件 → Open With Wine Windows Program Loader"
    echo "   - 或命令行运行：wine /路径/到/游戏.exe"
    echo "3. 后台挂机运行："
    echo "   - nohup wine /路径/到/游戏.exe > /dev/null 2>&1 &"
    echo -e "\n${RED}注意：${NC}云服务器安全组需手动开放 3389 端口！"
}

# 主执行流程
main() {
    log_info "开始执行 Ubuntu 游戏挂机环境配置脚本..."
    check_root
    system_update
    install_wine
    install_desktop
    config_xrdp
    config_firewall
    print_guide
}

# 启动主流程
main
