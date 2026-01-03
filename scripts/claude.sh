#!/bin/bash
# Claude CLI 启动脚本

# 设置项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 加载环境变量
if [ -f "$PROJECT_ROOT/.env" ]; then
    export $(grep -v '^#' "$PROJECT_ROOT/.env" | grep -E 'OPENAI_API_KEY|OPENAI_BASE_URL' | xargs)
fi

# 检查环境变量
if [ -z "$OPENAI_API_KEY" ] || [ -z "$OPENAI_BASE_URL" ]; then
    echo "❌ 错误：未配置 OPENAI_API_KEY 或 OPENAI_BASE_URL"
    echo "请检查 .env 文件配置"
    exit 1
fi

# 运行 Claude CLI
python3 "$PROJECT_ROOT/scripts/claude_cli.py" "$@"
