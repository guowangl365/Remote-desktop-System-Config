### ✅ 执行远程桌面安装命令
wget -qO- https://raw.githubusercontent.com/guowangl365/Remote-desktop-System-Config/main/Remote-desktop.sh | bash


### ✅ 下载软件
https://app.chongjin01.icu/Linux/


### ✅ 正确安装步骤（直接复制执行）
#### 1. 用正确文件名执行 dpkg 安装
```bash
sudo dpkg -i ./FlClash--linux-amd64.deb
```

#### 2. 自动修复依赖（必须执行）
如果上一步出现依赖缺失报错，执行此命令补全环境：
```bash
sudo apt -f install
```

#### 3. 验证安装与启动
```bash
# 检查是否安装成功
dpkg -l | grep flclash

# 启动 FlClash
flclash
```

---

### 📌 补充说明
- **为什么 apt 命令报错**：`apt install ./xxx.deb` 是 apt 2.0+ 版本新增的功能，旧版本（如 Ubuntu 18.04、Debian 9 及以下）不支持，因此必须用 `dpkg` + `apt -f install` 的经典组合。
- **文件名注意事项**：Linux 对文件名大小写、符号**完全敏感**，必须严格和 `ls` 显示的一致（双横杠 `--` 不能写成单横杠 `-`）。
- **全局搜索兜底**：如果后续仍找不到文件，可执行全局搜索定位：
  ```bash
  find ~ -name "FlClash*.deb"
  ```

---

### 💡 新手友好方案（图形化）
如果不想用命令行，可安装 GDebi 图形安装器：
```bash
sudo apt update && sudo apt install gdebi-core
```
然后在桌面右键 `FlClash--linux-amd64.deb`，选择「用 GDebi 包安装器打开」，点击「安装包」即可自动处理依赖。

需要我帮你写一条**一键安装+启动**的完整命令，直接复制就能用吗？