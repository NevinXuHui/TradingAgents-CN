# Claude CLI 使用指南

## 📋 简介

Claude CLI 是一个强大的命令行工具，让您可以在终端中直接使用 Claude API。

## 🚀 快速开始

### 基础用法

```bash
# 交互式对话
./scripts/claude.sh

# 或直接使用 Python
python3 scripts/claude_cli.py
```

### 单次问答

```bash
# 简单问答
./scripts/claude.sh -q "什么是 Python 装饰器？"

# 使用流式输出
./scripts/claude.sh -q "写一首关于编程的诗" --stream

# 使用不同模型
./scripts/claude.sh -m opus -q "设计一个高并发系统架构"
```

### 文件分析

```bash
# 分析文件
./scripts/claude.sh -f script.py

# 分析并回答问题
./scripts/claude.sh -f config.json -q "这个配置文件有什么问题？"
```

### 代码审查

```bash
# 审查代码
./scripts/claude.sh -r app.py

# 审查多个文件
./scripts/claude.sh -r src/main.py
./scripts/claude.sh -r tests/test_main.py
```

### 股票分析

```bash
# 分析股票
./scripts/claude.sh -s 600519
./scripts/claude.sh -s 000858
```

## 🎯 交互式模式

启动交互式对话：

```bash
./scripts/claude.sh
```

### 可用命令

在交互式模式中，您可以使用以下命令：

| 命令 | 说明 |
|------|------|
| `/help` | 显示帮助信息 |
| `/clear` | 清除对话历史 |
| `/model` | 切换模型 |
| `/save` | 保存对话到文件 |
| `/exit` | 退出程序 |

### 示例对话

```
你: 你好，请介绍一下你自己

Claude: 你好！我是Claude，一个由Anthropic开发的AI助手...

你: 能帮我写一个Python函数吗？

Claude: 当然可以！请告诉我你需要什么功能的函数...

你: /save
✅ 对话已保存到: conversations/conversation_TradingAgents-CN_2.json

你: /exit
再见！
```

## 🔧 模型选择

### 可用模型

| 模型 | 参数 | 特点 | 适用场景 |
|------|------|------|---------|
| Sonnet | `-m sonnet` | 平衡性能（默认） | 日常开发、代码审查 |
| Opus | `-m opus` | 最强性能 | 架构设计、复杂问题 |
| Haiku | `-m haiku` | 快速响应 | 简单查询、代码补全 |

### 使用示例

```bash
# 使用 Sonnet（默认）
./scripts/claude.sh -q "分析这段代码"

# 使用 Opus（复杂任务）
./scripts/claude.sh -m opus -q "设计一个分布式系统"

# 使用 Haiku（快速响应）
./scripts/claude.sh -m haiku -q "Python 如何读取文件？"
```

## 📝 实用示例

### 1. 代码生成

```bash
./scripts/claude.sh -q "写一个 Python 函数，实现快速排序算法"
```

### 2. 代码解释

```bash
./scripts/claude.sh -f complex_algorithm.py -q "请解释这段代码的工作原理"
```

### 3. Bug 诊断

```bash
./scripts/claude.sh -f buggy_code.py -q "这段代码有什么问题？如何修复？"
```

### 4. 代码优化

```bash
./scripts/claude.sh -r slow_function.py
```

### 5. 技术咨询

```bash
./scripts/claude.sh -q "在 Python 中，什么时候应该使用多线程，什么时候应该使用多进程？"
```

### 6. 股票分析

```bash
# 分析贵州茅台
./scripts/claude.sh -s 600519

# 分析五粮液
./scripts/claude.sh -s 000858
```

### 7. 文档生成

```bash
./scripts/claude.sh -f api.py -q "为这个 API 生成详细的文档"
```

### 8. 测试用例生成

```bash
./scripts/claude.sh -f calculator.py -q "为这个类生成完整的单元测试"
```

## 🎨 高级用法

### 1. 管道操作

```bash
# 分析 git diff
git diff | ./scripts/claude.sh -q "分析这些代码变更"

# 分析日志
tail -100 app.log | ./scripts/claude.sh -q "分析这些日志，找出问题"
```

### 2. 批量处理

```bash
# 审查所有 Python 文件
for file in src/*.py; do
    echo "审查: $file"
    ./scripts/claude.sh -r "$file"
done
```

### 3. 结果保存

```bash
# 保存分析结果
./scripts/claude.sh -f data.json > analysis_result.txt

# 保存代码审查结果
./scripts/claude.sh -r app.py > code_review.md
```

## 💡 最佳实践

### 1. 提问技巧

**好的提问**：
```bash
./scripts/claude.sh -q "请用 Python 实现一个 LRU 缓存，要求：1) 使用字典和双向链表 2) 时间复杂度 O(1) 3) 包含完整的注释"
```

**不好的提问**：
```bash
./scripts/claude.sh -q "写个缓存"
```

### 2. 代码审查

**完整审查**：
```bash
./scripts/claude.sh -r app.py
```

**针对性审查**：
```bash
./scripts/claude.sh -f app.py -q "这段代码有没有安全漏洞？"
```

### 3. 模型选择策略

```bash
# 简单问题 → Haiku（快）
./scripts/claude.sh -m haiku -q "Python 如何读取 CSV？"

# 日常开发 → Sonnet（平衡）
./scripts/claude.sh -m sonnet -r app.py

# 复杂设计 → Opus（强）
./scripts/claude.sh -m opus -q "设计一个高可用的微服务架构"
```

## 🔍 故障排查

### 问题 1: 命令未找到

```bash
# 确保脚本可执行
chmod +x scripts/claude.sh

# 使用完整路径
/Volumes/mac/TradingAgents-CN/scripts/claude.sh
```

### 问题 2: API 错误

```bash
# 检查环境变量
echo $OPENAI_API_KEY
echo $OPENAI_BASE_URL

# 运行诊断
bash scripts/diagnose_claude_config.sh
```

### 问题 3: Python 模块未找到

```bash
# 安装依赖
pip install openai

# 或使用项目虚拟环境
source venv/bin/activate
pip install -r requirements.txt
```

## 📊 使用统计

### Token 消耗参考

| 操作 | 预估 Token | 成本参考 |
|------|-----------|---------|
| 简单问答 | 50-200 | 💰 |
| 代码审查 | 500-2000 | 💰💰 |
| 文件分析 | 1000-4000 | 💰💰💰 |
| 交互对话（10轮） | 2000-8000 | 💰💰💰 |

### 性能对比

| 模型 | 响应速度 | 质量 | 适用场景 |
|------|---------|------|---------|
| Haiku | ⚡⚡⚡ | ⭐⭐⭐ | 快速查询 |
| Sonnet | ⚡⚡ | ⭐⭐⭐⭐ | 日常开发 |
| Opus | ⚡ | ⭐⭐⭐⭐⭐ | 复杂任务 |

## 🎓 学习资源

### 相关文档

- [CLAUDE_QUICK_START.md](../CLAUDE_QUICK_START.md) - 快速开始
- [CLAUDE_README.md](../CLAUDE_README.md) - 完整指南
- [docs/CLAUDE_API_CONFIGURATION.md](../docs/CLAUDE_API_CONFIGURATION.md) - 配置详解

### 代码示例

- [examples/claude_api_examples.py](../examples/claude_api_examples.py) - 基础示例
- [examples/trading_ai_examples.py](../examples/trading_ai_examples.py) - 交易分析

### 测试工具

- [scripts/test_claude_simple.sh](test_claude_simple.sh) - 简单测试
- [scripts/diagnose_claude_config.sh](diagnose_claude_config.sh) - 诊断工具

## 🔗 快捷方式

### 创建别名（可选）

在 `~/.zshrc` 或 `~/.bashrc` 中添加：

```bash
# Claude CLI 别名
alias claude='/Volumes/mac/TradingAgents-CN/scripts/claude.sh'
alias claude-opus='/Volumes/mac/TradingAgents-CN/scripts/claude.sh -m opus'
alias claude-haiku='/Volumes/mac/TradingAgents-CN/scripts/claude.sh -m haiku'
alias claude-review='/Volumes/mac/TradingAgents-CN/scripts/claude.sh -r'
```

重新加载配置：
```bash
source ~/.zshrc
```

使用别名：
```bash
# 直接使用
claude -q "你好"

# 使用 Opus
claude-opus -q "设计系统架构"

# 代码审查
claude-review app.py
```

## 📞 获取帮助

### 命令行帮助

```bash
# 查看帮助
./scripts/claude.sh --help

# 交互模式帮助
./scripts/claude.sh
> /help
```

### 文档

- 快速问题：查看 [CLAUDE_QUICK_START.md](../CLAUDE_QUICK_START.md)
- 详细配置：查看 [docs/CLAUDE_API_CONFIGURATION.md](../docs/CLAUDE_API_CONFIGURATION.md)
- 故障排查：运行 `bash scripts/diagnose_claude_config.sh`

### 社区

- GitHub Issues: [项目 Issues](https://github.com/your-repo/issues)
- 文档反馈: 欢迎提交 PR

---

**最后更新**: 2026-01-03
**版本**: 1.0.0

祝使用愉快！🎉
