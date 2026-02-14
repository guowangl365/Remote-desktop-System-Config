#!/bin/bash
set -euo pipefail

# ===================== 配置项 =====================
# 日志文件路径
LOG_FILE="/var/log/xrdp_install.log"
# 重试次数
RETRY_COUNT=3
# 重试间隔（秒）
RETRY_INTERVAL=5
# 目标端口
TARGET_PORT=3389
# ===================== 工具函数 =====================

# 日志函数：输出带时间戳的日志到文件和控制台
log() {
    local LEVEL=$1
    local MESSAGE=$2
    local TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$TIMESTAMP] [$LEVEL] $MESSAGE" | tee -a $LOG_FILE
}

# 重试函数：带重试机制执行命令
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

# ===================== 主程序 =====================

# 1. 检查是否为root用户
if [ $EUID -ne 0 ]; then
    log "ERROR" "请使用root权限运行此脚本 (sudo ./脚本名.sh)"
    exit 1
fi

# 2. 初始化日志文件
echo "===== XRDP安装脚本日志 - 开始时间: $(date +"%Y-%m-%d %H:%M:%S") =====" > $LOG_FILE
log "INFO" "XRDP安装脚本启动"

# 3. 检查3389端口状态
log "INFO" "检查$TARGET_PORT端口状态"
if ss -tulpn | grep -q ":$TARGET_PORT"; then
    log "INFO" "$TARGET_PORT端口已被监听，脚本退出"
    exit 0
else
    log "INFO" "$TARGET_PORT端口未监听，开始安装流程"
fi

# 4. 设置非交互模式，避免弹窗
export DEBIAN_FRONTEND=noninteractive
log "INFO" "设置系统为非交互模式，自动处理配置文件冲突"

# 5. 更新系统软件源
retry_run "apt update -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold'" "更新软件源"

# 6. 系统升级
retry_run "apt upgrade -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold'" "系统软件包升级"

# 7. 安装桌面环境和xrdp
retry_run "apt install xfce4 xfce4-goodies xrdp -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold'" "安装xfce4和xrdp"

# 8. 恢复交互模式
unset DEBIAN_FRONTEND
log "INFO" "恢复系统交互模式"

# 9. 配置xrdp服务
log "INFO" "配置xrdp服务自启并启动"
retry_run "systemctl enable xrdp" "设置xrdp开机自启"
retry_run "systemctl start xrdp" "启动xrdp服务"

# 10. 检查xrdp服务状态
if systemctl is-active --quiet xrdp; then
    log "INFO" "xrdp服务运行正常"
else
    log "ERROR" "xrdp服务启动失败"
    exit 1
fi

# 11. 防火墙配置
log "INFO" "检查UFW防火墙状态"
if ufw status | grep -q "active"; then
    retry_run "ufw allow $TARGET_PORT/tcp" "放行$TARGET_PORT端口"
    retry_run "ufw reload" "重载防火墙规则"
    log "INFO" "UFW防火墙已放行$TARGET_PORT端口"
else
    log "INFO" "UFW防火墙未启用，跳过端口放行"
fi

# 12. 最终端口检查
log "INFO" "最终检查$TARGET_PORT端口监听状态"
if ss -tulpn | grep -q ":$TARGET_PORT"; then
    log "SUCCESS" "===== XRDP安装配置完成！====="
    log "SUCCESS" "远程桌面端口: $TARGET_PORT"
    log "SUCCESS" "日志文件路径: $LOG_FILE"
else
    log "ERROR" "===== XRDP安装失败！====="
    log "ERROR" "$TARGET_PORT端口未监听，请查看日志: $LOG_FILE"
    exit 1
fi