#!/bin/bash

# TradingAgents-CN 本地运行脚本
# 用于启动后端和前端服务
# 参考文档: docs/deployment/v1.0.0-source-installation.md

set -e

echo "=========================================="
echo "  TradingAgents-CN 运行脚本"
echo "  版本: v1.0.0-preview"
echo "=========================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目根目录
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

# 默认配置
ACTION="start"
TARGET="all"
BACKEND_PORT=8000
FRONTEND_PORT=5173

show_help() {
    echo "用法: ./run.sh [命令] [选项]"
    echo ""
    echo "命令:"
    echo "  start          启动服务 (默认)"
    echo "  stop           停止服务"
    echo "  restart        重启服务"
    echo "  status         查看服务状态"
    echo "  logs           查看日志"
    echo ""
    echo "选项:"
    echo "  --backend      仅操作后端服务"
    echo "  --frontend     仅操作前端服务"
    echo "  -h, --help     显示帮助信息"
    echo ""
    echo "示例:"
    echo "  ./run.sh                 # 启动所有服务"
    echo "  ./run.sh --backend       # 仅启动后端"
    echo "  ./run.sh stop            # 停止所有服务"
    echo "  ./run.sh restart         # 重启所有服务"
    echo "  ./run.sh logs --backend  # 查看后端日志"
}

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        start)
            ACTION="start"
            shift
            ;;
        stop)
            ACTION="stop"
            shift
            ;;
        restart)
            ACTION="restart"
            shift
            ;;
        status)
            ACTION="status"
            shift
            ;;
        logs)
            ACTION="logs"
            shift
            ;;
        --backend)
            TARGET="backend"
            shift
            ;;
        --frontend)
            TARGET="frontend"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}未知参数: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# 检查 .env 文件
check_env() {
    if [ ! -f ".env" ]; then
        echo -e "${YELLOW}警告: .env 文件不存在${NC}"
        if [ -f ".env.example" ]; then
            echo -e "${YELLOW}正在从 .env.example 创建 .env 文件...${NC}"
            cp .env.example .env
            echo -e "${GREEN}✓ 已创建 .env 文件，请根据需要修改配置${NC}"
        fi
    fi
}

# 创建必要目录
create_dirs() {
    mkdir -p logs config data
}

# 检查数据库服务
check_databases() {
    local has_error=false

    # 检查 MongoDB
    if ! pgrep -x "mongod" > /dev/null; then
        echo -e "${RED}错误: MongoDB 服务未运行${NC}"
        echo -e "${YELLOW}  启动: brew services start mongodb-community${NC}"
        has_error=true
    fi

    # 检查 Redis
    if ! redis-cli ping &> /dev/null; then
        echo -e "${RED}错误: Redis 服务未运行${NC}"
        echo -e "${YELLOW}  启动: brew services start redis${NC}"
        has_error=true
    fi

    if [ "$has_error" = true ]; then
        echo ""
        echo -e "${YELLOW}请先启动数据库服务后再运行此脚本${NC}"
        exit 1
    fi
}

# 启动后端
start_backend() {
    echo -e "${BLUE}>>> 启动后端服务...${NC}"

    # 检查虚拟环境
    if [ ! -d "venv" ]; then
        echo -e "${RED}错误: 虚拟环境不存在，请先运行 ./build.sh${NC}"
        exit 1
    fi

    source venv/bin/activate

    # 检查是否已运行 (使用更灵活的匹配模式)
    if pgrep -fi "python.*-m app" > /dev/null || lsof -i :$BACKEND_PORT -P > /dev/null 2>&1; then
        echo -e "${YELLOW}后端服务已在运行${NC}"
        return
    fi

    # 使用官方推荐的启动方式: python -m app
    nohup python -m app > logs/backend.log 2>&1 &
    echo $! > .backend.pid

    # 等待服务启动并验证
    echo -e "  等待服务启动..."
    sleep 5

    # 检查进程是否存在 (使用更灵活的匹配模式)
    if pgrep -fi "python.*-m app" > /dev/null; then
        # 检查端口是否监听 (使用 -P 显示数字端口)
        if lsof -i :$BACKEND_PORT -P > /dev/null 2>&1; then
            # 测试 API 是否响应
            if curl -s http://localhost:$BACKEND_PORT/ > /dev/null 2>&1; then
                echo -e "${GREEN}✓ 后端服务已启动${NC}"
                echo -e "  API 地址: ${YELLOW}http://localhost:$BACKEND_PORT${NC}"
                echo -e "  API 文档: ${YELLOW}http://localhost:$BACKEND_PORT/docs${NC}"
                echo -e "  日志文件: ${YELLOW}logs/backend.log${NC}"
            else
                echo -e "${YELLOW}⚠ 后端服务正在启动中，请稍候...${NC}"
                echo -e "  提示: 可以运行 'tail -f logs/backend.log' 查看启动日志"
            fi
        else
            echo -e "${YELLOW}⚠ 后端进程已启动，但端口未监听${NC}"
            echo -e "  请查看日志: ${YELLOW}tail -f logs/backend.log${NC}"
        fi
    else
        echo -e "${RED}后端服务启动失败，请查看日志: logs/backend.log${NC}"
        echo ""
        echo -e "${YELLOW}常见问题:${NC}"
        echo -e "  1. 端口被占用: lsof -i :$BACKEND_PORT -P"
        echo -e "  2. 数据库未初始化: ./build.sh --init-db"
        echo -e "  3. 查看详细日志: tail -f logs/backend.log"
    fi
}

# 启动前端
start_frontend() {
    echo -e "${BLUE}>>> 启动前端服务...${NC}"

    cd "$PROJECT_DIR/frontend"

    # 检查是否已运行
    if pgrep -f "vite" > /dev/null; then
        echo -e "${YELLOW}前端服务已在运行${NC}"
        cd "$PROJECT_DIR"
        return
    fi

    # 启动前端（后台运行）
    if command -v yarn &> /dev/null; then
        nohup yarn dev > "$PROJECT_DIR/logs/frontend.log" 2>&1 &
    else
        nohup npm run dev > "$PROJECT_DIR/logs/frontend.log" 2>&1 &
    fi
    echo $! > "$PROJECT_DIR/.frontend.pid"

    cd "$PROJECT_DIR"

    sleep 3
    if pgrep -f "vite" > /dev/null; then
        echo -e "${GREEN}✓ 前端服务已启动${NC}"
        echo -e "  前端地址: ${YELLOW}http://localhost:$FRONTEND_PORT${NC}"
        echo -e "  日志文件: ${YELLOW}logs/frontend.log${NC}"
    else
        echo -e "${RED}前端服务启动失败，请查看日志: logs/frontend.log${NC}"
    fi
}

# 停止后端
stop_backend() {
    echo -e "${BLUE}>>> 停止后端服务...${NC}"

    if [ -f ".backend.pid" ]; then
        kill $(cat .backend.pid) 2>/dev/null || true
        rm -f .backend.pid
    fi

    pkill -f "uvicorn app.main:app" 2>/dev/null || true
    pkill -f "python -m app" 2>/dev/null || true
    echo -e "${GREEN}✓ 后端服务已停止${NC}"
}

# 停止前端
stop_frontend() {
    echo -e "${BLUE}>>> 停止前端服务...${NC}"

    if [ -f ".frontend.pid" ]; then
        kill $(cat .frontend.pid) 2>/dev/null || true
        rm -f .frontend.pid
    fi

    pkill -f "vite" 2>/dev/null || true
    echo -e "${GREEN}✓ 前端服务已停止${NC}"
}

# 查看状态
show_status() {
    echo -e "${BLUE}>>> 服务状态:${NC}"
    echo ""

    # MongoDB 状态
    if pgrep -x "mongod" > /dev/null; then
        echo -e "  MongoDB:    ${GREEN}运行中${NC}"
    else
        echo -e "  MongoDB:    ${RED}未运行${NC}"
    fi

    # Redis 状态
    if redis-cli ping &> /dev/null 2>&1; then
        echo -e "  Redis:      ${GREEN}运行中${NC}"
    else
        echo -e "  Redis:      ${RED}未运行${NC}"
    fi

    # 后端状态 (使用更灵活的匹配模式)
    if pgrep -fi "python.*-m app" > /dev/null; then
        # 检查端口是否监听 (使用 -P 显示数字端口)
        if lsof -i :$BACKEND_PORT -P > /dev/null 2>&1; then
            # 测试 API 是否响应
            if curl -s http://localhost:$BACKEND_PORT/ > /dev/null 2>&1; then
                echo -e "  后端服务:   ${GREEN}运行中${NC} (http://localhost:$BACKEND_PORT)"
            else
                echo -e "  后端服务:   ${YELLOW}启动中${NC} (进程存在但API未响应)"
            fi
        else
            echo -e "  后端服务:   ${YELLOW}启动中${NC} (进程存在但端口未监听)"
        fi
    else
        echo -e "  后端服务:   ${RED}未运行${NC}"
    fi

    # 前端状态
    if pgrep -f "vite" > /dev/null; then
        echo -e "  前端服务:   ${GREEN}运行中${NC} (http://localhost:$FRONTEND_PORT)"
    else
        echo -e "  前端服务:   ${RED}未运行${NC}"
    fi
}

# 查看日志
show_logs() {
    case $TARGET in
        backend)
            if [ -f "logs/backend.log" ]; then
                echo -e "${BLUE}>>> 后端日志 (Ctrl+C 退出):${NC}"
                tail -f logs/backend.log
            else
                echo -e "${YELLOW}后端日志文件不存在${NC}"
            fi
            ;;
        frontend)
            if [ -f "logs/frontend.log" ]; then
                echo -e "${BLUE}>>> 前端日志 (Ctrl+C 退出):${NC}"
                tail -f logs/frontend.log
            else
                echo -e "${YELLOW}前端日志文件不存在${NC}"
            fi
            ;;
        all)
            echo -e "${BLUE}>>> 查看日志:${NC}"
            echo -e "  后端日志: ${YELLOW}tail -f logs/backend.log${NC}"
            echo -e "  前端日志: ${YELLOW}tail -f logs/frontend.log${NC}"
            echo ""
            if [ -f "logs/backend.log" ]; then
                echo -e "${BLUE}>>> 后端最近日志:${NC}"
                tail -20 logs/backend.log
            fi
            ;;
    esac
}

# 主逻辑
echo ""

check_env
create_dirs

case $ACTION in
    start)
        check_databases
        case $TARGET in
            backend)
                start_backend
                ;;
            frontend)
                start_frontend
                ;;
            all)
                start_backend
                echo ""
                start_frontend
                ;;
        esac
        echo ""
        echo -e "${GREEN}=========================================="
        echo -e "服务已启动!"
        echo -e "==========================================${NC}"
        echo ""
        echo -e "默认登录账号: ${YELLOW}admin${NC}"
        echo -e "默认登录密码: ${YELLOW}admin123${NC}"
        echo ""
        echo -e "停止服务: ${YELLOW}./run.sh stop${NC}"
        echo -e "查看状态: ${YELLOW}./run.sh status${NC}"
        echo -e "查看日志: ${YELLOW}./run.sh logs${NC}"
        ;;
    stop)
        case $TARGET in
            backend)
                stop_backend
                ;;
            frontend)
                stop_frontend
                ;;
            all)
                stop_backend
                stop_frontend
                ;;
        esac
        ;;
    restart)
        case $TARGET in
            backend)
                stop_backend
                sleep 1
                check_databases
                start_backend
                ;;
            frontend)
                stop_frontend
                sleep 1
                start_frontend
                ;;
            all)
                stop_backend
                stop_frontend
                sleep 1
                check_databases
                start_backend
                echo ""
                start_frontend
                ;;
        esac
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
esac
