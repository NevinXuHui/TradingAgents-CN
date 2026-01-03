# Claude API 快速开始 🚀

## 一分钟配置

### 1. 环境变量（已配置 ✅）

```bash
# 在 ~/.zshrc 或 ~/.bashrc 中添加
export OPENAI_API_KEY="sk-e29d01f16f735a11dcee47f660541dd5bba9947c1e036cc2"
export OPENAI_BASE_URL="http://hh:8000/v1"
```

### 2. 快速测试

```bash
# 测试 API 连接
bash scripts/test_claude_simple.sh

# 或使用 curl
curl -X POST "http://hh:8000/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-e29d01f16f735a11dcee47f660541dd5bba9947c1e036cc2" \
  -d '{"model":"claude-sonnet-4-5","messages":[{"role":"user","content":"你好"}],"max_tokens":50}'
```

---

## 常用代码片段

### Python - 基础使用

```python
from openai import OpenAI
import os

client = OpenAI(
    api_key=os.getenv("OPENAI_API_KEY"),
    base_url=os.getenv("OPENAI_BASE_URL")
)

response = client.chat.completions.create(
    model="claude-sonnet-4-5",
    messages=[{"role": "user", "content": "你好"}]
)

print(response.choices[0].message.content)
```

### Python - 流式输出

```python
stream = client.chat.completions.create(
    model="claude-sonnet-4-5",
    messages=[{"role": "user", "content": "写一首诗"}],
    stream=True
)

for chunk in stream:
    if chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="", flush=True)
```

### Python - 对话历史

```python
messages = [
    {"role": "user", "content": "你好"},
    {"role": "assistant", "content": "你好！有什么可以帮助你的吗？"},
    {"role": "user", "content": "介绍一下 Python"}
]

response = client.chat.completions.create(
    model="claude-sonnet-4-5",
    messages=messages
)
```

---

## 模型选择速查

| 场景 | 推荐模型 | 命令 |
|------|---------|------|
| 日常开发 | Sonnet 4.5 | `model="claude-sonnet-4-5"` |
| 复杂任务 | Opus 4.5 | `model="claude-opus-4-5"` |
| 快速响应 | Haiku 4.5 | `model="claude-haiku-4-5"` |

---

## Claude Code 使用

```bash
# 启动 Claude Code
claude-code

# 使用特定模型
claude-code --model "claude-opus-4-5"

# 在项目中使用
cd /Volumes/mac/TradingAgents-CN
claude-code
```

---

## 常见问题速查

### ❌ HTTP 403 错误

**原因**: 使用了错误的 API 格式

**解决**:
```bash
# ❌ 错误
ANTHROPIC_API_KEY=...
ANTHROPIC_BASE_URL=http://hh:8000/

# ✅ 正确
OPENAI_API_KEY=...
OPENAI_BASE_URL=http://hh:8000/v1  # 注意 /v1 后缀
```

### ❌ 连接超时

**检查步骤**:
```bash
# 1. 检查代理服务器
curl http://hh:8000/

# 2. 检查网络
ping hh

# 3. 测试 API
bash scripts/test_claude_simple.sh
```

### ❌ 模型不支持

**可用模型**:
- ✅ `claude-sonnet-4-5`
- ✅ `claude-opus-4-5`
- ✅ `claude-haiku-4-5`
- ❌ `gpt-3.5-turbo` (不支持)
- ❌ `gpt-4` (不支持)

---

## 有用的命令

```bash
# 查看环境变量
echo $OPENAI_API_KEY
echo $OPENAI_BASE_URL

# 重新加载配置
source ~/.zshrc

# 运行测试
bash scripts/test_claude_simple.sh

# 查看 API 响应
curl -X POST "http://hh:8000/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{"model":"claude-sonnet-4-5","messages":[{"role":"user","content":"测试"}],"max_tokens":10}' | python3 -m json.tool
```

---

## 更多信息

- 📖 完整配置指南: [docs/CLAUDE_API_CONFIGURATION.md](docs/CLAUDE_API_CONFIGURATION.md)
- 📖 Claude Code 设置: [CLAUDE_CODE_SETUP.md](CLAUDE_CODE_SETUP.md)
- 🧪 测试脚本: [scripts/test_claude_simple.sh](scripts/test_claude_simple.sh)

---

**配置状态**: ✅ 已完成 | **测试状态**: ✅ 通过 | **最后更新**: 2026-01-03
