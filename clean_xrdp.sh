#!/bin/bash
set -euo pipefail

# 日志函数（复用你的风格）
LOG_FILE="/var/log/xrdp_clean.log"
log() {
    local LEVEL=$1
    local MESSAGE=$2
    local TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    case $LEVEL in
        "INFO") COLOR="\033[36m" ;;
        "SUCCESS") COLOR="\033[32m" ;;
        "WARN") COLOR="\033[33m" ;;
        "ERROR") COLOR="\033[31m" ;;
        *) COLOR="\033[0m" ;;
    esac
    echo -e "${COLOR}[$TIMESTAMP] [$LEVEL]\033[0m $MESSAGE" | tee -a $LOG_FILE
}

# 检查root权限
if [ $EUID -ne 0 ]; then
    log "ERROR" "请用sudo运行此脚本！示例：sudo ./clean_xrdp.sh"
    exit 1
fi

# 初始化日志
echo "===== XRDP清理脚本日志 - $(date) =====" > $LOG_FILE
log "INFO" "开始彻底清理XRDP及残留配置"

# 1. 停止所有xrdp相关服务
log "INFO" "停止xrdp/xrdp-sesman服务..."
sudo systemctl stop xrdp xrdp-sesman &>/dev/null || true
sudo systemctl disable xrdp xrdp-sesman &>/dev/null || true

# 2. 彻底卸载软件包
log "INFO" "卸载xrdp/xfce4相关包..."
sudo apt purge -y xrdp xorgxrdp xfce4 xfce4-goodies &>/dev/null
sudo apt autoremove -y &>/dev/null
sudo apt autoclean -y &>/dev/null

# 3. 删除残留配置/目录/日志
log "INFO" "清理残留配置文件..."
sudo rm -rf /etc/xrdp /var/lib/xrdp /var/run/xrdp /tmp/.X* /tmp/.xrdp* &>/dev/null
sudo rm -rf /home/*/.xsession /home/*/.xsession-errors /home/*/.xfce4/* &>/dev/null
sudo rm -f /var/log/xrdp*.log /var/log/xrdp_install.log &>/dev/null

# 4. 清理端口残留（可选）
sudo fuser -k 3389/tcp &>/dev/null || true

# 5. 重置polkit配置（解决权限残留）
sudo rm -f /etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla &>/dev/null
sudo systemctl restart polkit &>/dev/null

log "SUCCESS" "✅ XRDP已彻底清理完成！"
log "INFO" "接下来执行：sudo ./Remote-desktop.sh 重新安装"
