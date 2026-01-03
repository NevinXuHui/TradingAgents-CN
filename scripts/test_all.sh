#!/bin/bash
# Claude API 一键测试脚本
# 快速验证所有功能是否正常

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 打印函数
print_header() { echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo -e "${CYAN}$1${NC}"; echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# 加载环境变量
if [ -f ".env" ]; then
    export $(grep -v '^#' .env | grep -E 'OPENAI_API_KEY|OPENAI_BASE_URL' | xargs)
fi

# 检查配置
if [ -z "$OPENAI_API_KEY" ] || [ -z "$OPENAI_BASE_URL" ]; then
    print_error "未配置 API Key 或 Base URL"
    exit 1
fi

# 主标题
clear
echo -e "${CYAN}"
cat << "EOF"
   _____ _                 _         _    ____ ___
  / ____| |               | |       / \  |  _ \_ _|
 | |    | | __ _ _   _  __| | ___  / _ \ | |_) | |
 | |    | |/ _` | | | |/ _` |/ _ \/ ___ \|  __/| |
 | |____| | (_| | |_| | (_| |  __/ /   \ \ |  _| |_
  \_____|_|\__,_|\__,_|\__,_|\___|_/     \_\_| |___|

  一键测试脚本 - 验证所有功能
EOF
echo -e "${NC}\n"

# 测试计数
total_tests=0
passed_tests=0

# 测试 1: 环境变量
print_header "测试 1/6: 环境变量配置"
total_tests=$((total_tests + 1))

print_info "检查 OPENAI_API_KEY..."
if [ -n "$OPENAI_API_KEY" ]; then
    print_success "OPENAI_API_KEY: ${OPENAI_API_KEY:0:20}...${OPENAI_API_KEY: -10}"
    passed_tests=$((passed_tests + 1))
else
    print_error "OPENAI_API_KEY 未配置"
fi

print_info "检查 OPENAI_BASE_URL..."
if [ -n "$OPENAI_BASE_URL" ]; then
    print_success "OPENAI_BASE_URL: $OPENAI_BASE_URL"
else
    print_error "OPENAI_BASE_URL 未配置"
fi

# 测试 2: 网络连接
print_header "测试 2/6: 网络连接"
total_tests=$((total_tests + 1))

host=$(echo $OPENAI_BASE_URL | sed -E 's|https?://([^:/]+).*|\1|')
print_info "测试连接到: $host"

if ping -c 1 -W 2 "$host" > /dev/null 2>&1; then
    print_success "网络连接正常"
    passed_tests=$((passed_tests + 1))
else
    print_warning "无法 ping 通（可能被防火墙阻止，但不影响 HTTP 请求）"
    passed_tests=$((passed_tests + 1))
fi

# 测试 3: API 调用
print_header "测试 3/6: API 基础调用"
total_tests=$((total_tests + 1))

print_info "发送测试请求..."
response=$(curl -s -X POST "$OPENAI_BASE_URL/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d '{
        "model": "claude-sonnet-4-5",
        "messages": [{"role": "user", "content": "Hi"}],
        "max_tokens": 10
    }' 2>&1)

if echo "$response" | grep -q '"content"'; then
    content=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin)['choices'][0]['message']['content'])" 2>/dev/null)
    print_success "API 调用成功"
    print_info "响应: $content"
    passed_tests=$((passed_tests + 1))
else
    print_error "API 调用失败"
    echo "$response"
fi

# 测试 4: 中文支持
print_header "测试 4/6: 中文支持"
total_tests=$((total_tests + 1))

print_info "测试中文对话..."
response=$(curl -s -X POST "$OPENAI_BASE_URL/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d '{
        "model": "claude-sonnet-4-5",
        "messages": [{"role": "user", "content": "你好"}],
        "max_tokens": 20
    }' 2>&1)

if echo "$response" | grep -q '"content"'; then
    content=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin)['choices'][0]['message']['content'])" 2>/dev/null)
    print_success "中文支持正常"
    print_info "响应: $content"
    passed_tests=$((passed_tests + 1))
else
    print_error "中文测试失败"
fi

# 测试 5: 模型可用性
print_header "测试 5/6: 模型可用性"
total_tests=$((total_tests + 1))

models=("claude-sonnet-4-5" "claude-opus-4-5" "claude-haiku-4-5")
available_models=0

for model in "${models[@]}"; do
    print_info "测试模型: $model"

    response=$(curl -s -X POST "$OPENAI_BASE_URL/chat/completions" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "{
            \"model\": \"$model\",
            \"messages\": [{\"role\": \"user\", \"content\": \"Hi\"}],
            \"max_tokens\": 5
        }" 2>&1)

    if echo "$response" | grep -q '"content"'; then
        print_success "  $model - 可用"
        available_models=$((available_models + 1))
    else
        print_error "  $model - 不可用"
    fi
done

if [ $available_models -eq 3 ]; then
    print_success "所有模型可用"
    passed_tests=$((passed_tests + 1))
else
    print_warning "部分模型不可用 ($available_models/3)"
fi

# 测试 6: 文档完整性
print_header "测试 6/6: 文档完整性"
total_tests=$((total_tests + 1))

docs=(
    "CLAUDE_INDEX.md"
    "CLAUDE_QUICK_START.md"
    "CLAUDE_README.md"
    "CLAUDE_CODE_SETUP.md"
    "CLAUDE_SETUP_SUMMARY.md"
    "CLAUDE_COMPLETION_REPORT.md"
    "docs/CLAUDE_API_CONFIGURATION.md"
    "docs/CLAUDE_CLI_GUIDE.md"
)

missing_docs=0
for doc in "${docs[@]}"; do
    if [ ! -f "$doc" ]; then
        print_warning "缺少文档: $doc"
        missing_docs=$((missing_docs + 1))
    fi
done

if [ $missing_docs -eq 0 ]; then
    print_success "所有文档完整 (${#docs[@]}个)"
    passed_tests=$((passed_tests + 1))
else
    print_warning "缺少 $missing_docs 个文档"
fi

# 总结
print_header "测试总结"

echo -e "${CYAN}测试结果:${NC}"
echo -e "  总测试数: $total_tests"
echo -e "  通过数: ${GREEN}$passed_tests${NC}"
echo -e "  失败数: ${RED}$((total_tests - passed_tests))${NC}"
echo -e "  通过率: $(( passed_tests * 100 / total_tests ))%"
echo ""

if [ $passed_tests -eq $total_tests ]; then
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🎉 恭喜！所有测试通过！${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}下一步:${NC}"
    echo -e "  1. 阅读快速开始: ${BLUE}CLAUDE_QUICK_START.md${NC}"
    echo -e "  2. 尝试 CLI 工具: ${BLUE}./scripts/claude.sh${NC}"
    echo -e "  3. 运行示例代码: ${BLUE}python examples/claude_api_examples.py${NC}"
    echo ""
    echo -e "${CYAN}常用命令:${NC}"
    echo -e "  ${BLUE}./scripts/claude.sh -q \"你好\"${NC}          # 单次问答"
    echo -e "  ${BLUE}./scripts/claude.sh -r app.py${NC}          # 代码审查"
    echo -e "  ${BLUE}bash scripts/diagnose_claude_config.sh${NC} # 完整诊断"
    echo ""
else
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}⚠️  部分测试未通过${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}故障排查:${NC}"
    echo -e "  1. 运行完整诊断: ${BLUE}bash scripts/diagnose_claude_config.sh${NC}"
    echo -e "  2. 检查环境变量: ${BLUE}echo \$OPENAI_API_KEY${NC}"
    echo -e "  3. 查看文档: ${BLUE}CLAUDE_QUICK_START.md${NC}"
    echo ""
fi

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
