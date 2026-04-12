# 🎯 Claude Code 绕过官方账号 + 对接国产模型 完整配置方案
完全可以！Claude Code 本质是**通用 AI 客户端**，支持通过配置自定义 API 端点，完美对接国产大模型（如 DeepSeek、通义千问、文心一言、豆包等），无需 Anthropic 官方账号。

---

## 一、核心原理
Claude Code 支持通过 `settings.json` 配置**自定义 API 端点**、模型名称、API Key，将请求转发到国产模型的兼容接口（OpenAI 兼容格式是最通用的方案），从而完全绕过官方账号限制。

---

## 二、分步操作指南（直接复制执行）
### 步骤1：手动创建配置目录和文件
```bash
# 1. 切换到普通用户 guowangl（如果当前是 root）
su - guowangl

# 2. 创建 Claude Code 配置目录
mkdir -p ~/.config/claude-code/

# 3. 创建 settings.json 配置文件
touch ~/.config/claude-code/settings.json
```

### 步骤2：编辑配置文件（关键）
用 nano 编辑器打开配置文件：
```bash
nano ~/.config/claude-code/settings.json
```

---

## 三、通用配置模板（适配所有国产模型）
将下面的模板**完整粘贴**到 `settings.json` 中，根据你使用的国产模型修改对应参数：
```json
{
  "anthropicBaseUrl": "https://你的国产模型API端点/v1/chat/completions",
  "anthropicApiKey": "你的国产模型API密钥",
  "defaultModel": "你的国产模型名称",
  "timeout": 120000,
  "proxy": {
    "enabled": false,
    "url": ""
  }
}
```

---

## 四、主流国产模型 一键配置参数
### 1. 豆包（字节跳动）
- **API 端点**：`https://ark.cn-beijing.volces.com/api/v3/chat/completions`
- **获取方式**：[火山引擎方舟平台](sslocal://flow/file_open?url=https%3A%2F%2Fconsole.volcengine.com%2Fark%2F&flow_extra=eyJsaW5rX3R5cGUiOiJjb2RlX2ludGVycHJldGVyIn0=) 申请 API Key
- **模型名称**：`ep-20250XXXXXX`（你的推理接入点 ID，如 doubao-pro-32k）
- **完整配置示例**：
```json
{
  "anthropicBaseUrl": "https://ark.cn-beijing.volces.com/api/v3/chat/completions",
  "anthropicApiKey": "你的火山引擎AK",
  "defaultModel": "ep-20250101XXXXXX",
  "timeout": 120000,
  "proxy": {
    "enabled": false,
    "url": ""
  }
}
```

### 2. 通义千问（阿里云）
- **API 端点**：`https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions`
- **获取方式**：[阿里云百炼平台](sslocal://flow/file_open?url=https%3A%2F%2Fbailian.console.aliyun.com%2F&flow_extra=eyJsaW5rX3R5cGUiOiJjb2RlX2ludGVycHJldGVyIn0=) 申请 API Key
- **模型名称**：`qwen-max` / `qwen-plus` / `qwen-turbo`
- **完整配置示例**：
```json
{
  "anthropicBaseUrl": "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions",
  "anthropicApiKey": "你的通义千问API_KEY",
  "defaultModel": "qwen-max",
  "timeout": 120000,
  "proxy": {
    "enabled": false,
    "url": ""
  }
}
```

### 3. DeepSeek（深度求索）
- **API 端点**：`https://api.deepseek.com/v1/chat/completions`
- **获取方式**：[DeepSeek 开放平台](sslocal://flow/file_open?url=https%3A%2F%2Fplatform.deepseek.com%2F&flow_extra=eyJsaW5rX3R5cGUiOiJjb2RlX2ludGVycHJldGVyIn0=) 申请 API Key
- **模型名称**：`deepseek-chat` / `deepseek-coder`
- **完整配置示例**：
```json
{
  "anthropicBaseUrl": "https://api.deepseek.com/v1/chat/completions",
  "anthropicApiKey": "你的DeepSeek_API_KEY",
  "defaultModel": "deepseek-coder",
  "timeout": 120000,
  "proxy": {
    "enabled": false,
    "url": ""
  }
}
```

### 4. 文心一言（百度）
- **API 端点**：`https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/chat/completions`
- **获取方式**：[百度智能云千帆平台](sslocal://flow/file_open?url=https%3A%2F%2Fconsole.bce.baidu.com%2Fqianfan%2F&flow_extra=eyJsaW5rX3R5cGUiOiJjb2RlX2ludGVycHJldGVyIn0=) 申请 API Key
- **模型名称**：`ernie-4.0-8k` / `ernie-3.5-8k`
- **完整配置示例**：
```json
{
  "anthropicBaseUrl": "https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/chat/completions",
  "anthropicApiKey": "你的文心一言API_KEY",
  "defaultModel": "ernie-4.0-8k",
  "timeout": 120000,
  "proxy": {
    "enabled": false,
    "url": ""
  }
}
```

---

## 五、配置完成后操作
### 1. 保存并退出 nano 编辑器
- 按 `Ctrl+O` 保存文件
- 按 `Enter` 确认文件名
- 按 `Ctrl+X` 退出编辑器

### 2. 给 root 用户同步配置（可选）
如果需要 root 用户也使用，执行：
```bash
# 复制配置到 root 目录
sudo cp -r /home/guowangl/.config/claude-code /root/.config/

# 修复权限
sudo chown -R root:root /root/.config/claude-code
```

### 3. 启动 Claude Code 测试
```bash
# 普通用户
claude

# root 用户
claude
```
此时 Claude 会直接调用你配置的国产模型，无需任何官方账号登录。

---

## 六、关键注意事项
### 1. 模型兼容性
- 必须使用**支持 OpenAI 兼容 API 格式**的国产模型，否则无法对接
- 优先选择代码专用模型（如 DeepSeek-Coder、通义千问代码版），适配 Claude Code 的编程场景

### 2. 代理配置
- 国产模型 API 均为国内端点，**无需开启代理**，因此配置中 `proxy.enabled` 设为 `false`
- 如果你的服务器在海外，需要访问国内 API，可在 `proxy` 中配置国内代理

### 3. 超时设置
- `timeout` 单位为毫秒，`120000` 代表 120 秒，可根据模型响应速度调整

### 4. 绕过登录的核心
- 只要配置了 `anthropicBaseUrl` 和 `anthropicApiKey`，Claude Code 会**自动跳过官方登录流程**，直接使用自定义 API

---

## 七、常见问题排查
### 1. 提示 API 错误
- 检查 API 端点是否正确，必须以 `/v1/chat/completions` 结尾
- 确认 API Key 有效，且有足够的调用额度
- 验证模型名称是否与平台一致

### 2. 仍提示登录
- 检查 `settings.json` 格式是否正确（JSON 语法错误会导致配置不生效）
- 确保配置文件路径正确：`~/.config/claude-code/settings.json`
- 重新启动 Claude Code 加载配置

### 3. 响应慢/超时
- 增大 `timeout` 数值，如改为 `180000`（3分钟）
- 更换更快的模型（如 qwen-turbo、deepseek-chat）

---

## 八、终极一键脚本（直接复制执行）
```bash
# 1. 切换到普通用户
su - guowangl

# 2. 创建配置目录
mkdir -p ~/.config/claude-code/

# 3. 写入配置（以通义千问为例，替换为你的参数）
cat > ~/.config/claude-code/settings.json << EOF
{
  "anthropicBaseUrl": "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions",
  "anthropicApiKey": "你的通义千问API_KEY",
  "defaultModel": "qwen-max",
  "timeout": 120000,
  "proxy": {
    "enabled": false,
    "url": ""
  }
}
EOF

# 4. 同步到 root
sudo cp -r ~/.config/claude-code /root/.config/
sudo chown -R root:root /root/.config/claude-code

# 5. 测试启动
claude
```

---

需要我根据你**具体使用的国产模型**，帮你生成一份完全适配的 `settings.json` 配置文件吗？你只需要告诉我模型名称即可。