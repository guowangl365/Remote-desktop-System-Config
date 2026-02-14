#!/bin/bash
set -euo pipefail

# ===================== 配置项 =====================
LOG_FILE="/var/log/xrdp_install.log"
RETRY_COUNT=3
RETRY_INTERVAL=5
TARGET_PORT=3389
# ===================== 工具函数 =====================
log() {
    local LEVEL=$1
    local MESSAGE=$2
    local TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$TIMESTAMP] [$LEVEL] $MESSAGE" | tee -a $LOG_FILE
}

retry_run() {
    local CMD=$1
    local DESC=$2
    local COUNT=0
    
    log "INFO" "开始执行: $DESC"
    while [ $COUNT -lt $RETRY_COUNT ]; do
        if eval $CMD; then
            log "INFO" "成功执行: $DESC"
            return 0
        else
            COUNT=$((COUNT + 1))
            log "WARN" "执行失败: $DESC (第 $COUNT 次重试)"
            sleep $RETRY_INTERVAL
        fi
    done
    
    log "ERROR" "执行失败: $DESC (已重试 $RETRY_COUNT 次)"
    exit 1
}

# 交互式创建普通用户函数
create_normal_user() {
    log "INFO" "===== 开始创建远程桌面普通用户 ====="
    # 提示输入用户名
    read -p "请输入要创建的普通用户名（例如：ubuntu_user）：" USER_NAME
    # 校验用户名是否为空
    if [ -z "$USER_NAME" ]; then
        log "ERROR" "用户名不能为空！"
        exit 1
    fi
    # 检查用户是否已存在
    if id "$USER_NAME" &>/dev/null; then
        log "WARN" "用户 $USER_NAME 已存在，跳过创建步骤"
        return 0
    fi
    # 交互式创建用户（会提示输入密码）
    log "INFO" "请为用户 $USER_NAME 设置密码（输入时无回显，按提示操作）"
    sudo adduser "$USER_NAME"
    # 将用户添加到sudo组（可选，赋予管理员权限）
    read -p "是否将用户 $USER_NAME 添加到sudo组（拥有管理员权限）？(y/n)：" ADD_SUDO
    if [ "$ADD_SUDO" = "y" ] || [ "$ADD_SUDO" = "Y" ]; then
        sudo usermod -aG sudo "$USER_NAME"
        log "INFO" "用户 $USER_NAME 已添加到sudo组"
    fi
    # 为用户配置xrdp桌面会话
    log "INFO" "为用户 $USER_NAME 配置xfce4桌面会话"
    sudo -u "$USER_NAME" bash -c 'echo "xfce4-session" > ~/.xsession'
    log "INFO" "用户 $USER_NAME 创建并配置完成！"
    log "SUCCESS" "远程桌面登录信息："
    log "SUCCESS" "用户名：$USER_NAME"
    log "SUCCESS" "密码：你刚才设置的密码"
}

# ===================== 主程序 =====================
# 检查root权限
if [ $EUID -ne 0 ]; then
    log "ERROR" "请使用root权限运行此脚本 (sudo ./脚本名.sh)"
    exit 1
fi

# 初始化日志
echo "===== XRDP安装脚本日志 - 开始时间: $(date +"%Y-%m-%d %H:%M:%S") =====" > $LOG_FILE
log "INFO" "XRDP安装脚本启动"

# 检查3389端口
log "INFO" "检查$TARGET_PORT端口状态"
if ss -tulpn | grep -q ":$TARGET_PORT"; then
    log "INFO" "$TARGET_PORT端口已被监听，跳过安装步骤"
    # 端口已监听时，仍提示创建用户
    create_normal_user
    exit 0
else
    log "INFO" "$TARGET_PORT端口未监听，开始安装流程"
fi

# 非交互模式安装依赖
export DEBIAN_FRONTEND=noninteractive
log "INFO" "设置系统为非交互模式，自动处理配置文件冲突"

# 更新源+安装软件
retry_run "apt update -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold'" "更新软件源"
retry_run "apt upgrade -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold'" "系统软件包升级"
retry_run "apt install xfce4 xfce4-goodies xrdp -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold'" "安装xfce4和xrdp"

# 恢复交互模式
unset DEBIAN_FRONTEND
log "INFO" "恢复系统交互模式"

# 启动并配置xrdp服务
log "INFO" "配置xrdp服务自启并启动"
retry_run "systemctl enable xrdp" "设置xrdp开机自启"
retry_run "systemctl restart xrdp" "重启xrdp服务（加载新配置）"

# 检查xrdp状态
if systemctl is-active --quiet xrdp; then
    log "INFO" "xrdp服务运行正常"
else
    log "ERROR" "xrdp服务启动失败"
    exit 1
fi

# 防火墙配置
log "INFO" "检查UFW防火墙状态"
if ufw status | grep -q "active"; then
    retry_run "ufw allow $TARGET_PORT/tcp" "放行$TARGET_PORT端口"
    retry_run "ufw reload" "重载防火墙规则"
    log "INFO" "UFW防火墙已放行$TARGET_PORT端口"
else
    log "INFO" "UFW防火墙未启用，跳过端口放行"
fi

# 创建远程桌面普通用户（核心交互环节）
create_normal_user

# 最终检查端口
log "INFO" "最终检查$TARGET_PORT端口监听状态"
if ss -tulpn | grep -q ":$TARGET_PORT"; then
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    log "SUCCESS" "===== XRDP安装配置全完成！====="
    log "SUCCESS" "远程桌面连接信息："
    log "SUCCESS" "服务器IP：$SERVER_IP"
    log "SUCCESS" "端口：$TARGET_PORT"
    log "SUCCESS" "用户名：$USER_NAME（你刚才创建的）"
    log "SUCCESS" "密码：你刚才设置的密码"
    log "SUCCESS" "直接用Windows远程桌面连接即可！"
    log "SUCCESS" "日志文件路径: $LOG_FILE"
else
    log "ERROR" "===== XRDP安装失败！====="
    log "ERROR" "$TARGET_PORT端口未监听，请查看日志: $LOG_FILE"
    exit 1
fi
