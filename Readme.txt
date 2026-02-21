你想要让云端 Ubuntu 服务器自动运行 GitHub 上的 shell 脚本（包含端口检测、安装 xrdp 等命令），核心思路是通过curl或wget直接从 GitHub 拉取脚本并执行，我会给你两种最常用、最安全的方法，你可以直接复制使用。
前提准备
确保你的 GitHub 脚本满足 2 个条件：
脚本是公开的（私有仓库需要额外配置 token，新手先做公开）；
脚本第一行必须加#!/bin/bash（指定解释器），且脚本里的命令都加了sudo（或你以 root 身份执行）。
先通过 SSH 登录到你的云端服务器（ssh root@38.76.217.53）。
方法 1：直接拉取并执行（最快捷）
步骤 1：获取 GitHub 脚本的原始链接
打开 GitHub 上你的 sh 脚本页面；
点击右上角的「Raw」按钮，此时浏览器地址栏的链接就是原始脚本链接（例：https://raw.githubusercontent.com/你的用户名/仓库名/分支名/脚本名.sh）。
步骤 2：在服务器执行命令
把下面的链接替换成你的原始链接，直接执行：
bash
运行
# 方法A：用curl（Ubuntu默认安装）
curl -sSL https://raw.githubusercontent.com/你的用户名/仓库名/main/remote-desktop.sh | bash

# 方法B：用wget（如果curl没装）
wget -qO- https://raw.githubusercontent.com/你的用户名/仓库名/main/remote-desktop.sh | bash
wget -qO- https://raw.githubusercontent.com/guowangl365/Remote-desktop-System-Config/main/Remote-desktop.sh | bash
sudo wget -O ubuntu-wine-game-setup.sh https://raw.githubusercontent.com/guowangl365/Remote-desktop-System-Config/main/ubuntu-wine-game-setup.sh && sudo chmod +x ubuntu-wine-game-setup.sh && sudo ./ubuntu-wine-game-setup.sh
curl -O https://raw.githubusercontent.com/guowangl365/Remote-desktop-System-Config/main/android-studio-auto-setup.sh

-sSL/-qO-：静默模式，避免多余输出；
| bash：把拉取到的脚本内容直接传给 bash 执行。
方法 2：先下载再执行（更安全，可先检查脚本）
如果你想先看脚本内容再执行，避免误执行恶意代码，用这个方法：
bash
运行
# 1. 下载脚本到服务器
wget https://raw.githubusercontent.com/你的用户名/仓库名/main/remote-desktop.sh -O ~/remote-desktop.sh

# 2. 给脚本添加执行权限
chmod +x ~/remote-desktop.sh

# 3. （可选）查看脚本内容，确认无误
cat ~/remote-desktop.sh

# 4. 执行脚本
bash ~/remote-desktop.sh
示例：标准的远程桌面配置脚本（你可以直接用）
如果你的 GitHub 脚本还没写，这里给一个包含「端口检测→安装 xrdp→放行端口」的完整脚本，你可以复制到 GitHub 上：
bash
运行
#!/bin/bash
# 脚本功能：配置Ubuntu远程桌面（检测端口+安装xrdp+放行端口）

# 第一步：检查3389端口是否监听
echo "===== 检查3389端口状态 ====="
if ss -tulpn | grep 3389 > /dev/null; then
    echo "3389端口已被监听"
else
    echo "3389端口未监听，开始安装xrdp..."
    
    # 第二步：更新系统并安装桌面环境和xrdp
    sudo apt update && sudo apt upgrade -y
    sudo apt install xfce4 xfce4-goodies xrdp -y
    
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
注意事项
权限问题：如果不是以 root 身份登录，脚本里的所有sudo都会提示输入密码，建议直接用root执行（云服务器默认 root 登录）。
网络问题：如果拉取不到 GitHub 脚本，可能是服务器网络限制，可先执行sudo apt install curl wget -y，再尝试。
脚本换行符：确保 GitHub 上的脚本是LF换行（Linux 格式），不是CRLF（Windows 格式），否则执行会报错（GitHub 默认是 LF，不用改）。
总结
核心命令：通过curl/wget拉取 GitHub 原始脚本链接，管道给bash执行；
安全建议：新手优先用「先下载→检查内容→再执行」的方式；
关键前提：脚本要加#!/bin/bash，且命令带sudo（或 root 执行）。
执行完脚本后，你就可以按之前的方法用 Windows 远程桌面连接服务器了。
