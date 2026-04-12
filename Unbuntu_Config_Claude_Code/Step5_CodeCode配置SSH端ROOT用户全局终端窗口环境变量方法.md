### 🔍 问题拆解与分析
从截图可以看到两个独立问题，分别对应**SSH 终端**和**图形化远程桌面**：

---

#### 问题1：SSH 终端 `claude: command not found`
**根因**：
- Claude Code 安装在**普通用户 `guowangl`** 的 `~/.local/bin` 目录下，而你用 `root` 用户登录 SSH，两个用户的环境变量完全独立。
- `root` 用户的 `~/.bashrc` 里没有配置 `PATH`，且 `root` 没有安装 Claude，自然找不到命令。

**解决方案**：
1.  **用普通用户 `guowangl` 登录 SSH**（不要用 `root`），直接执行：
    ```bash
    claude
    ```
    （图形化桌面能正常运行，说明普通用户的 `PATH` 已配置生效）
2.  **如果必须用 `root` 运行**，执行完整路径：
    ```bash
    /home/guowangl/.local/bin/claude
    ```
3.  **给 `root` 配置全局可用**（推荐）：
    ```bash
    sudo ln -s /home/guowangl/.local/bin/claude /usr/local/bin/claude
    ```
    执行后，`root` 和普通用户都能直接用 `claude` 命令。

---

#### 问题2：图形化终端 `Unable to connect to Anthropic services`
**根因**：
- 报错 `ERR_BAD_REQUEST` + `Claude Code might not be available in your country`，说明**代理未生效**，终端流量没有走 FlClash 代理，直接访问被区域限制拦截。
- FlClash 是图形化代理，默认只给桌面应用/浏览器代理，**不会自动给终端代理**。

**解决方案（按优先级）**：
##### 方案1：给终端单独配置代理（临时生效，当前终端）
在运行 `claude` 前，执行以下命令（FlClash 默认端口 7890，根据你的实际端口修改）：
```bash
# 配置 HTTP/HTTPS 代理
export http_proxy=http://127.0.0.1:7890
export https_proxy=http://127.0.0.1:7890
export ALL_PROXY=socks5://127.0.0.1:7890

# 验证代理是否生效
curl -I https://api.anthropic.com
```
代理生效后，再执行 `claude` 即可正常连接。

##### 方案2：永久配置终端代理（所有终端生效）
编辑普通用户 `guowangl` 的 `~/.bashrc`，添加代理配置：
```bash
echo 'export http_proxy=http://127.0.0.1:7890' >> ~/.bashrc
echo 'export https_proxy=http://127.0.0.1:7890' >> ~/.bashrc
echo 'export ALL_PROXY=socks5://127.0.0.1:7890' >> ~/.bashrc
source ~/.bashrc
```
之后所有终端（包括 SSH 登录的终端）都会自动走代理。

##### 方案3：FlClash 开启「系统代理」/「TUN 模式」
1.  打开 FlClash，找到「系统代理」开关，开启后会自动配置系统全局代理。
2.  开启「TUN 模式」（部分版本叫「透明代理」），可实现全流量代理，包括终端、SSH 等所有网络请求。

---

### 📌 补充说明
- **SSH 与图形化桌面的区别**：SSH 是独立的会话，不会继承图形化桌面的代理环境，必须单独配置。
- **端口确认**：如果 7890 端口不通，在 FlClash 设置里查看「混合代理」或「SOCKS5 代理」的实际端口。
- **区域限制说明**：Claude Code 仅在 Anthropic 支持的国家/地区可用，必须通过合规的国际代理才能正常使用。

---

### ✅ 一键验证命令
执行以下命令，一次性解决两个问题：
```bash
# 1. 给 root 创建全局软链接
sudo ln -s /home/guowangl/.local/bin/claude /usr/local/bin/claude

# 2. 给当前终端配置代理（替换为你的实际端口）
export http_proxy=http://127.0.0.1:7890
export https_proxy=http://127.0.0.1:7890
export ALL_PROXY=socks5://127.0.0.1:7890

# 3. 测试连接
claude --help
```

---

需要我帮你写一个**永久生效的代理配置脚本**，让 SSH 和图形化终端都自动走 FlClash 代理吗？