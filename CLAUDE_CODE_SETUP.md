# Claude Code 配置指南

## 概述

本项目的代理服务器 (`http://hh:8000/`) 使用 OpenAI 兼容格式提供 Claude 模型访问。

## 测试结果

✅ **代理服务器状态：正常**
- 端点：`http://hh:8000/v1/chat/completions`
- 格式：OpenAI 兼容 API
- API Key：`sk-e29d01f16f735a11dcee47f660541dd5bba9947c1e036cc2`

✅ **可用模型：**
- `claude-sonnet-4-5` (推荐 - 最新版本)
- `claude-opus-4-5` (最强性能)
- `claude-haiku-4-5` (快速响应)
- `claude-3-7-sonnet-20250219`
- `claude-sonnet-4`
- `claude-sonnet-4-20250514`
- `claude-opus-4-5-20251101`
- `claude-haiku-4-5-20251001`

## Claude Code 配置方法

### 方法 1：环境变量配置（推荐）

在您的 shell 配置文件中添加（`~/.zshrc` 或 `~/.bashrc`）：

```bash
# Claude Code 配置
export OPENAI_API_KEY="sk-e29d01f16f735a11dcee47f660541dd5bba9947c1e036cc2"
export OPENAI_BASE_URL="http://hh:8000/v1"
```

然后重新加载配置：
```bash
source ~/.zshrc  # 或 source ~/.bashrc
```

### 方法 2：Claude Code 配置文件

Claude Code 的配置文件通常位于：
- macOS/Linux: `~/.config/claude-code/config.json`
- Windows: `%APPDATA%\claude-code\config.json`

编辑配置文件，添加：

```json
{
  "apiKey": "sk-e29d01f16f735a11dcee47f660541dd5bba9947c1e036cc2",
  "baseURL": "http://hh:8000/v1",
  "model": "claude-sonnet-4-5"
}
```

### 方法 3：命令行参数

每次运行 Claude Code 时指定：

```bash
claude-code --api-key "sk-e29d01f16f735a11dcee47f660541dd5bba9947c1e036cc2" \
            --base-url "http://hh:8000/v1" \
            --model "claude-sonnet-4-5"
```

## 验证配置

### 1. 测试 API 连接

```bash
curl -X POST "http://hh:8000/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-e29d01f16f735a11dcee47f660541dd5bba9947c1e036cc2" \
  -d '{
    "model": "claude-sonnet-4-5",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 50
  }'
```

预期输出：
```json
{
  "id": "chatcmpl-...",
  "object": "chat.completion",
  "created": 1767429730,
  "model": "claude-sonnet-4-5",
  "choices": [{
    "index": 0,
    "message": {
      "role": "assistant",
      "content": "你好！很高兴见到你。有什么我可以帮助你的吗？"
    },
    "finish_reason": "stop"
  }],
  "usage": {
    "prompt_tokens": 13,
    "completion_tokens": 31,
    "total_tokens": 44
  }
}
```

### 2. 测试 Claude Code

```bash
# 启动 Claude Code
claude-code

# 或者在项目目录中
cd /Volumes/mac/TradingAgents-CN
claude-code
```

## 模型选择建议

| 模型 | 用途 | 特点 |
|------|------|------|
| `claude-sonnet-4-5` | **日常开发（推荐）** | 平衡性能和速度，适合大多数编程任务 |
| `claude-opus-4-5` | 复杂任务 | 最强性能，适合复杂架构设计和难题 |
| `claude-haiku-4-5` | 快速响应 | 速度最快，适合简单查询和代码补全 |

## 常见问题

### Q1: 为什么不能使用 ANTHROPIC_API_KEY？

**A:** 您的代理服务器使用 OpenAI 兼容格式，而不是原生 Anthropic API 格式。必须使用 `OPENAI_API_KEY` 和 `OPENAI_BASE_URL`。

### Q2: 出现 403 错误怎么办？

**A:** 检查以下几点：
1. API Key 是否正确
2. Base URL 是否包含 `/v1` 后缀
3. 是否使用了正确的环境变量名（`OPENAI_API_KEY` 而不是 `ANTHROPIC_API_KEY`）

### Q3: 如何切换模型？

**A:** 在配置中修改 `model` 字段，或使用命令行参数 `--model`：
```bash
claude-code --model "claude-opus-4-5"  # 使用更强大的模型
claude-code --model "claude-haiku-4-5"  # 使用更快的模型
```

### Q4: 代理服务器连接超时？

**A:** 检查：
1. 代理服务器是否运行：`curl http://hh:8000/`
2. 网络连接是否正常
3. 防火墙设置是否阻止了连接

## 项目集成

本项目的 `.env` 文件已经配置了相关环境变量：

```env
# OpenAI API（实际连接到 Claude 代理）
OPENAI_API_KEY=sk-e29d01f16f735a11dcee47f660541dd5bba9947c1e036cc2
OPENAI_BASE_URL=http://hh:8000/v1
```

如果您在项目中使用 Python 代码调用 Claude，可以这样使用：

```python
import os
from openai import OpenAI

# 使用 OpenAI 客户端连接到 Claude 代理
client = OpenAI(
    api_key=os.getenv("OPENAI_API_KEY"),
    base_url=os.getenv("OPENAI_BASE_URL")
)

response = client.chat.completions.create(
    model="claude-sonnet-4-5",
    messages=[
        {"role": "user", "content": "你好"}
    ]
)

print(response.choices[0].message.content)
```

## 安全提示

⚠️ **重要：**
1. 不要将 API Key 提交到 Git 仓库
2. `.env` 文件已在 `.gitignore` 中
3. 在生产环境中使用更安全的密钥管理方案

## 更多信息

- Claude Code 官方文档：https://github.com/anthropics/claude-code
- OpenAI API 文档：https://platform.openai.com/docs/api-reference
- Anthropic API 文档：https://docs.anthropic.com/

---

**最后更新：** 2026-01-03
**测试状态：** ✅ 通过
