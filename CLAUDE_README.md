# Claude API 集成完整指南

## 📋 目录

- [快速开始](#快速开始)
- [配置状态](#配置状态)
- [文档资源](#文档资源)
- [测试工具](#测试工具)
- [代码示例](#代码示例)
- [常见问题](#常见问题)
- [下一步](#下一步)

---

## 🚀 快速开始

### 1. 环境变量已配置 ✅

项目的 `.env` 文件已包含 Claude API 配置：

```bash
OPENAI_API_KEY=sk-e29d01f16f735a11dcee47f660541dd5bba9947c1e036cc2
OPENAI_BASE_URL=http://hh:8000/v1
```

### 2. 快速测试

```bash
# 运行简单测试
bash scripts/test_claude_simple.sh

# 运行完整诊断
bash scripts/diagnose_claude_config.sh
```

### 3. 立即使用

#### 方式 A: 命令行测试

```bash
curl -X POST "http://hh:8000/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-e29d01f16f735a11dcee47f660541dd5bba9947c1e036cc2" \
  -d '{"model":"claude-sonnet-4-5","messages":[{"role":"user","content":"你好"}],"max_tokens":50}'
```

#### 方式 B: Python 代码

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

#### 方式 C: Claude Code CLI

```bash
# 配置环境变量后直接使用
claude-code

# 或在项目中使用
cd /Volumes/mac/TradingAgents-CN
claude-code
```

---

## ✅ 配置状态

### 测试结果（2026-01-03）

```
✅ .env 文件配置: 正常
✅ 网络连接: 正常
✅ 代理服务器: 正常
✅ API 调用: 成功
✅ 可用模型:
   - claude-sonnet-4-5 ⭐ 推荐
   - claude-opus-4-5
   - claude-haiku-4-5
✅ Shell 环境变量: 已配置
```

### 可用模型

| 模型 | 用途 | 特点 |
|------|------|------|
| **claude-sonnet-4-5** | 日常开发 | ⭐ 推荐，平衡性能和速度 |
| **claude-opus-4-5** | 复杂任务 | 最强性能，适合架构设计 |
| **claude-haiku-4-5** | 快速响应 | 速度最快，适合简单查询 |

---

## 📚 文档资源

### 核心文档

1. **[CLAUDE_QUICK_START.md](CLAUDE_QUICK_START.md)** ⭐ 推荐首先阅读
   - 一分钟快速配置
   - 常用代码片段
   - 模型选择速查
   - 常见问题速查

2. **[CLAUDE_CODE_SETUP.md](CLAUDE_CODE_SETUP.md)**
   - Claude Code CLI 详细配置
   - 验证方法
   - 模型选择建议
   - 故障排查

3. **[docs/CLAUDE_API_CONFIGURATION.md](docs/CLAUDE_API_CONFIGURATION.md)**
   - 完整配置指南
   - Python 项目集成
   - 最佳实践
   - 安全建议
   - 成本优化

4. **[CLAUDE_SETUP_SUMMARY.md](CLAUDE_SETUP_SUMMARY.md)**
   - 配置总结
   - 测试报告
   - 下一步操作
   - 相关资源

### 文档结构

```
TradingAgents-CN/
├── CLAUDE_QUICK_START.md          # 快速开始（推荐）
├── CLAUDE_CODE_SETUP.md           # Claude Code 配置
├── CLAUDE_SETUP_SUMMARY.md        # 配置总结
├── docs/
│   └── CLAUDE_API_CONFIGURATION.md # 完整配置文档
├── scripts/
│   ├── test_claude_simple.sh      # 简单测试脚本
│   ├── test_claude_api.py         # Python 测试脚本
│   └── diagnose_claude_config.sh  # 诊断工具
└── examples/
    ├── claude_api_examples.py     # 基础示例
    └── trading_ai_examples.py     # 交易分析示例
```

---

## 🧪 测试工具

### 1. 简单测试脚本（推荐）

```bash
bash scripts/test_claude_simple.sh
```

**测试内容**：
- ✅ API 连接测试
- ✅ 简单对话测试
- ✅ 代码生成测试
- ✅ Token 使用统计

**输出示例**：
```
==========================================
🧪 Claude API 配置测试
==========================================

📍 Base URL: http://hh:8000/v1
🔑 API Key: sk-e29d01f16f735a11d...

💬 测试 1: 简单对话
----------------------------------------
📥 收到回复: 你好！我是Claude...
📊 Token 使用: 输入=26, 输出=50, 总计=76

✅ 所有测试通过！
```

### 2. 完整诊断工具

```bash
bash scripts/diagnose_claude_config.sh
```

**诊断内容**：
- ✅ .env 文件检查
- ✅ 网络连接测试
- ✅ 代理服务器状态
- ✅ API 调用测试
- ✅ 模型可用性测试
- ✅ Shell 环境变量检查
- ✅ Python 环境检查

### 3. Python 测试脚本

```bash
# 需要先安装依赖
pip install openai python-dotenv

# 运行测试
python scripts/test_claude_api.py
```

**测试内容**：
- 完整的 API 测试
- Token 使用统计
- 多模型测试
- 错误处理测试

---

## 💻 代码示例

### 基础示例

位置：`examples/claude_api_examples.py`

**包含示例**：
1. ✅ 基础对话
2. ✅ 流式输出
3. ✅ 多轮对话
4. ✅ 代码分析
5. ✅ 股票分析
6. ✅ 模型对比
7. ✅ 错误处理
8. ✅ 批量处理

**运行方式**：
```bash
python examples/claude_api_examples.py
```

### 交易分析示例

位置：`examples/trading_ai_examples.py`

**包含示例**：
1. ✅ 技术面分析
2. ✅ 基本面分析
3. ✅ 综合分析
4. ✅ 股票对比
5. ✅ 交易策略生成
6. ✅ 新闻影响分析

**运行方式**：
```bash
python examples/trading_ai_examples.py
```

### 快速代码片段

#### 1. 简单对话

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

#### 2. 流式输出

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

#### 3. 股票分析

```python
# 使用 TradingAnalystAI 类
from examples.trading_ai_examples import TradingAnalystAI

analyst = TradingAnalystAI()

technical_data = {
    "price": 1680.50,
    "change_pct": 2.3,
    "ma5": 1650.20,
    "ma10": 1620.30,
    # ... 更多指标
}

result = analyst.analyze_technical(
    stock_code="600519",
    stock_name="贵州茅台",
    technical_data=technical_data
)

print(result)
```

---

## ❓ 常见问题

### Q1: 为什么不能使用 ANTHROPIC_API_KEY？

**A:** 您的代理服务器使用 OpenAI 兼容格式，而不是原生 Anthropic API 格式。

- ❌ 错误：`ANTHROPIC_API_KEY` + `ANTHROPIC_BASE_URL`
- ✅ 正确：`OPENAI_API_KEY` + `OPENAI_BASE_URL`

### Q2: 出现 HTTP 403 错误？

**原因**：
1. 使用了错误的 API 格式
2. Base URL 配置错误（缺少 `/v1` 后缀）
3. API Key 错误

**解决**：
```bash
# 运行诊断工具
bash scripts/diagnose_claude_config.sh

# 检查环境变量
echo $OPENAI_API_KEY
echo $OPENAI_BASE_URL
```

### Q3: 如何切换模型？

```python
# 方法 1: 在代码中指定
response = client.chat.completions.create(
    model="claude-opus-4-5",  # 使用更强大的模型
    messages=[...]
)

# 方法 2: 环境变量
export OPENAI_MODEL="claude-opus-4-5"

# 方法 3: Claude Code 命令行
claude-code --model "claude-opus-4-5"
```

### Q4: 如何监控 Token 使用？

```python
response = client.chat.completions.create(...)

# 查看 token 使用
print(f"输入: {response.usage.prompt_tokens} tokens")
print(f"输出: {response.usage.completion_tokens} tokens")
print(f"总计: {response.usage.total_tokens} tokens")
```

### Q5: 代理服务器连接超时？

**排查步骤**：
```bash
# 1. 检查代理服务器
curl http://hh:8000/

# 2. 检查网络
ping hh

# 3. 运行诊断
bash scripts/diagnose_claude_config.sh
```

---

## 🎯 下一步

### 1. 安装 Python 依赖（可选）

```bash
# 安装 OpenAI SDK
pip install openai

# 安装环境变量管理
pip install python-dotenv

# 或使用项目 requirements
pip install -r requirements.txt
```

### 2. 配置 Shell 环境变量（推荐）

```bash
# 编辑配置文件
nano ~/.zshrc  # 或 ~/.bashrc

# 添加以下内容
export OPENAI_API_KEY="sk-e29d01f16f735a11dcee47f660541dd5bba9947c1e036cc2"
export OPENAI_BASE_URL="http://hh:8000/v1"

# 重新加载
source ~/.zshrc
```

### 3. 尝试示例代码

```bash
# 基础示例
python examples/claude_api_examples.py

# 交易分析示例
python examples/trading_ai_examples.py
```

### 4. 集成到项目

参考文档：
- [docs/CLAUDE_API_CONFIGURATION.md](docs/CLAUDE_API_CONFIGURATION.md) - 完整集成指南
- [examples/trading_ai_examples.py](examples/trading_ai_examples.py) - 实际应用示例

### 5. 探索高级功能

- **流式输出**：实时显示生成内容
- **对话历史管理**：维护上下文
- **成本跟踪**：监控 Token 使用
- **错误处理**：优雅处理 API 错误
- **批量处理**：高效处理多个请求

---

## 📊 使用统计

### 模型性能对比

| 模型 | 速度 | 质量 | 成本 | 推荐场景 |
|------|------|------|------|---------|
| claude-haiku-4-5 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | 💰 | 简单查询、代码补全 |
| claude-sonnet-4-5 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 💰💰 | 日常开发、代码审查 |
| claude-opus-4-5 | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 💰💰💰 | 架构设计、复杂问题 |

### Token 使用参考

- **中文**：约 1.5-2 个字符 = 1 token
- **英文**：约 4 个字符 = 1 token
- **代码**：约 3-4 个字符 = 1 token

**示例**：
- "你好" ≈ 2-3 tokens
- "Hello" ≈ 1 token
- 一段 100 行的 Python 代码 ≈ 300-400 tokens

---

## 🔒 安全提示

### API Key 保护

- ✅ 使用环境变量存储
- ✅ `.env` 文件已在 `.gitignore` 中
- ✅ 不要在代码中硬编码
- ✅ 不要提交到 Git
- ✅ 定期轮换密钥

### 访问控制

```python
# 好的做法
api_key = os.getenv("OPENAI_API_KEY")
if not api_key:
    raise ValueError("未设置 API Key")

# 日志中隐藏敏感信息
logging.info(f"API Key: {api_key[:10]}...{api_key[-4:]}")
```

---

## 📖 相关资源

### 项目文档

- [README.md](README.md) - 项目主文档
- [docs/configuration_guide.md](docs/configuration_guide.md) - 配置指南
- [docs/AGGREGATOR_SUPPORT.md](docs/AGGREGATOR_SUPPORT.md) - 聚合渠道支持

### 官方文档

- [OpenAI API 文档](https://platform.openai.com/docs/api-reference)
- [Anthropic API 文档](https://docs.anthropic.com/)
- [Claude Code GitHub](https://github.com/anthropics/claude-code)

### 社区资源

- [OpenAI Python SDK](https://github.com/openai/openai-python)
- [LangChain 文档](https://python.langchain.com/)

---

## 🎉 总结

### ✅ 已完成

1. ✅ 配置 `.env` 文件
2. ✅ 测试 API 连接
3. ✅ 验证所有模型
4. ✅ 创建测试脚本
5. ✅ 编写完整文档
6. ✅ 提供代码示例
7. ✅ 配置 Shell 环境

### 🚀 可以开始使用

您的 Claude API 配置已完成，现在可以：

- ✅ 使用 Claude Code CLI 进行开发
- ✅ 在 Python 项目中调用 Claude API
- ✅ 使用三种不同性能级别的模型
- ✅ 运行测试脚本验证配置
- ✅ 参考示例代码快速上手

### 💡 推荐阅读顺序

1. **[CLAUDE_QUICK_START.md](CLAUDE_QUICK_START.md)** - 快速上手
2. **运行测试脚本** - 验证配置
3. **[examples/claude_api_examples.py](examples/claude_api_examples.py)** - 学习基础用法
4. **[examples/trading_ai_examples.py](examples/trading_ai_examples.py)** - 了解实际应用
5. **[docs/CLAUDE_API_CONFIGURATION.md](docs/CLAUDE_API_CONFIGURATION.md)** - 深入学习

---

**配置状态**: ✅ 完成
**测试状态**: ✅ 通过
**文档状态**: ✅ 完整
**可用性**: ✅ 立即可用

**最后更新**: 2026-01-03

如有任何问题，请参考相关文档或运行诊断工具。祝使用愉快！🎉
