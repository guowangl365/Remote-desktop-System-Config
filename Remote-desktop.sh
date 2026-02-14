#!/bin/bash
# 脚本功能：配置Ubuntu远程桌面（检测端口+安装xrdp+放行端口）

# 第一步：检查3389端口是否监听
echo "===== 检查3389端口状态 ====="
if ss -tulpn | grep 3389 > /dev/null; then
    echo "3389端口已被监听"
else
    echo "3389端口未监听，开始安装xrdp..."
    
    # 第二步：更新系统并安装桌面环境和xrdp
    # 设置环境变量，避免配置文件冲突时的交互弹窗
    export DEBIAN_FRONTEND=noninteractive
    
    sudo apt update && sudo apt upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
    sudo apt install xfce4 xfce4-goodies xrdp -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
    
    # 恢复环境变量
    unset DEBIAN_FRONTEND
    
    # 第三步：启动xrdp并设置开机自启
    sudo systemctl enable xrdp
    sudo systemctl start xrdp
    
    # 第四步：放行ufw防火墙3389端口（如果开启了ufw）
    if sudo ufw status | grep active > /dev/null; then
        sudo ufw allow 3389/tcp
        sudo ufw reload
        echo "UFW防火墙已放行3389端口"
    fi
    
    # 再次检查端口
    echo "===== 安装完成，再次检查3389端口 ====="
    if ss -tulpn | grep 3389 > /dev/null; then
        echo "xrdp安装成功，3389端口已监听！"
    else
        echo "安装失败，请检查日志！"
    fi
fi