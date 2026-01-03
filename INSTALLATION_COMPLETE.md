# TradingAgents-CN 安装配置完成报告

**生成时间**: 2026-01-03  
**系统版本**: v1.0.0-preview  
**环境**: macOS 26.2 (ARM64)

---

## ✅ 已完成的配置

### 1. 数据库安装和配置

#### MongoDB 8.0.17
- ✅ 已安装并运行 (端口 27017)
- ✅ 管理员账户: `admin` / `tradingagents123`
- ✅ 应用账户: `tradingagents_user` / `tradingagents123`
- ✅ 启用身份验证
- ✅ 连接字符串: `mongodb://admin:tradingagents123@localhost:27017/tradingagents?authSource=admin`

#### Redis 8.4.0
- ✅ 已安装并运行 (端口 6379)
- ✅ 密码: `tradingagents123`
- ✅ 连接字符串: `redis://:tradingagents123@localhost:6379/0`

### 2. 数据库初始化

- ✅ 创建 13 个集合
- ✅ 创建所有必需的索引
- ✅ 导入 54 个配置文档
- ✅ 创建默认管理员账户 (admin / admin123)

### 3. 环境变量配置

- ✅ .env 文件已配置
- ✅ 数据库连接已配置
- ✅ API 服务已配置

### 4. 服务启动

- ✅ MongoDB: 运行中
- ✅ Redis: 运行中
- ✅ 后端 API: 运行中 (http://localhost:8000)
- ✅ 前端应用: 运行中 (http://localhost:5173)

### 5. 脚本优化

#### run.sh 脚本
- ✅ 修复后端服务状态检测问题
- ✅ 支持大小写不敏感的进程匹配
- ✅ 区分"运行中"、"启动中"、"未运行"状态

#### build.sh 脚本
- ✅ 添加 `--install-db` 选项
- ✅ 自动安装和配置数据库
- ✅ 自动创建数据库用户

---

## 🔗 访问地址

- **前端应用**: http://localhost:5173
- **后端 API**: http://localhost:8000
- **API 文档**: http://localhost:8000/docs

**登录信息**:
- 用户名: `admin`
- 密码: `admin123`

---

## ⚠️ 待完成的配置

### 1. 大模型 API 密钥 (必需)

编辑 `.env` 文件,配置至少一个大模型 API 密钥:

```bash
# 推荐配置 DeepSeek
DEEPSEEK_API_KEY=sk-xxxxxxxxxxxxxxxx
DEEPSEEK_ENABLED=true

# 或配置阿里百炼
DASHSCOPE_API_KEY=sk-xxxxxxxxxxxxxxxx
```

**获取 API 密钥**:
- DeepSeek: https://platform.deepseek.com/
- 阿里百炼: https://dashscope.aliyun.com/

配置完成后重启后端服务:
```bash
./run.sh restart --backend
```

### 2. 生产环境安全密钥 (可选)

如果要部署到生产环境,请修改以下密钥:

```bash
# 生成强密钥
python -c "import secrets; print('JWT_SECRET=' + secrets.token_urlsafe(32))"
python -c "import secrets; print('CSRF_SECRET=' + secrets.token_urlsafe(32))"
```

---

## 📋 常用命令

### 服务管理

```bash
# 查看服务状态
./run.sh status

# 启动服务
./run.sh start

# 停止服务
./run.sh stop

# 重启服务
./run.sh restart

# 查看日志
./run.sh logs
./run.sh logs --backend
./run.sh logs --frontend
```

### 数据库管理

```bash
# 连接 MongoDB
mongosh "mongodb://admin:tradingagents123@localhost:27017/tradingagents?authSource=admin"

# 连接 Redis
redis-cli -a tradingagents123 --no-auth-warning

# 查看数据库服务状态
brew services list | grep -E "(mongodb|redis)"

# 重启数据库服务
brew services restart mongodb/brew/mongodb-community@8.0
brew services restart redis
```

### 构建和部署

```bash
# 完整构建
./build.sh

# 安装数据库
./build.sh --install-db

# 初始化数据库
./build.sh --init-db
```

---

## 🔧 故障排查

### 问题 1: 后端服务状态显示"启动中"

**解决方法**:
```bash
# 等待几秒后再次检查
sleep 5 && ./run.sh status

# 或查看日志
tail -f logs/backend.log
```

### 问题 2: 端口被占用

**解决方法**:
```bash
# 查看占用端口的进程
lsof -i :8000

# 停止服务
./run.sh stop
```

### 问题 3: 数据库连接失败

**解决方法**:
```bash
# 检查数据库服务状态
brew services list | grep -E "(mongodb|redis)"

# 启动数据库服务
brew services start mongodb/brew/mongodb-community@8.0
brew services start redis

# 测试连接
mongosh -u admin -p tradingagents123 --authenticationDatabase admin --eval "db.runCommand({ ping: 1 })"
redis-cli -a tradingagents123 --no-auth-warning ping
```

---

## 📚 相关文档

- 完整部署文档: `docs/deployment/v1.0.0-source-installation.md`
- 配置指南: `docs/configuration_guide.md`
- API 文档: http://localhost:8000/docs

---

## 🎉 下一步操作

1. **配置 API 密钥** (必需)
   ```bash
   nano .env
   # 配置 DEEPSEEK_API_KEY 或 DASHSCOPE_API_KEY
   ./run.sh restart --backend
   ```

2. **访问应用**
   - 打开浏览器访问: http://localhost:5173
   - 使用 admin / admin123 登录

3. **开始使用**
   - 查看 API 文档: http://localhost:8000/docs
   - 创建分析任务
   - 管理自选股

---

**祝您使用愉快! 🚀**
