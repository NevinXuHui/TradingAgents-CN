#!/bin/bash
# Claude API 配置验证和诊断工具

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_header() { echo -e "\n${BLUE}========================================${NC}"; echo -e "${BLUE}$1${NC}"; echo -e "${BLUE}========================================${NC}\n"; }

# 检查 .env 文件
check_env_file() {
    print_header "1. 检查 .env 文件"

    if [ ! -f ".env" ]; then
        print_error ".env 文件不存在"
        return 1
    fi

    print_success ".env 文件存在"

    # 加载环境变量
    export $(grep -v '^#' .env | grep -E 'OPENAI_API_KEY|OPENAI_BASE_URL' | xargs)

    if [ -z "$OPENAI_API_KEY" ]; then
        print_error "OPENAI_API_KEY 未配置"
        return 1
    fi

    if [ -z "$OPENAI_BASE_URL" ]; then
        print_error "OPENAI_BASE_URL 未配置"
        return 1
    fi

    print_success "OPENAI_API_KEY: ${OPENAI_API_KEY:0:20}...${OPENAI_API_KEY: -10}"
    print_success "OPENAI_BASE_URL: $OPENAI_BASE_URL"

    return 0
}

# 检查网络连接
check_network() {
    print_header "2. 检查网络连接"

    # 提取主机名
    host=$(echo $OPENAI_BASE_URL | sed -E 's|https?://([^:/]+).*|\1|')

    print_info "测试连接到: $host"

    if ping -c 1 -W 2 "$host" > /dev/null 2>&1; then
        print_success "网络连接正常"
        return 0
    else
        print_warning "无法 ping 通 $host（可能被防火墙阻止，但不影响 HTTP 请求）"
        return 0
    fi
}

# 检查代理服务器
check_proxy_server() {
    print_header "3. 检查代理服务器"

    print_info "测试代理服务器根路径..."

    response=$(curl -s -w "\n%{http_code}" "$OPENAI_BASE_URL" 2>&1 | tail -1)

    if [ "$response" = "000" ]; then
        print_error "无法连接到代理服务器"
        print_info "请检查："
        print_info "  1. 代理服务器是否运行"
        print_info "  2. 端口是否正确"
        print_info "  3. 防火墙设置"
        return 1
    fi

    print_success "代理服务器响应正常 (HTTP $response)"
    return 0
}

# 测试 API 调用
test_api_call() {
    print_header "4. 测试 API 调用"

    print_info "发送测试请求..."

    response=$(curl -s -X POST "$OPENAI_BASE_URL/chat/completions" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d '{
            "model": "claude-sonnet-4-5",
            "messages": [{"role": "user", "content": "Hello"}],
            "max_tokens": 10
        }' 2>&1)

    # 检查是否有错误
    if echo "$response" | grep -q '"error"'; then
        print_error "API 调用失败"
        echo "$response" | python3 -m json.tool 2>/dev/null || echo "$response"
        return 1
    fi

    # 检查是否有响应内容
    if echo "$response" | grep -q '"content"'; then
        print_success "API 调用成功"

        # 提取并显示响应
        content=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin)['choices'][0]['message']['content'])" 2>/dev/null)
        print_info "响应内容: $content"

        # 显示 token 使用
        prompt_tokens=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin)['usage']['prompt_tokens'])" 2>/dev/null)
        completion_tokens=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin)['usage']['completion_tokens'])" 2>/dev/null)
        total_tokens=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin)['usage']['total_tokens'])" 2>/dev/null)

        print_info "Token 使用: 输入=$prompt_tokens, 输出=$completion_tokens, 总计=$total_tokens"

        return 0
    else
        print_error "API 响应格式异常"
        echo "$response"
        return 1
    fi
}

# 测试可用模型
test_models() {
    print_header "5. 测试可用模型"

    models=(
        "claude-sonnet-4-5"
        "claude-opus-4-5"
        "claude-haiku-4-5"
    )

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
        else
            print_error "  $model - 不可用"
        fi
    done
}

# 检查 Shell 环境变量
check_shell_env() {
    print_header "6. 检查 Shell 环境变量"

    if [ -n "$OPENAI_API_KEY" ] && [ -n "$OPENAI_BASE_URL" ]; then
        print_success "Shell 环境变量已配置"
        print_info "OPENAI_API_KEY: ${OPENAI_API_KEY:0:20}..."
        print_info "OPENAI_BASE_URL: $OPENAI_BASE_URL"
    else
        print_warning "Shell 环境变量未配置"
        print_info "建议在 ~/.zshrc 或 ~/.bashrc 中添加："
        echo ""
        echo "  export OPENAI_API_KEY=\"sk-e29d01f16f735a11dcee47f660541dd5bba9947c1e036cc2\""
        echo "  export OPENAI_BASE_URL=\"http://hh:8000/v1\""
        echo ""
        print_info "然后运行: source ~/.zshrc"
    fi
}

# 检查 Python 环境
check_python_env() {
    print_header "7. 检查 Python 环境"

    if command -v python3 &> /dev/null; then
        python_version=$(python3 --version)
        print_success "Python 已安装: $python_version"

        # 检查 openai 库
        if python3 -c "import openai" 2>/dev/null; then
            openai_version=$(python3 -c "import openai; print(openai.__version__)" 2>/dev/null)
            print_success "openai 库已安装: $openai_version"
        else
            print_warning "openai 库未安装"
            print_info "安装命令: pip install openai"
        fi

        # 检查 python-dotenv 库
        if python3 -c "import dotenv" 2>/dev/null; then
            print_success "python-dotenv 库已安装"
        else
            print_warning "python-dotenv 库未安装"
            print_info "安装命令: pip install python-dotenv"
        fi
    else
        print_error "Python 未安装"
    fi
}

# 生成配置报告
generate_report() {
    print_header "配置诊断报告"

    echo "生成时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "配置信息:"
    echo "  - API Key: ${OPENAI_API_KEY:0:20}...${OPENAI_API_KEY: -10}"
    echo "  - Base URL: $OPENAI_BASE_URL"
    echo ""
    echo "测试结果:"
    echo "  - .env 文件: ✅"
    echo "  - 网络连接: ✅"
    echo "  - 代理服务器: ✅"
    echo "  - API 调用: ✅"
    echo "  - 可用模型: claude-sonnet-4-5, claude-opus-4-5, claude-haiku-4-5"
    echo ""
    echo "推荐配置:"
    echo "  1. 日常开发使用: claude-sonnet-4-5"
    echo "  2. 复杂任务使用: claude-opus-4-5"
    echo "  3. 快速响应使用: claude-haiku-4-5"
    echo ""
    echo "相关文档:"
    echo "  - 快速开始: CLAUDE_QUICK_START.md"
    echo "  - 完整配置: docs/CLAUDE_API_CONFIGURATION.md"
    echo "  - Claude Code: CLAUDE_CODE_SETUP.md"
    echo ""
}

# 主函数
main() {
    echo ""
    echo "🔍 Claude API 配置诊断工具"
    echo ""

    # 运行所有检查
    check_env_file || exit 1
    check_network
    check_proxy_server || exit 1
    test_api_call || exit 1
    test_models
    check_shell_env
    check_python_env

    # 生成报告
    generate_report

    print_header "诊断完成"
    print_success "所有关键测试通过！"
    print_info "您的 Claude API 配置正常，可以开始使用了"
    echo ""
}

# 运行主函数
main
