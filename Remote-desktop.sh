#!/bin/bash
set -euo pipefail

# ===================== 核心配置 =====================
LOG_FILE="/var/log/xrdp_install.log"
TARGET_PORT=3389
# 默认配置（空输入时使用）
DEFAULT_USER="rdp_user"
DEFAULT_PASS="Rdp@123456"  # 建议登录后修改
# ===================== 工具函数 =====================
# 带颜色的日志函数
log() {
    local LEVEL=$1
    local MESSAGE=$2
    local TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    # 不同级别不同颜色
    case $LEVEL in
        "INFO") COLOR="\033[36m" ;;  # 青色
        "SUCCESS") COLOR="\033[32m" ;; # 绿色
        "WARN") COLOR="\033[33m" ;;  # 黄色
        "ERROR") COLOR="\033[31m" ;; # 红色
        *) COLOR="\033[0m" ;;        # 默认
    esac
    echo -e "${COLOR}[$TIMESTAMP] [$LEVEL]\033[0m $MESSAGE" | tee -a $LOG_FILE
}

# 交互式输入函数（空输入用默认值）
input_prompt() {
    local PROMPT_MSG=$1
    local INPUT_VAR=$2
    local DEFAULT_VAL=$3
    
    # 强制从终端读取输入（适配SSH）
    read -p "$PROMPT_MSG（直接回车使用默认：$DEFAULT_VAL）：" "$INPUT_VAR" < /dev/tty
    
    # 空输入则使用默认值
    if [ -z "${!INPUT_VAR}" ]; then
        eval "$INPUT_VAR='$DEFAULT_VAL'"
        log "WARN" "未输入内容，使用默认值：$DEFAULT_VAL"
    fi
}

# 创建用户核心函数（支持默认值）
create_normal_user() {
    log "INFO" "====================================="
    log "INFO" "开始创建远程桌面专用普通用户"
    log "INFO" "====================================="
    
    # 1. 输入用户名（空输入用默认）
    input_prompt "👉 请输入要创建的用户名" "USER_NAME" "$DEFAULT_USER"
    
    # 检查用户是否已存在
    if id "$USER_NAME" &>/dev/null; then
        log "WARN" "用户 $USER_NAME 已存在，跳过创建，直接配置桌面"
        configure_user_session "$USER_NAME"
        return 0
    fi

    # 2. 输入密码（空输入用默认，隐藏输入）
    log "INFO" "👉 请为用户 $USER_NAME 设置密码（输入无回显）"
    read -s PASSWD1 < /dev/tty
    echo ""
    
    # 空密码则使用默认值
    if [ -z "$PASSWD1" ]; then
        PASSWD1=$DEFAULT_PASS
        log "WARN" "未输入密码，使用默认密码：$DEFAULT_PASS（请尽快修改）"
        PASSWD2=$DEFAULT_PASS
    else
        # 二次确认密码
        log "INFO" "👉 请再次输入密码确认（输入无回显）"
        read -s PASSWD2 < /dev/tty
        echo ""
        
        # 校验两次密码一致
        if [ "$PASSWD1" != "$PASSWD2" ]; then
            log "ERROR" "两次密码输入不一致！"
            exit 1
        fi
    fi

    # 3. 创建用户
    log "INFO" "正在创建用户 $USER_NAME..."
    sudo useradd -m -s /bin/bash "$USER_NAME"
    echo "$USER_NAME:$PASSWD1" | sudo chpasswd
    
    # 4. 询问是否加入sudo组（空输入默认n）
    input_prompt "👉 是否将 $USER_NAME 加入管理员组" "ADD_SUDO" "n"
    if [ "$ADD_SUDO" = "y" ] || [ "$ADD_SUDO" = "Y" ]; then
        sudo usermod -aG sudo "$USER_NAME"
        log "INFO" "用户 $USER_NAME 已添加到sudo组"
    fi

    # 5. 配置桌面会话
    configure_user_session "$USER_NAME"

    # 输出登录信息
    log "SUCCESS" "====================================="
    log "SUCCESS" "用户创建完成！登录信息："
    log "SUCCESS" "✅ 用户名：$USER_NAME"
    log "SUCCESS" "✅ 密码：$( [ "$PASSWD1" = "$DEFAULT_PASS" ] && echo "$DEFAULT_PASS（默认）" || echo "你设置的密码" )"
    log "SUCCESS" "====================================="
}

# 配置用户桌面会话
configure_user_session() {
    local USER=$1
    log "INFO" "为用户 $USER 配置xfce4桌面会话..."
    sudo -u "$USER" bash -c 'echo "xfce4-session" > ~/.xsession'
    sudo chown "$USER:$USER" "/home/$USER/.xsession"
}

# ===================== 主程序 =====================
# 检查root权限
if [ $EUID -ne 0 ]; then
    log "ERROR" "请用sudo运行此脚本！示例：sudo ./install_xrdp.sh"
    exit 1
fi

# 初始化日志
echo "===== XRDP安装脚本日志 - $(date) =====" > $LOG_FILE
log "INFO" "XRDP远程桌面安装脚本启动（SSH专用版）"

# 快速检查端口（已安装则直接创建用户）
if ss -tulpn | grep -q ":$TARGET_PORT"; then
    log "INFO" "3389端口已监听，跳过安装，直接创建用户"
    create_normal_user
    exit 0
fi

# 快速安装依赖（无交互，加快速度）
log "INFO" "开始安装xrdp和桌面环境（约1-2分钟）..."
export DEBIAN_FRONTEND=noninteractive
sudo apt update -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold'
sudo apt install -y xfce4 xfce4-goodies xrdp -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold'
unset DEBIAN_FRONTEND

# 启动xrdp服务
log "INFO" "启动xrdp服务..."
sudo systemctl enable --now xrdp
sudo systemctl restart xrdp

# 放行防火墙（如果开启）
if sudo ufw status | grep -q "active"; then
    sudo ufw allow 3389/tcp >/dev/null
    sudo ufw reload >/dev/null
    log "INFO" "UFW防火墙已放行3389端口"
fi

# 核心环节：交互式创建用户
create_normal_user

# 最终提示
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
log "SUCCESS" "====================================="
log "SUCCESS" "🎉 XRDP配置全部完成！"
log "SUCCESS" "📌 远程桌面连接信息："
log "SUCCESS" "   IP地址：$SERVER_IP"
log "SUCCESS" "   端口：3389"
log "SUCCESS" "   用户名：$USER_NAME"
log "SUCCESS" "🔑 密码：$( [ "$PASSWD1" = "$DEFAULT_PASS" ] && echo "$DEFAULT_PASS（默认，建议修改）" || echo "你设置的密码" )"
log "SUCCESS" "====================================="
log "INFO" "修改密码命令：sudo passwd $USER_NAME"
log "INFO" "现在可以用Windows远程桌面直接连接了！"
