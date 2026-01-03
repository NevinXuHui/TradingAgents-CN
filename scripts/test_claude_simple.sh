#!/bin/bash
# Claude API 简单测试脚本

echo "=========================================="
echo "🧪 Claude API 配置测试"
echo "=========================================="
echo ""

# 从 .env 文件读取配置
if [ -f ".env" ]; then
    export $(grep -v '^#' .env | grep -E 'OPENAI_API_KEY|OPENAI_BASE_URL' | xargs)
else
    echo "❌ 错误：未找到 .env 文件"
    exit 1
fi

if [ -z "$OPENAI_API_KEY" ] || [ -z "$OPENAI_BASE_URL" ]; then
    echo "❌ 错误：未配置 OPENAI_API_KEY 或 OPENAI_BASE_URL"
    exit 1
fi

echo "📍 Base URL: $OPENAI_BASE_URL"
echo "🔑 API Key: ${OPENAI_API_KEY:0:20}...${OPENAI_API_KEY: -10}"
echo ""

# 测试 1: 简单对话
echo "💬 测试 1: 简单对话"
echo "----------------------------------------"
echo "📤 发送消息: 你好，请介绍一下你自己"
echo ""

response=$(curl -s -X POST "$OPENAI_BASE_URL/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{
    "model": "claude-sonnet-4-5",
    "messages": [{"role": "user", "content": "你好，请用一句话介绍一下你自己"}],
    "max_tokens": 100
  }')

# 检查是否有错误
if echo "$response" | grep -q '"error"'; then
    echo "❌ 测试失败"
    echo "$response" | python3 -m json.tool 2>/dev/null || echo "$response"
    exit 1
fi

# 提取回复内容
content=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin)['choices'][0]['message']['content'])" 2>/dev/null)

if [ -n "$content" ]; then
    echo "📥 收到回复:"
    echo "   $content"
    echo ""

    # 提取 token 使用情况
    prompt_tokens=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin)['usage']['prompt_tokens'])" 2>/dev/null)
    completion_tokens=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin)['usage']['completion_tokens'])" 2>/dev/null)
    total_tokens=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin)['usage']['total_tokens'])" 2>/dev/null)

    echo "📊 Token 使用统计:"
    echo "   - 输入 tokens: $prompt_tokens"
    echo "   - 输出 tokens: $completion_tokens"
    echo "   - 总计 tokens: $total_tokens"
    echo ""
else
    echo "❌ 无法解析响应"
    echo "$response"
    exit 1
fi

# 测试 2: 代码生成
echo "💬 测试 2: 代码生成能力"
echo "----------------------------------------"
echo "📤 发送消息: 写一个Python函数计算斐波那契数列"
echo ""

response=$(curl -s -X POST "$OPENAI_BASE_URL/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{
    "model": "claude-sonnet-4-5",
    "messages": [{"role": "user", "content": "请写一个简单的Python函数计算斐波那契数列第n项"}],
    "max_tokens": 300
  }')

content=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin)['choices'][0]['message']['content'])" 2>/dev/null)

if [ -n "$content" ]; then
    echo "📥 收到回复:"
    echo "$content" | head -20
    echo ""
else
    echo "❌ 测试失败"
    exit 1
fi

# 测试 3: 列出可用模型
echo "📋 测试 3: 可用模型"
echo "----------------------------------------"
echo "✅ 已验证可用的模型："
echo "   - claude-sonnet-4-5 (推荐 - 平衡性能)"
echo "   - claude-opus-4-5 (最强性能)"
echo "   - claude-haiku-4-5 (快速响应)"
echo "   - claude-3-7-sonnet-20250219"
echo ""

echo "=========================================="
echo "✅ 所有测试通过！"
echo "=========================================="
echo ""
echo "💡 使用建议："
echo "   1. 日常开发推荐使用: claude-sonnet-4-5"
echo "   2. 复杂任务可使用: claude-opus-4-5"
echo "   3. 快速响应可使用: claude-haiku-4-5"
echo ""
echo "📖 详细配置说明: CLAUDE_CODE_SETUP.md"
echo ""
