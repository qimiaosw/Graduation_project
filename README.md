# 企业绩效管理系统 (EPMS)

企业级绩效管理平台，支持考核周期管理、指标方案、目标下达、绩效评估、审批流转、申诉处理、改进计划等核心业务功能，并提供多因素辅助决策引擎。

## 技术栈

- 后端：Spring Boot 3.5 + JDK 21 + MyBatis-Plus 3.5.7 + JWT
- 前端：Vue 3 + Vite 5 + TypeScript + Element Plus + ECharts
- 数据库：MySQL 8.0
- 缓存：Redis 7.x
- API 文档：Knife4j 4.5.0

## 项目结构

```
D:\Graduation_project\
├─ backend\                 # Spring Boot 后端工程
│  ├─ src\main\java\com\epms\
│  │  ├─ common\           # 通用基础
│  │  ├─ config\           # 框架配置
│  │  ├─ security\         # 鉴权模块
│  │  ├─ infra\            # 基础设施
│  │  └─ modules\          # 业务模块
│  └─ src\main\resources\
│     └─ application.yml   # 应用配置
├─ frontend\               # Vue3 前端工程
│  ├─ src\
│  │  ├─ api\              # API 接口
│  │  ├─ views\            # 页面视图
│  │  ├─ components\       # 组件
│  │  ├─ stores\           # Pinia 状态
│  │  ├─ router\           # 路由
│  │  └─ utils\            # 工具
│  └─ package.json
├─ db\                     # 数据库脚本
│  ├─ schema.sql           # 建表 DDL
│  └─ seed.sql             # 初始化数据
├─ docs\                   # 施工规格文档
├─ data\files\             # 文件上传目录
└─ WORKLOG.md              # 工作日志
```

## 环境要求

- JDK 21+
- Node.js 20 LTS
- Maven 3.9+
- MySQL 8.0
- Redis 7.x

## 快速启动

### 1. 初始化数据库

```sql
-- 登录 MySQL
mysql -u root -p

-- 创建数据库
CREATE DATABASE epms CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

-- 执行建表脚本
source D:/Graduation_project/db/schema.sql

-- 导入种子数据
source D:/Graduation_project/db/seed.sql
```

### 2. 启动 Redis

```bash
# Windows (使用 WSL 或 Docker)
redis-server

# 或使用 Docker
docker run -d -p 6379:6379 redis:7
```

### 3. 启动后端

```bash
cd D:\Graduation_project\backend

# 使用 Maven 启动
mvn spring-boot:run

# 或先编译再运行
mvn clean package -DskipTests
java -jar target/epms-backend-1.0.0-SNAPSHOT.jar
```

后端启动成功后：
- 健康检查：http://localhost:8080/api/v1/health
- Knife4j 文档：http://localhost:8080/api/v1/doc.html

### 4. 启动前端

```bash
cd D:\Graduation_project\frontend

# 安装依赖
npm install

# 启动开发服务器
npm run dev
```

前端启动成功后访问：http://localhost:5173

### 5. 验证

打开浏览器访问 http://localhost:5173，应该能看到健康检查结果显示系统运行状态。

## 默认账号

种子数据中的默认账号（首次登录建议修改密码）：

| 角色 | 用户名 | 初始密码 |
|------|--------|----------|
| 管理员 | admin | Epms@123456 |
| HR 专员 | hr01 | Epms@123456 |
| 部门负责人 | manager01 | Epms@123456 |
| 员工 | employee01 | Epms@123456 |

## 演示数据

系统预置了 4 个典型绩效案例用于验证决策引擎：

- E1001：正常绩效 (B+)
- E1002：临界绩效 (边界验证)
- E1003：冲突绩效 (多约束同时触发)
- E1004：缺失数据 (MANUAL_REQUIRED)

详见 `db/seed.sql` 和 `docs/04-决策规则与验证.md`

## 功能模块

| 模块 | 说明 |
|------|------|
| 系统管理 | 用户、部门、角色、参数、消息、操作日志 |
| 绩效管理 | 周期、指标库、方案、目标、考评单、材料 |
| 审批流转 | 节点配置、任务分派、审批工作台 |
| 决策引擎 | 六因子计算、硬约束、分档、置信度 |
| 智能助手 | 方案起草、评价解释、异常巡检 |
| 看板统计 | 等级分布、部门排名、周期趋势 |

## 开发规范

- 后端遵循技术方案文档 (docs/01-技术方案.md)
- 数据库遵循数据模型文档 (docs/02-数据模型.md)
- 接口遵循状态机与接口契约文档 (docs/03-状态机与接口契约.md)
- 决策规则遵循决策规则与验证文档 (docs/04-决策规则与验证.md)

## 常见问题

### 1. 前端无法连接后端
检查后端是否已启动，以及 vite.config.ts 中的代理配置是否正确。

### 2. 数据库连接失败
确认 MySQL 服务已启动，检查 application.yml 中的数据库配置是否正确。

### 3. Redis 连接失败
确认 Redis 服务已启动，检查 application.yml 中的 Redis 配置。

### 4. Knife4j 文档无法访问
确认后端已启动，访问 http://localhost:8080/doc.html

## 许可证

仅供毕业设计演示使用
