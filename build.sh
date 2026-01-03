#!/bin/bash

# TradingAgents-CN 本地构建脚本
# 用于安装依赖和构建项目
# 参考文档: docs/deployment/v1.0.0-source-installation.md

set -e

echo "=========================================="
echo "  TradingAgents-CN 本地构建脚本"
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

# 解析参数
BUILD_TARGET="all"
SKIP_INSTALL=false
INIT_DB=false
INSTALL_DB=false

show_help() {
    echo "用法: ./build.sh [选项]"
    echo ""
    echo "选项:"
    echo "  --backend      仅构建后端"
    echo "  --frontend     仅构建前端"
    echo "  --skip-install 跳过依赖安装"
    echo "  --init-db      初始化数据库（导入配置和创建用户）"
    echo "  --install-db   安装并配置数据库（MongoDB 和 Redis）"
    echo "  -h, --help     显示帮助信息"
    echo ""
    echo "示例:"
    echo "  ./build.sh                    # 安装依赖并构建全部"
    echo "  ./build.sh --install-db       # 安装并配置数据库"
    echo "  ./build.sh --init-db          # 初始化数据库"
    echo "  ./build.sh --frontend         # 仅构建前端"
    echo "  ./build.sh --skip-install     # 跳过依赖安装"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --backend)
            BUILD_TARGET="backend"
            shift
            ;;
        --frontend)
            BUILD_TARGET="frontend"
            shift
            ;;
        --skip-install)
            SKIP_INSTALL=true
            shift
            ;;
        --init-db)
            INIT_DB=true
            shift
            ;;
        --install-db)
            INSTALL_DB=true
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

# 检查 Python 环境
check_python() {
    echo -e "${BLUE}>>> 检查 Python 环境...${NC}"

    # 优先使用 python3.10-3.12
    if command -v python3.10 &> /dev/null; then
        PYTHON_CMD="python3.10"
    elif command -v /opt/homebrew/bin/python3.10 &> /dev/null; then
        PYTHON_CMD="/opt/homebrew/bin/python3.10"
    elif command -v python3.11 &> /dev/null; then
        PYTHON_CMD="python3.11"
    elif command -v python3.12 &> /dev/null; then
        PYTHON_CMD="python3.12"
    elif command -v python3 &> /dev/null; then
        PYTHON_CMD="python3"
    else
        echo -e "${RED}错误: Python3 未安装${NC}"
        exit 1
    fi

    PYTHON_VERSION=$($PYTHON_CMD --version 2>&1 | cut -d' ' -f2)
    PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d'.' -f1)
    PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d'.' -f2)

    # 检查版本是否在 3.10-3.12 范围内
    if [[ "$PYTHON_MAJOR" -eq 3 && "$PYTHON_MINOR" -ge 10 && "$PYTHON_MINOR" -le 12 ]]; then
        echo -e "${GREEN}✓ Python 版本: $PYTHON_VERSION ($PYTHON_CMD)${NC}"
    else
        echo -e "${YELLOW}警告: Python 版本 $PYTHON_VERSION 可能不兼容，建议使用 3.10-3.12${NC}"
        echo -e "${YELLOW}  安装 Python 3.10: brew install python@3.10${NC}"
    fi
}

# 检查 Node.js 环境
check_node() {
    echo -e "${BLUE}>>> 检查 Node.js 环境...${NC}"
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        echo -e "${GREEN}✓ Node.js 版本: $NODE_VERSION${NC}"
    else
        echo -e "${RED}错误: Node.js 未安装${NC}"
        echo -e "${YELLOW}  安装: brew install node${NC}"
        exit 1
    fi

    if command -v yarn &> /dev/null; then
        YARN_VERSION=$(yarn --version)
        echo -e "${GREEN}✓ Yarn 版本: $YARN_VERSION${NC}"
    else
        echo -e "${YELLOW}提示: Yarn 未安装，将使用 npm${NC}"
    fi
}

# 检查数据库服务
check_databases() {
    echo -e "${BLUE}>>> 检查数据库服务...${NC}"

    # 检查 MongoDB
    if command -v mongosh &> /dev/null || command -v mongo &> /dev/null; then
        if pgrep -x "mongod" > /dev/null; then
            echo -e "${GREEN}✓ MongoDB 服务运行中${NC}"
        else
            echo -e "${YELLOW}警告: MongoDB 服务未运行${NC}"
            echo -e "${YELLOW}  启动: brew services start mongodb-community${NC}"
        fi
    else
        echo -e "${YELLOW}警告: MongoDB 未安装${NC}"
        echo -e "${YELLOW}  安装: brew tap mongodb/brew && brew install mongodb-community${NC}"
    fi

    # 检查 Redis
    if command -v redis-cli &> /dev/null; then
        if redis-cli ping &> /dev/null; then
            echo -e "${GREEN}✓ Redis 服务运行中${NC}"
        else
            echo -e "${YELLOW}警告: Redis 服务未运行${NC}"
            echo -e "${YELLOW}  启动: brew services start redis${NC}"
        fi
    else
        echo -e "${YELLOW}警告: Redis 未安装${NC}"
        echo -e "${YELLOW}  安装: brew install redis${NC}"
    fi
}

# 安装后端依赖
install_backend() {
    echo ""
    echo -e "${BLUE}>>> 安装后端依赖...${NC}"

    # 创建虚拟环境（如果不存在）
    if [ ! -d "venv" ]; then
        echo -e "${YELLOW}创建虚拟环境...${NC}"
        $PYTHON_CMD -m venv venv
    fi

    # 激活虚拟环境
    source venv/bin/activate

    # 升级 pip 并配置镜像
    echo -e "${YELLOW}配置 pip 镜像...${NC}"
    pip install --upgrade pip -q
    pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple 2>/dev/null || true

    # 安装依赖
    echo -e "${YELLOW}安装 Python 依赖（可能需要几分钟）...${NC}"
    pip install -e . -q

    echo -e "${GREEN}✓ 后端依赖安装完成${NC}"
}

# 安装前端依赖
install_frontend() {
    echo ""
    echo -e "${BLUE}>>> 安装前端依赖...${NC}"

    cd "$PROJECT_DIR/frontend"

    if command -v yarn &> /dev/null; then
        yarn install
    else
        npm install
    fi

    cd "$PROJECT_DIR"
    echo -e "${GREEN}✓ 前端依赖安装完成${NC}"
}

# 构建前端
build_frontend() {
    echo ""
    echo -e "${BLUE}>>> 构建前端...${NC}"

    cd "$PROJECT_DIR/frontend"

    # 跳过类型检查，直接构建（与 Dockerfile 一致）
    if command -v yarn &> /dev/null; then
        yarn vite build
    else
        npx vite build
    fi

    cd "$PROJECT_DIR"
    echo -e "${GREEN}✓ 前端构建完成${NC}"
    echo -e "  构建产物位于: ${YELLOW}frontend/dist/${NC}"
}

# 初始化数据库
init_database() {
    echo ""
    echo -e "${BLUE}>>> 初始化数据库...${NC}"

    # 激活虚拟环境
    if [ -d "venv" ]; then
        source venv/bin/activate
    else
        echo -e "${RED}错误: 虚拟环境不存在，请先运行 ./build.sh 安装依赖${NC}"
        exit 1
    fi

    # 检查初始化脚本
    if [ -f "scripts/import_config_and_create_user.py" ]; then
        echo -e "${YELLOW}执行数据库初始化脚本...${NC}"
        python scripts/import_config_and_create_user.py --host
        echo -e "${GREEN}✓ 数据库初始化完成${NC}"
        echo -e "  默认管理员账号: ${YELLOW}admin${NC}"
        echo -e "  默认管理员密码: ${YELLOW}admin123${NC}"
    else
        echo -e "${RED}错误: 初始化脚本不存在: scripts/import_config_and_create_user.py${NC}"
        exit 1
    fi
}

# 安装并配置数据库
install_databases() {
    echo ""
    echo -e "${BLUE}>>> 安装并配置数据库...${NC}"
    echo ""

    # 检查操作系统
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo -e "${RED}错误: 此脚本仅支持 macOS 系统${NC}"
        echo -e "${YELLOW}Linux 用户请参考文档手动安装数据库${NC}"
        exit 1
    fi

    # 检查 Homebrew
    if ! command -v brew &> /dev/null; then
        echo -e "${RED}错误: Homebrew 未安装${NC}"
        echo -e "${YELLOW}请先安装 Homebrew: https://brew.sh/${NC}"
        exit 1
    fi

    # 安装 MongoDB
    echo -e "${BLUE}>>> 安装 MongoDB...${NC}"
    if command -v mongosh &> /dev/null || command -v mongo &> /dev/null; then
        echo -e "${GREEN}✓ MongoDB 已安装${NC}"
    else
        echo -e "${YELLOW}正在安装 MongoDB Community Edition...${NC}"
        brew tap mongodb/brew
        brew install mongodb-community@8.0
        echo -e "${GREEN}✓ MongoDB 安装完成${NC}"
    fi

    # 启动 MongoDB
    echo -e "${YELLOW}启动 MongoDB 服务...${NC}"
    brew services start mongodb/brew/mongodb-community@8.0
    sleep 3

    # 创建 MongoDB 管理员用户
    echo -e "${YELLOW}创建 MongoDB 管理员用户...${NC}"
    mongosh << 'EOF'
use admin
db.createUser({
  user: "admin",
  pwd: "tradingagents123",
  roles: [
    { role: "userAdminAnyDatabase", db: "admin" },
    { role: "readWriteAnyDatabase", db: "admin" },
    { role: "dbAdminAnyDatabase", db: "admin" },
    { role: "clusterAdmin", db: "admin" }
  ]
})
EOF

    # 创建应用用户
    echo -e "${YELLOW}创建 MongoDB 应用用户...${NC}"
    mongosh "mongodb://admin:tradingagents123@localhost:27017/admin" << 'EOF'
use tradingagents
db.createUser({
  user: "tradingagents_user",
  pwd: "tradingagents123",
  roles: [
    { role: "readWrite", db: "tradingagents" }
  ]
})
EOF

    # 启用 MongoDB 身份验证
    echo -e "${YELLOW}配置 MongoDB 身份验证...${NC}"
    if ! grep -q "authorization: enabled" /opt/homebrew/etc/mongod.conf; then
        echo "security:" >> /opt/homebrew/etc/mongod.conf
        echo "  authorization: enabled" >> /opt/homebrew/etc/mongod.conf
        brew services restart mongodb/brew/mongodb-community@8.0
        sleep 3
    fi

    echo -e "${GREEN}✓ MongoDB 配置完成${NC}"
    echo -e "  管理员账户: ${YELLOW}admin / tradingagents123${NC}"
    echo -e "  应用账户: ${YELLOW}tradingagents_user / tradingagents123${NC}"
    echo ""

    # 安装 Redis
    echo -e "${BLUE}>>> 安装 Redis...${NC}"
    if command -v redis-cli &> /dev/null; then
        echo -e "${GREEN}✓ Redis 已安装${NC}"
    else
        echo -e "${YELLOW}正在安装 Redis...${NC}"
        brew install redis
        echo -e "${GREEN}✓ Redis 安装完成${NC}"
    fi

    # 配置 Redis 密码
    echo -e "${YELLOW}配置 Redis 密码...${NC}"
    if ! grep -q "^requirepass tradingagents123" /opt/homebrew/etc/redis.conf; then
        sed -i '' 's/^# requirepass foobared/requirepass tradingagents123/' /opt/homebrew/etc/redis.conf
    fi

    # 启动 Redis
    echo -e "${YELLOW}启动 Redis 服务...${NC}"
    brew services start redis
    sleep 2

    echo -e "${GREEN}✓ Redis 配置完成${NC}"
    echo -e "  密码: ${YELLOW}tradingagents123${NC}"
    echo ""

    # 验证数据库连接
    echo -e "${BLUE}>>> 验证数据库连接...${NC}"

    # 测试 MongoDB
    if mongosh "mongodb://admin:tradingagents123@localhost:27017/admin?authSource=admin" --quiet --eval "db.runCommand({ ping: 1 })" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ MongoDB 连接成功${NC}"
    else
        echo -e "${RED}✗ MongoDB 连接失败${NC}"
    fi

    # 测试 Redis
    if redis-cli -a tradingagents123 --no-auth-warning ping > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Redis 连接成功${NC}"
    else
        echo -e "${RED}✗ Redis 连接失败${NC}"
    fi

    echo ""
    echo -e "${GREEN}=========================================="
    echo -e "✓ 数据库安装和配置完成!"
    echo -e "==========================================${NC}"
    echo ""
    echo -e "数据库信息:"
    echo -e "  MongoDB:"
    echo -e "    - 端口: ${YELLOW}27017${NC}"
    echo -e "    - 管理员: ${YELLOW}admin / tradingagents123${NC}"
    echo -e "    - 应用用户: ${YELLOW}tradingagents_user / tradingagents123${NC}"
    echo -e "    - 连接字符串: ${YELLOW}mongodb://admin:tradingagents123@localhost:27017/tradingagents?authSource=admin${NC}"
    echo ""
    echo -e "  Redis:"
    echo -e "    - 端口: ${YELLOW}6379${NC}"
    echo -e "    - 密码: ${YELLOW}tradingagents123${NC}"
    echo -e "    - 连接字符串: ${YELLOW}redis://:tradingagents123@localhost:6379/0${NC}"
    echo ""
    echo -e "下一步操作:"
    echo -e "  1. 初始化数据库: ${YELLOW}./build.sh --init-db${NC}"
    echo -e "  2. 启动服务:     ${YELLOW}./run.sh${NC}"
    echo ""
}

# 创建必要目录
create_dirs() {
    mkdir -p logs config data
}

# 复制环境配置文件
setup_env() {
    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            echo -e "${YELLOW}创建 .env 配置文件...${NC}"
            cp .env.example .env
            echo -e "${GREEN}✓ 已创建 .env 文件，请根据需要修改配置${NC}"
        fi
    fi
}

# 主逻辑
echo ""

create_dirs
setup_env

# 如果是安装数据库
if [ "$INSTALL_DB" = true ]; then
    install_databases
    exit 0
fi

# 如果只是初始化数据库
if [ "$INIT_DB" = true ]; then
    check_databases
    init_database
    exit 0
fi

case $BUILD_TARGET in
    backend)
        check_python
        check_databases
        if [ "$SKIP_INSTALL" = false ]; then
            install_backend
        fi
        echo -e "${GREEN}✓ 后端准备完成${NC}"
        ;;
    frontend)
        check_node
        if [ "$SKIP_INSTALL" = false ]; then
            install_frontend
        fi
        build_frontend
        ;;
    all)
        check_python
        check_node
        check_databases
        if [ "$SKIP_INSTALL" = false ]; then
            install_backend
            install_frontend
        fi
        build_frontend
        ;;
esac

echo ""
echo "=========================================="
echo -e "${GREEN}✓ 构建完成!${NC}"
echo "=========================================="
echo ""
echo -e "下一步操作:"
echo -e "  1. 安装数据库: ${YELLOW}./build.sh --install-db${NC} (如果还未安装)"
echo -e "  2. 初始化数据库: ${YELLOW}./build.sh --init-db${NC}"
echo -e "  3. 启动服务:     ${YELLOW}./run.sh${NC}"
echo ""
