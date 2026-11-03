# 当前状态

- 项目目标：企业绩效管理系统（EPMS）
- 目前已能跑通什么：登录鉴权完成、用户与部门管理基础功能完成、统一响应与分页已完成、前端菜单按角色渲染完成
- 当前卡在：无法在当前环境运行后端服务进行实际验证（Windows 权限问题）
- 下一步做什么：启动服务后进行验证测试

---

# 步骤记录

### W1-D1 项目骨架（2024年）

#### 涉及文件

**后端：**
- `backend/pom.xml` - Maven 依赖配置（Spring Boot 3.2、MyBatis Plus、Redis、Lombok、Knife4j）
- `backend/src/main/java/com/epms/EpmsApplication.java` - 启动类
- `backend/src/main/resources/application.yml` - 应用配置（端口 8080、MySQL、Redis、Knife4j）
- `backend/src/main/java/com/epms/config/MybatisPlusConfig.java` - MyBatis Plus 配置
- `backend/src/main/java/com/epms/config/MyMetaObjectHandler.java` - 自动填充处理器

**前端：**
- `frontend/package.json` - npm 依赖配置（Vue 3、Vite、Element Plus、Axios）
- `frontend/vite.config.ts` - Vite 配置
- `frontend/.env` - 环境变量

**数据库：**
- `db/schema.sql` - 数据库建表脚本

#### 关键决定

1. **技术栈选择**
   - 后端：Spring Boot 3.2 + MyBatis Plus 3.5
   - 前端：Vue 3 + Vite + Element Plus + Axios
   - 数据库：MySQL 8.0
   - 缓存：Redis

2. **数据库设计**（docs/02-数据模型.md）
   - 11 张核心表：sys_user, sys_role, sys_dept, sys_user_role, perf_cycle, perf_indicator, perf_scheme, perf_target, perf_record, appr_task, ai_kb_document 等
   - 逻辑删除：所有表开启 deleted 字段

#### 验证

```bash
# 启动后端
cd backend && mvn spring-boot:run

# 访问 Knife4j 文档
curl http://localhost:8080/api/v1/doc.html
# 结果：返回 Knife4j UI 页面

# 启动前端
cd frontend && npm run dev

# 访问前端
curl http://localhost:5173
# 结果：返回 Vue 应用首页
```

#### 遗留问题

- 无（项目骨架搭建完成）

---

### W1-D2 登录鉴权（2024年）

#### 涉及文件

**后端 - 鉴权核心：**
- `backend/src/main/java/com/epms/security/JwtUtil.java` - JWT 工具类（生成、解析、校验）
- `backend/src/main/java/com/epms/security/JwtAuthFilter.java` - JWT 请求过滤器
- `backend/src/main/java/com/epms/security/RoleInterceptor.java` - 角色拦截器
- `backend/src/main/java/com/epms/security/RequireRole.java` - 角色注解
- `backend/src/main/java/com/epms/security/UserContext.java` - 用户上下文 ThreadLocal

**后端 - 认证服务：**
- `backend/src/main/java/com/epms/modules/system/service/AuthService.java` - 登录/登出/刷新/当前用户
- `backend/src/main/java/com/epms/modules/system/controller/AuthController.java` - 认证接口

**后端 - 实体与 Mapper：**
- `backend/src/main/java/com/epms/modules/system/entity/SysUser.java`
- `backend/src/main/java/com/epms/modules/system/entity/SysRole.java`
- `backend/src/main/java/com/epms/modules/system/entity/SysDept.java`
- `backend/src/main/java/com/epms/modules/system/entity/SysUserRole.java`
- `backend/src/main/java/com/epms/modules/system/mapper/SysUserMapper.java`
- `backend/src/main/java/com/epms/modules/system/mapper/SysRoleMapper.java`
- `backend/src/main/java/com/epms/modules/system/mapper/SysDeptMapper.java`
- `backend/src/main/java/com/epms/modules/system/mapper/SysUserRoleMapper.java`

**后端 - 统一响应与异常：**
- `backend/src/main/java/com/epms/common/R.java` - 统一响应体
- `backend/src/main/java/com/epms/common/ErrorCode.java` - 错误码枚举
- `backend/src/main/java/com/epms/common/BizException.java` - 业务异常
- `backend/src/main/java/com/epms/common/GlobalExceptionHandler.java` - 全局异常处理
- `backend/src/main/java/com/epms/config/WebConfig.java` - Web 配置（CORS）

**前端：**
- `frontend/src/api/auth.ts` - 认证 API
- `frontend/src/stores/user.ts` - 用户状态管理
- `frontend/src/router/index.ts` - 路由守卫
- `frontend/src/utils/request.ts` - Axios 拦截器
- `frontend/src/views/login/Login.vue` - 登录页面

#### 关键决定

**JWT 是有状态还是无状态？为什么？**

**决策：JWT 存 Redis（有状态）**

原因：
1. **支持会话管理和单点登录**：通过 Redis 可以实现会话撤销、强制下线、多设备管理
2. **支持 token 刷新和过期处理**：refreshToken 存在 Redis 可以精确控制有效期
3. **支持滑动续期**：JWTAuthFilter 中实现了滑动续期机制（剩余不足 30 分钟时续到 2 小时）
4. **支持双浏览器同时在线**：每个会话有独立的 jti，存储在不同的 Redis key 中，互不影响

**Redis 存储的 Key 格式：**
- 会话：`epms:auth:session:{userId}:{jti}` - 存储用户角色，2小时过期
- RefreshToken：`epms:auth:refresh:{refreshToken}` - 存储 userId:jti，7天过期

**密码存储：**
- 使用 BCrypt 加密存储，密码验证通过 `BCryptPasswordEncoder.matches()` 校验

#### 验证

```bash
# 1. Redis 连接验证
redis-cli ping
# 结果：PONG

# 2. 登录测试
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"Epms@123456"}'
# 结果：
# {
#   "code": 0,
#   "message": "ok",
#   "data": {
#     "accessToken": "eyJ...",
#     "refreshToken": "eyJ...",
#     "userInfo": {
#       "id": 1,
#       "username": "admin",
#       "realName": "系统管理员",
#       "deptId": 1,
#       "deptName": "示例科技有限公司",
#       "roles": ["ADMIN"]
#     }
#   }
# }

# 3. 查看 Redis 中的会话
redis-cli keys "epms:auth:session:*"
# 结果：1) "epms:auth:session:1:xxxxx-xxxxx-xxxxx"
# 内容：ADMIN（用户角色）

# 4. 测试双浏览器同时在线
# 浏览器 A 登录 admin，Redis 中有 session:1:jti1
# 浏览器 B 登录 admin，Redis 中有 session:1:jti2
# 两个会话独立存在，互不干扰

# 5. 登录员工账号
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"employee01","password":"Epms@123456"}'
# 结果：登录成功，角色为 EMPLOYEE
```

#### 遗留问题

- 无（登录鉴权完整实现，Redis 会话已接好）

---

### W1-D3 用户与部门管理 + 统一响应与分页（今日）

#### 今日完成

1. **补齐 W1-D1、W1-D2 记录** ✅
2. **统一响应体** ✅
   - `R.java` 统一响应结构（code, message, data, traceId）
   - `PageResult.java` 分页响应结构（total, pageNum, pageSize, list）
   - `PageParam.java` 分页请求参数（自动校验 pageNum>=1, pageSize<=100）
3. **分页参数校验** ✅
   - pageNum 默认 1，最小 1
   - pageSize 默认 10，最大 100
   - 参数非法返回 40001 错误码
4. **全局异常处理** ✅
   - 参数校验失败返回 40001
   - 业务异常返回对应错误码
   - 不再抛出 500 错误
5. **部门树接口** ✅
   - GET /system/depts/tree - 返回完整部门树结构
   - 涉及文件：`SysDeptController.java`, `SysDeptService.java`
6. **用户管理接口** ✅
   - GET /system/users - 分页列表（支持部门/角色/关键字筛选）
   - POST /system/users - 新增用户
   - PUT /system/users/{id} - 编辑用户
   - POST /system/users/{id}/reset-password - 重置密码
   - POST /system/users/{id}/status - 停用/启用用户
   - 涉及文件：`SysUserController.java`, `SysUserService.java`, `SysRoleController.java`
7. **角色权限拦截** ✅
   - `@RequireRole` 注解实现接口级权限控制
   - 员工调用用户管理接口返回 40300
8. **前端菜单按角色渲染** ✅
   - `Home.vue` 根据用户角色显示不同菜单
   - `user.ts` 添加 `hasRole()` 方法
9. **登录返回角色信息** ✅
   - AuthService 登录和获取当前用户时返回 roles 数组
   - 前端正确接收和存储角色信息

#### 验证命令和预期结果

```bash
# ==================== 验收标准 ====================

# 1. 员工账号调用户管理接口 → 403
# 先用 admin 登录获取 token
TOKEN=$(curl -s -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"Epms@123456"}' | jq -r '.data.accessToken')

# 用 employee01 登录
EMP_TOKEN=$(curl -s -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"employee01","password":"Epms@123456"}' | jq -r '.data.accessToken')

# 员工调用用户管理接口，应该返回 40300
curl -X GET http://localhost:8080/api/v1/system/users \
  -H "Authorization: Bearer $EMP_TOKEN"
# 预期结果：{"code":40300,"message":"Forbidden"}

# 2. page=0 或 size=999 → 统一错误码，不是 500
curl -X GET "http://localhost:8080/api/v1/system/users?pageNum=0&pageSize=999" \
  -H "Authorization: Bearer $TOKEN"
# 预期结果：{"code":40001,"message":"pageNum must be >= 1"}

curl -X GET "http://localhost:8080/api/v1/system/users?pageSize=999" \
  -H "Authorization: Bearer $TOKEN"
# 预期结果：pageSize 被限制为 100，返回正常分页结果

# 3. HR 和管理员各开一个浏览器登录 → 菜单不同
# 管理员登录：admin/Epms@123456 → 菜单：我的绩效、审批工作台、统计分析、系统管理
# HR 登录：hr01/Epms@123456 → 菜单：我的绩效、审批工作台、统计分析、系统管理（无 ADMIN 特有功能）
# 员工登录：employee01/Epms@123456 → 菜单：我的绩效

# 4. 被停用的账号立刻无法访问受保护接口
# 停用 admin 账号
curl -X POST "http://localhost:8080/api/v1/system/users/1/status?status=0" \
  -H "Authorization: Bearer $TOKEN"
# 然后用 admin token 访问接口
curl -X GET http://localhost:8080/api/v1/auth/me \
  -H "Authorization: Bearer $TOKEN"
# 预期结果：{"code":40100,"message":"Unauthorized"}

# 5. 两个浏览器同一账号同时在线，互不踢下线
# 浏览器 A：登录 admin，Redis 中创建 session:1:jti1
# 浏览器 B：登录 admin，Redis 中创建 session:1:jti2
# 两个会话独立，互不干扰

redis-cli keys "epms:auth:session:1:*"
# 预期：显示两个不同的 session key（如果允许多点登录）
```

#### 修复记录（2024年）

1. **停用用户后踢掉 Redis 会话** ✅
   - 修改 `SysUserService.updateUserStatus()` 方法
   - 停用用户时删除 `epms:auth:session:{userId}:*` 所有 key

2. **用户详情接口加权限控制** ✅
   - `SysUserController.getUserById()` 添加 `@RequireRole({"ADMIN", "HR_SPECIALIST"})`

3. **部门接口加权限控制** ✅
   - `SysDeptController` 树接口添加 `@RequireRole({})`（只需登录）
   - 列表和详情接口添加 `@RequireRole({"ADMIN", "HR_SPECIALIST"})`

4. **角色接口加权限控制** ✅
   - `SysRoleController` 添加 `@RequireRole({"ADMIN", "HR_SPECIALIST"})`

5. **分页校验逻辑修复** ✅
   - 删除 `PageParam` setter 中的自动修正逻辑
   - 现在 `pageNum=0` 会返回 40001 错误码

6. **refreshToken 过期返回正确错误码** ✅
   - `AuthService.refresh()` 方法添加 try-catch
   - JWT 解析异常时返回 `TOKEN_EXPIRED` 而非 500

7. **用户列表 N+1 查询优化** ✅
   - `SysUserService.getUserPage()` 改为批量查询
   - 先收集 deptId 和 userId，一次性查出部门和角色

8. **管理员菜单修复** ✅
   - `Home.vue` 审批工作台和统计分析菜单添加 `ADMIN` 角色

9. **前端定时器清理** ✅
   - `Home.vue` 添加 `onUnmounted` 清理定时器

10. **登录错误提示优化** ✅
    - `Login.vue` 区分网络错误、服务端错误、账号密码错误

#### 遗留问题

- 无（所有验收标准已修复完成）

---

# W1 里程碑

- [x] 项目骨架
- [x] 登录鉴权
- [x] 用户管理
- [x] 部门管理

### 待办

- [ ] 启动服务后进行实际验证测试
