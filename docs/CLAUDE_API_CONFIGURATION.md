# Claude API 配置完整指南

## 📋 目录

1. [配置概述](#配置概述)
2. [环境变量配置](#环境变量配置)
3. [Claude Code 集成](#claude-code-集成)
4. [Python 项目集成](#python-项目集成)
5. [测试验证](#测试验证)
6. [常见问题](#常见问题)
7. [最佳实践](#最佳实践)

---

## 配置概述

### ✅ 当前配置状态

您的代理服务器配置：
- **端点**: `http://hh:8000/v1`
- **格式**: OpenAI 兼容 API
- **API Key**: `sk-e29d01f16f735a11dcee47f660541dd5bba9947c1e036cc2`
- **状态**: ✅ 已测试通过

### 🎯 可用模型

| 模型名称 | 版本 | 用途 | 性能 |
|---------|------|------|------|
| `claude-sonnet-4-5` | 最新 | **日常开发（推荐）** | ⭐⭐⭐⭐ |
| `claude-opus-4-5` | 最新 | 复杂任务、架构设计 | ⭐⭐⭐⭐⭐ |
| `claude-haiku-4-5` | 最新 | 快速响应、代码补全 | ⭐⭐⭐ |
| `claude-3-7-sonnet-20250219` | 3.7 | 稳定版本 | ⭐⭐⭐⭐ |
| `claude-sonnet-4` | 4.0 | 标准版本 | ⭐⭐⭐⭐ |
| `claude-sonnet-4-20250514` | 4.0 | 特定日期版本 | ⭐⭐⭐⭐ |
| `claude-opus-4-5-20251101` | 4.5 | 特定日期版本 | ⭐⭐⭐⭐⭐ |
| `claude-haiku-4-5-20251001` | 4.5 | 特定日期版本 | ⭐⭐⭐ |

---

## 环境变量配置

### 1. 项目 .env 文件

项目根目录的 `.env` 文件已配置：

```bash
# OpenAI API（实际连接到 Claude 代理）
OPENAI_API_KEY=sk-e29d01f16f735a11dcee47f660541dd5bba9947c1e036cc2
OPENAI_BASE_URL=http://hh:8000/v1
```

### 2. Shell 环境变量（用于 Claude Code）

在您的 shell 配置文件中添加（`~/.zshrc` 或 `~/.bashrc`）：

```bash
# Claude Code 配置
export OPENAI_API_KEY="sk-e29d01f16f735a11dcee47f660541dd5bba9947c1e036cc2"
export OPENAI_BASE_URL="http://hh:8000/v1"

# 可选：设置默认模型
export OPENAI_MODEL="claude-sonnet-4-5"
```

应用配置：

```bash
# macOS/Linux
source ~/.zshrc  # 或 source ~/.bashrc

# 验证配置
echo $OPENAI_API_KEY
echo $OPENAI_BASE_URL
```

---

## Claude Code 集成

### 方法 1：使用环境变量（推荐）

如果已配置 shell 环境变量，直接运行：

```bash
claude-code
```

### 方法 2：使用配置文件

创建 Claude Code 配置文件：

**macOS/Linux**: `~/.config/claude-code/config.json`

```json
{
  "apiProvider": "openai",
  "apiKey": "sk-e29d01f16f735a11dcee47f660541dd5bba9947c1e036cc2",
  "baseURL": "http://hh:8000/v1",
  "model": "claude-sonnet-4-5",
  "maxTokens": 4096
}
```

### 方法 3：命令行参数

每次运行时指定：

```bash
claude-code \
  --api-key "sk-e29d01f16f735a11dcee47f660541dd5bba9947c1e036cc2" \
  --base-url "http://hh:8000/v1" \
  --model "claude-sonnet-4-5"
```

### 在项目中使用 Claude Code

```bash
# 进入项目目录
cd /Volumes/mac/TradingAgents-CN

# 启动 Claude Code
claude-code

# 或使用特定模型
claude-code --model "claude-opus-4-5"  # 使用更强大的模型
claude-code --model "claude-haiku-4-5"  # 使用更快的模型
```

---

## Python 项目集成

### 1. 使用 OpenAI SDK

```python
import os
from openai import OpenAI

# 从环境变量加载配置
client = OpenAI(
    api_key=os.getenv("OPENAI_API_KEY"),
    base_url=os.getenv("OPENAI_BASE_URL")
)

# 发送请求
response = client.chat.completions.create(
    model="claude-sonnet-4-5",
    messages=[
        {"role": "user", "content": "你好，请介绍一下你自己"}
    ],
    max_tokens=100
)

print(response.choices[0].message.content)
```

### 2. 使用 LangChain

```python
from langchain_openai import ChatOpenAI
import os

# 创建 LangChain 客户端
llm = ChatOpenAI(
    model="claude-sonnet-4-5",
    openai_api_key=os.getenv("OPENAI_API_KEY"),
    openai_api_base=os.getenv("OPENAI_BASE_URL"),
    max_tokens=1000
)

# 使用
response = llm.invoke("你好")
print(response.content)
```

### 3. 异步调用

```python
import asyncio
from openai import AsyncOpenAI
import os

async def chat():
    client = AsyncOpenAI(
        api_key=os.getenv("OPENAI_API_KEY"),
        base_url=os.getenv("OPENAI_BASE_URL")
    )

    response = await client.chat.completions.create(
        model="claude-sonnet-4-5",
        messages=[
            {"role": "user", "content": "Hello"}
        ]
    )

    return response.choices[0].message.content

# 运行
result = asyncio.run(chat())
print(result)
```

### 4. 流式响应

```python
from openai import OpenAI
import os

client = OpenAI(
    api_key=os.getenv("OPENAI_API_KEY"),
    base_url=os.getenv("OPENAI_BASE_URL")
)

# 流式输出
stream = client.chat.completions.create(
    model="claude-sonnet-4-5",
    messages=[
        {"role": "user", "content": "写一首关于编程的诗"}
    ],
    stream=True
)

for chunk in stream:
    if chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="", flush=True)
```

---

## 测试验证

### 快速测试脚本

项目提供了两个测试脚本：

#### 1. Shell 脚本测试（推荐）

```bash
# 运行测试
bash scripts/test_claude_simple.sh
```

**测试内容**：
- ✅ API 连接测试
- ✅ 简单对话测试
- ✅ 代码生成测试
- ✅ Token 使用统计

#### 2. Python 脚本测试

```bash
# 安装依赖
pip install openai python-dotenv

# 运行测试
python scripts/test_claude_api.py
```

### 手动测试

#### 使用 curl 测试

```bash
curl -X POST "http://hh:8000/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-e29d01f16f735a11dcee47f660541dd5bba9947c1e036cc2" \
  -d '{
    "model": "claude-sonnet-4-5",
    "messages": [{"role": "user", "content": "你好"}],
    "max_tokens": 50
  }'
```

**预期输出**：

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
      "content": "你好！我是Claude，一个由Anthropic开发的AI助手..."
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

#### 使用 Python 测试

```python
from openai import OpenAI

client = OpenAI(
    api_key="sk-e29d01f16f735a11dcee47f660541dd5bba9947c1e036cc2",
    base_url="http://hh:8000/v1"
)

response = client.chat.completions.create(
    model="claude-sonnet-4-5",
    messages=[{"role": "user", "content": "你好"}]
)

print(response.choices[0].message.content)
```

---

## 常见问题

### Q1: 为什么不能使用 ANTHROPIC_API_KEY？

**A:** 您的代理服务器使用 **OpenAI 兼容格式**，而不是原生 Anthropic API 格式。

- ❌ 错误配置：
  ```bash
  ANTHROPIC_API_KEY=sk-...
  ANTHROPIC_BASE_URL=http://hh:8000/
  ```

- ✅ 正确配置：
  ```bash
  OPENAI_API_KEY=sk-...
  OPENAI_BASE_URL=http://hh:8000/v1
  ```

### Q2: 出现 HTTP 403 错误怎么办？

**可能原因**：

1. **使用了错误的 API 格式**
   - 检查是否使用了 `ANTHROPIC_API_KEY` 而不是 `OPENAI_API_KEY`
   - 确保使用 OpenAI 兼容格式

2. **Base URL 配置错误**
   - ❌ 错误：`http://hh:8000/`
   - ✅ 正确：`http://hh:8000/v1`

3. **API Key 错误**
   - 检查 API Key 是否正确复制
   - 确认没有多余的空格或换行符

### Q3: 如何切换不同的模型？

**方法 1：在代码中指定**

```python
# 使用 Sonnet（推荐）
response = client.chat.completions.create(
    model="claude-sonnet-4-5",
    messages=[...]
)

# 使用 Opus（最强性能）
response = client.chat.completions.create(
    model="claude-opus-4-5",
    messages=[...]
)

# 使用 Haiku（快速响应）
response = client.chat.completions.create(
    model="claude-haiku-4-5",
    messages=[...]
)
```

**方法 2：环境变量**

```bash
export OPENAI_MODEL="claude-opus-4-5"
```

**方法 3：Claude Code 命令行**

```bash
claude-code --model "claude-opus-4-5"
```

### Q4: 代理服务器连接超时？

**排查步骤**：

1. **检查代理服务器状态**
   ```bash
   curl http://hh:8000/
   ```

2. **检查网络连接**
   ```bash
   ping hh
   ```

3. **检查防火墙设置**
   - 确保端口 8000 未被阻止

4. **检查代理服务器日志**
   - 查看是否有错误信息

### Q5: Token 使用量如何计算？

**Token 计算规则**：

- **中文**：约 1.5-2 个字符 = 1 token
- **英文**：约 4 个字符 = 1 token
- **代码**：约 3-4 个字符 = 1 token

**示例**：

```python
# 查看 token 使用
response = client.chat.completions.create(...)
print(f"输入: {response.usage.prompt_tokens} tokens")
print(f"输出: {response.usage.completion_tokens} tokens")
print(f"总计: {response.usage.total_tokens} tokens")
```

### Q6: 如何处理速率限制？

**策略**：

1. **添加重试逻辑**
   ```python
   from openai import OpenAI
   import time

   def chat_with_retry(client, messages, max_retries=3):
       for i in range(max_retries):
           try:
               return client.chat.completions.create(
                   model="claude-sonnet-4-5",
                   messages=messages
               )
           except Exception as e:
               if i < max_retries - 1:
                   time.sleep(2 ** i)  # 指数退避
                   continue
               raise
   ```

2. **使用更快的模型**
   - 对于简单任务使用 `claude-haiku-4-5`

3. **批量处理**
   - 合并多个小请求为一个大请求

---

## 最佳实践

### 1. 模型选择策略

```python
def get_model_for_task(task_type):
    """根据任务类型选择合适的模型"""
    models = {
        "simple": "claude-haiku-4-5",      # 简单查询、代码补全
        "standard": "claude-sonnet-4-5",   # 日常开发、代码审查
        "complex": "claude-opus-4-5",      # 架构设计、复杂问题
    }
    return models.get(task_type, "claude-sonnet-4-5")

# 使用
model = get_model_for_task("standard")
response = client.chat.completions.create(model=model, ...)
```

### 2. 错误处理

```python
from openai import OpenAI, OpenAIError
import logging

def safe_chat(client, messages, model="claude-sonnet-4-5"):
    """安全的聊天函数，包含错误处理"""
    try:
        response = client.chat.completions.create(
            model=model,
            messages=messages,
            timeout=30.0  # 设置超时
        )
        return response.choices[0].message.content

    except OpenAIError as e:
        logging.error(f"OpenAI API 错误: {e}")
        return None

    except Exception as e:
        logging.error(f"未知错误: {e}")
        return None
```

### 3. 成本优化

```python
class CostTracker:
    """Token 使用和成本跟踪"""

    def __init__(self):
        self.total_tokens = 0
        self.total_cost = 0.0

        # 假设的价格（实际价格请咨询您的代理服务商）
        self.prices = {
            "claude-haiku-4-5": {"input": 0.00025, "output": 0.00125},
            "claude-sonnet-4-5": {"input": 0.003, "output": 0.015},
            "claude-opus-4-5": {"input": 0.015, "output": 0.075},
        }

    def track(self, response, model):
        """跟踪单次请求的成本"""
        usage = response.usage
        price = self.prices.get(model, self.prices["claude-sonnet-4-5"])

        cost = (
            usage.prompt_tokens * price["input"] / 1000 +
            usage.completion_tokens * price["output"] / 1000
        )

        self.total_tokens += usage.total_tokens
        self.total_cost += cost

        return {
            "tokens": usage.total_tokens,
            "cost": cost,
            "total_cost": self.total_cost
        }

# 使用
tracker = CostTracker()
response = client.chat.completions.create(...)
stats = tracker.track(response, "claude-sonnet-4-5")
print(f"本次成本: ¥{stats['cost']:.4f}")
print(f"累计成本: ¥{stats['total_cost']:.2f}")
```

### 4. 上下文管理

```python
class ConversationManager:
    """对话上下文管理"""

    def __init__(self, max_history=10):
        self.messages = []
        self.max_history = max_history

    def add_user_message(self, content):
        """添加用户消息"""
        self.messages.append({"role": "user", "content": content})
        self._trim_history()

    def add_assistant_message(self, content):
        """添加助手消息"""
        self.messages.append({"role": "assistant", "content": content})
        self._trim_history()

    def _trim_history(self):
        """保持历史记录在限制内"""
        if len(self.messages) > self.max_history:
            # 保留系统消息，删除最旧的对话
            system_msgs = [m for m in self.messages if m["role"] == "system"]
            other_msgs = [m for m in self.messages if m["role"] != "system"]
            self.messages = system_msgs + other_msgs[-self.max_history:]

    def get_messages(self):
        """获取当前对话历史"""
        return self.messages.copy()

# 使用
conv = ConversationManager()
conv.add_user_message("你好")
response = client.chat.completions.create(
    model="claude-sonnet-4-5",
    messages=conv.get_messages()
)
conv.add_assistant_message(response.choices[0].message.content)
```

### 5. 配置管理

```python
from dataclasses import dataclass
import os

@dataclass
class ClaudeConfig:
    """Claude API 配置"""
    api_key: str
    base_url: str
    model: str = "claude-sonnet-4-5"
    max_tokens: int = 4096
    temperature: float = 0.7

    @classmethod
    def from_env(cls):
        """从环境变量加载配置"""
        return cls(
            api_key=os.getenv("OPENAI_API_KEY"),
            base_url=os.getenv("OPENAI_BASE_URL"),
            model=os.getenv("OPENAI_MODEL", "claude-sonnet-4-5")
        )

    def create_client(self):
        """创建 OpenAI 客户端"""
        from openai import OpenAI
        return OpenAI(
            api_key=self.api_key,
            base_url=self.base_url
        )

# 使用
config = ClaudeConfig.from_env()
client = config.create_client()
```

---

## 安全建议

### 1. API Key 保护

- ✅ **DO**：
  - 使用环境变量存储 API Key
  - 将 `.env` 文件添加到 `.gitignore`
  - 定期轮换 API Key
  - 使用密钥管理服务（如 AWS Secrets Manager）

- ❌ **DON'T**：
  - 不要在代码中硬编码 API Key
  - 不要将 API Key 提交到 Git
  - 不要在日志中打印完整的 API Key
  - 不要在公共场合分享 API Key

### 2. 访问控制

```python
# 使用环境变量，不要硬编码
api_key = os.getenv("OPENAI_API_KEY")
if not api_key:
    raise ValueError("未设置 OPENAI_API_KEY 环境变量")

# 日志中隐藏敏感信息
logging.info(f"使用 API Key: {api_key[:10]}...{api_key[-4:]}")
```

### 3. 速率限制

```python
from functools import wraps
import time

def rate_limit(calls_per_minute=60):
    """速率限制装饰器"""
    min_interval = 60.0 / calls_per_minute
    last_called = [0.0]

    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            elapsed = time.time() - last_called[0]
            left_to_wait = min_interval - elapsed
            if left_to_wait > 0:
                time.sleep(left_to_wait)
            ret = func(*args, **kwargs)
            last_called[0] = time.time()
            return ret
        return wrapper
    return decorator

@rate_limit(calls_per_minute=30)
def call_claude_api(client, messages):
    return client.chat.completions.create(
        model="claude-sonnet-4-5",
        messages=messages
    )
```

---

## 相关资源

### 文档

- 📖 [Claude Code 配置指南](../CLAUDE_CODE_SETUP.md)
- 📖 [项目配置指南](../docs/configuration_guide.md)
- 📖 [API 聚合渠道支持](../docs/AGGREGATOR_SUPPORT.md)

### 测试脚本

- 🧪 [Shell 测试脚本](../scripts/test_claude_simple.sh)
- 🧪 [Python 测试脚本](../scripts/test_claude_api.py)

### 官方文档

- [OpenAI API 文档](https://platform.openai.com/docs/api-reference)
- [Anthropic API 文档](https://docs.anthropic.com/)
- [Claude Code GitHub](https://github.com/anthropics/claude-code)

---

## 更新日志

### 2026-01-03
- ✅ 完成 API 配置和测试
- ✅ 验证所有可用模型
- ✅ 创建测试脚本
- ✅ 编写完整文档

---

**配置状态**: ✅ 已完成并测试通过

如有问题，请参考 [常见问题](#常见问题) 部分或查看测试脚本输出。
