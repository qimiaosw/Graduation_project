-- =============================================================
-- EPMS 企业绩效管理系统 - 建库建表脚本
-- 依据：docs/02-数据模型.md
-- 数据库：MySQL 8.0
-- 执行方式：mysql -u root -p < D:/Graduation_project/db/schema.sql
--          或在 Navicat / 命令行中 source 本文件
-- 说明：不建物理外键，引用完整性由应用层（Service）保证
-- =============================================================

CREATE DATABASE IF NOT EXISTS epms
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_0900_ai_ci;

USE epms;
SET NAMES utf8mb4;

-- -------------------------------------------------------------
-- 1. 系统域
-- -------------------------------------------------------------

-- 1.1 部门表（树形）
CREATE TABLE sys_dept (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    parent_id BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '父部门 id，0=根',
    ancestors VARCHAR(500) NOT NULL DEFAULT '0' COMMENT '祖先链，逗号分隔，如 0,1,3',
    dept_code VARCHAR(32) NOT NULL COMMENT '部门编码',
    dept_name VARCHAR(64) NOT NULL COMMENT '部门名称',
    leader_user_id BIGINT UNSIGNED NULL COMMENT '部门负责人 user_id（sys_user.id）',
    sort_no INT NOT NULL DEFAULT 0 COMMENT '展示排序',
    status TINYINT NOT NULL DEFAULT 1 COMMENT '1 启用 0 停用',
    create_by BIGINT UNSIGNED NULL COMMENT '创建人 user_id（0=系统）',
    update_by BIGINT UNSIGNED NULL COMMENT '最后修改人 user_id',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT(1) NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 已删',
    PRIMARY KEY (id),
    UNIQUE KEY uk_dept_code (dept_code),
    KEY idx_parent (parent_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='部门表';

-- 1.2 角色表
CREATE TABLE sys_role (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    role_code VARCHAR(32) NOT NULL COMMENT '角色码：EMPLOYEE/DEPT_MANAGER/HR_SPECIALIST/EXECUTIVE/ADMIN',
    role_name VARCHAR(64) NOT NULL COMMENT '显示名',
    data_scope VARCHAR(16) NOT NULL DEFAULT 'SELF' COMMENT '数据范围：SELF 本人 / DEPT_TREE 部门子树 / ALL 全公司',
    status TINYINT NOT NULL DEFAULT 1 COMMENT '1 启用 0 停用',
    remark VARCHAR(255) NULL COMMENT '备注',
    create_by BIGINT UNSIGNED NULL COMMENT '创建人 user_id',
    update_by BIGINT UNSIGNED NULL COMMENT '最后修改人 user_id',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT(1) NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 已删',
    PRIMARY KEY (id),
    UNIQUE KEY uk_role_code (role_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='角色表';

-- 1.3 用户表
CREATE TABLE sys_user (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    username VARCHAR(64) NOT NULL COMMENT '登录名',
    password_hash VARCHAR(100) NOT NULL COMMENT 'BCrypt 密文（cost=10）',
    real_name VARCHAR(64) NOT NULL COMMENT '姓名',
    employee_no VARCHAR(32) NOT NULL COMMENT '工号',
    dept_id BIGINT UNSIGNED NOT NULL COMMENT '所属部门（sys_dept.id）',
    position_title VARCHAR(64) NULL COMMENT '岗位/职务',
    mobile VARCHAR(20) NULL COMMENT '手机号',
    email VARCHAR(128) NULL COMMENT '邮箱',
    status TINYINT NOT NULL DEFAULT 1 COMMENT '1 在职 0 停用（停用即拒绝登录）',
    pwd_changed_at DATETIME NULL COMMENT '最近改密时间',
    last_login_at DATETIME NULL COMMENT '最近登录时间',
    last_login_ip VARCHAR(45) NULL COMMENT '最近登录 IP（兼容 IPv6）',
    create_by BIGINT UNSIGNED NULL COMMENT '创建人 user_id',
    update_by BIGINT UNSIGNED NULL COMMENT '最后修改人 user_id',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT(1) NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 已删',
    version INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
    PRIMARY KEY (id),
    UNIQUE KEY uk_username (username),
    UNIQUE KEY uk_employee_no (employee_no),
    KEY idx_dept (dept_id),
    KEY idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='用户表';

-- 1.4 用户角色关联表
CREATE TABLE sys_user_role (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    user_id BIGINT UNSIGNED NOT NULL COMMENT 'sys_user.id',
    role_id BIGINT UNSIGNED NOT NULL COMMENT 'sys_role.id',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (id),
    UNIQUE KEY uk_user_role (user_id, role_id),
    KEY idx_role (role_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='用户角色关联表';

-- 1.5 系统参数表
CREATE TABLE sys_config (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    config_key VARCHAR(128) NOT NULL COMMENT '参数键',
    config_value TEXT NULL COMMENT '参数值（布尔/数字也以字符串存，读取时转换）',
    value_type VARCHAR(16) NOT NULL DEFAULT 'STRING' COMMENT 'STRING/NUMBER/BOOLEAN/JSON',
    group_code VARCHAR(32) NOT NULL DEFAULT 'SYS' COMMENT '分组：SYS/LOGIN/REMIND/AI/ENGINE',
    remark VARCHAR(255) NULL COMMENT '中文说明',
    status TINYINT NOT NULL DEFAULT 1 COMMENT '1 启用',
    create_by BIGINT UNSIGNED NULL COMMENT '创建人 user_id',
    update_by BIGINT UNSIGNED NULL COMMENT '最后修改人 user_id',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT(1) NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 已删',
    PRIMARY KEY (id),
    UNIQUE KEY uk_config_key (config_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='系统参数表';

-- 1.6 站内消息表
CREATE TABLE sys_message (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    receiver_id BIGINT UNSIGNED NOT NULL COMMENT '接收人 user_id',
    title VARCHAR(128) NOT NULL COMMENT '标题',
    content VARCHAR(500) NOT NULL COMMENT '内容',
    biz_type VARCHAR(32) NOT NULL COMMENT '业务类型：APPROVAL_REMIND/APPEAL/PLAN/SYSTEM',
    biz_id BIGINT UNSIGNED NULL COMMENT '关联业务 id（如 appr_task.id）',
    is_read TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否已读',
    read_at DATETIME NULL COMMENT '阅读时间',
    create_by BIGINT UNSIGNED NULL COMMENT '创建人 user_id',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (id),
    KEY idx_receiver (receiver_id, is_read, created_at),
    KEY idx_biz (biz_type, biz_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='站内消息表（不可编辑删除）';

-- 1.7 操作日志表（AOP 自动写入，只增不改）
CREATE TABLE sys_operation_log (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    trace_id VARCHAR(64) NULL COMMENT '链路 id',
    user_id BIGINT UNSIGNED NULL COMMENT '操作人（登录失败时为空）',
    username VARCHAR(64) NULL COMMENT '操作人账号快照',
    module VARCHAR(32) NOT NULL COMMENT '模块：AUTH/CYCLE/SCHEME/TARGET/RECORD/APPROVAL/ENGINE/CONCLUSION/APPEAL/PLAN/AI/CONFIG',
    action VARCHAR(64) NOT NULL COMMENT '动作码，如 SUBMIT、DEPT_APPROVE',
    biz_type VARCHAR(32) NULL COMMENT '业务对象类型（如 PERF_RECORD）',
    biz_id VARCHAR(64) NULL COMMENT '业务对象 id（字符串兼容复合键）',
    request_method VARCHAR(8) NULL COMMENT 'GET/POST/PUT/DELETE',
    request_url VARCHAR(255) NULL COMMENT '请求路径（不含 query 明文敏感参数）',
    request_params TEXT NULL COMMENT '入参 JSON（密码/Token 字段脱敏）',
    before_snapshot JSON NULL COMMENT '变更前快照',
    after_snapshot JSON NULL COMMENT '变更后快照',
    result TINYINT NOT NULL COMMENT '1 成功 0 失败',
    error_msg VARCHAR(1000) NULL COMMENT '失败摘要',
    ip VARCHAR(45) NULL COMMENT '来源 IP',
    user_agent VARCHAR(255) NULL COMMENT 'UA',
    cost_ms INT NULL COMMENT '耗时毫秒',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (id),
    KEY idx_user_time (user_id, created_at),
    KEY idx_biz (biz_type, biz_id),
    KEY idx_module_time (module, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='操作日志表';

-- -------------------------------------------------------------
-- 2. 绩效配置域（周期 / 指标库 / 方案）
-- -------------------------------------------------------------

-- 2.1 考核周期表
CREATE TABLE perf_cycle (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    cycle_code VARCHAR(32) NOT NULL COMMENT '周期编码，如 2026-Q4',
    cycle_name VARCHAR(64) NOT NULL COMMENT '周期名称',
    cycle_type VARCHAR(16) NOT NULL COMMENT 'MONTH/QUARTER/YEAR/CUSTOM',
    start_date DATE NOT NULL COMMENT '周期开始日',
    end_date DATE NOT NULL COMMENT '周期结束日（须晚于开始日）',
    self_deadline DATETIME NOT NULL COMMENT '员工自评截止',
    manager_deadline DATETIME NOT NULL COMMENT '部门评审截止',
    hr_deadline DATETIME NOT NULL COMMENT 'HR 复核截止',
    final_deadline DATETIME NOT NULL COMMENT '终审截止',
    status VARCHAR(16) NOT NULL DEFAULT 'DRAFT' COMMENT 'DRAFT/PUBLISHED/FINISHED/ARCHIVED',
    published_at DATETIME NULL COMMENT '启动时间',
    finished_at DATETIME NULL COMMENT '结束时间',
    remark VARCHAR(255) NULL COMMENT '备注',
    create_by BIGINT UNSIGNED NULL COMMENT '创建人 user_id',
    update_by BIGINT UNSIGNED NULL COMMENT '最后修改人 user_id',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT(1) NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 已删',
    version INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
    PRIMARY KEY (id),
    UNIQUE KEY uk_cycle_code (cycle_code),
    KEY idx_status (status),
    KEY idx_type_time (cycle_type, start_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='考核周期表';

-- 2.2 指标库表
CREATE TABLE perf_indicator (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    indicator_code VARCHAR(32) NOT NULL COMMENT '指标编码，如 KPI-SALE-01',
    indicator_name VARCHAR(128) NOT NULL COMMENT '指标名称',
    category VARCHAR(16) NOT NULL COMMENT 'QUANTITATIVE 定量 / QUALITATIVE 定性',
    unit VARCHAR(16) NULL COMMENT '单位：%、万元、个、项、分等',
    default_factor_code VARCHAR(16) NOT NULL COMMENT '默认归属决策因子：F1-F6',
    data_source VARCHAR(128) NULL COMMENT '数据来源口径',
    scoring_desc VARCHAR(500) NULL COMMENT '计分口径文字说明',
    status TINYINT NOT NULL DEFAULT 1 COMMENT '1 可用 0 停用',
    create_by BIGINT UNSIGNED NULL COMMENT '创建人 user_id',
    update_by BIGINT UNSIGNED NULL COMMENT '最后修改人 user_id',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT(1) NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 已删',
    PRIMARY KEY (id),
    UNIQUE KEY uk_indicator_code (indicator_code),
    KEY idx_category (category),
    KEY idx_factor (default_factor_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='指标库表';

-- 2.3 指标方案表
CREATE TABLE perf_scheme (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    scheme_code VARCHAR(32) NOT NULL COMMENT '方案编码',
    scheme_name VARCHAR(128) NOT NULL COMMENT '方案名称',
    cycle_id BIGINT UNSIGNED NOT NULL COMMENT '所属周期（perf_cycle.id）',
    scope_type VARCHAR(16) NOT NULL COMMENT 'ALL 全员 / DEPT 按部门 / POSITION 按岗位',
    scope_value VARCHAR(64) NOT NULL COMMENT '作用域值：*、部门 id、岗位名称',
    rule_version INT NOT NULL DEFAULT 1 COMMENT '规则版本；每次发布 +1',
    total_weight DECIMAL(5,2) NOT NULL DEFAULT 0 COMMENT '指标项权重合计（发布前必须=100.00）',
    status VARCHAR(16) NOT NULL DEFAULT 'DRAFT' COMMENT 'DRAFT/PUBLISHED/CLOSED',
    published_at DATETIME NULL COMMENT '最近发布时间',
    remark VARCHAR(255) NULL COMMENT '备注',
    create_by BIGINT UNSIGNED NULL COMMENT '创建人 user_id',
    update_by BIGINT UNSIGNED NULL COMMENT '最后修改人 user_id',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT(1) NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 已删',
    version INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
    PRIMARY KEY (id),
    UNIQUE KEY uk_scheme_code (scheme_code),
    KEY idx_cycle (cycle_id),
    KEY idx_scope (scope_type, scope_value)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='指标方案表';

-- 2.4 方案指标项表
CREATE TABLE perf_scheme_item (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    scheme_id BIGINT UNSIGNED NOT NULL COMMENT '所属方案',
    indicator_id BIGINT UNSIGNED NOT NULL COMMENT '引用指标库',
    factor_code VARCHAR(16) NOT NULL COMMENT '本方案中归属的因子：F1-F6',
    weight DECIMAL(5,2) NOT NULL COMMENT '指标权重，同方案内合计=100.00',
    target_required TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否必填目标值',
    scoring_rule JSON NULL COMMENT '计分参数，如 {"rateCap":120,"scoreCap":100,"direction":"POSITIVE"}',
    sort_no INT NOT NULL DEFAULT 0 COMMENT '展示顺序',
    create_by BIGINT UNSIGNED NULL COMMENT '创建人 user_id',
    update_by BIGINT UNSIGNED NULL COMMENT '最后修改人 user_id',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT(1) NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 已删',
    PRIMARY KEY (id),
    UNIQUE KEY uk_scheme_indicator (scheme_id, indicator_id),
    KEY idx_factor (scheme_id, factor_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='方案指标项表';

-- -------------------------------------------------------------
-- 3. 决策规则配置域
-- -------------------------------------------------------------

-- 3.1 因子权重配置表
CREATE TABLE perf_factor_config (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    scheme_id BIGINT UNSIGNED NOT NULL COMMENT '所属方案',
    factor_code VARCHAR(16) NOT NULL COMMENT 'F1-F6',
    factor_name VARCHAR(64) NOT NULL COMMENT '因子名称快照',
    weight DECIMAL(5,2) NOT NULL COMMENT '因子权重，启用项合计必须=100.00',
    enabled TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否启用',
    calc_params JSON NULL COMMENT '计算参数，如 F4 的 {"deductPerEvent":10}',
    sort_no INT NOT NULL DEFAULT 0 COMMENT '因子顺序',
    create_by BIGINT UNSIGNED NULL COMMENT '创建人 user_id',
    update_by BIGINT UNSIGNED NULL COMMENT '最后修改人 user_id',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT(1) NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 已删',
    PRIMARY KEY (id),
    UNIQUE KEY uk_scheme_factor (scheme_id, factor_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='因子权重配置表';

-- 3.2 硬约束配置表
CREATE TABLE perf_hard_constraint (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    scheme_id BIGINT UNSIGNED NOT NULL COMMENT '所属方案',
    constraint_code VARCHAR(32) NOT NULL COMMENT 'HC_DISCIPLINE_VETO / HC_ATTENDANCE / HC_KPI_LOW / HC_DATA_MISSING / HC_SCORE_GAP',
    constraint_name VARCHAR(128) NOT NULL COMMENT '约束名称',
    threshold_value DECIMAL(6,2) NOT NULL COMMENT '阈值（语义随 code）',
    threshold_unit VARCHAR(8) NOT NULL COMMENT 'PERCENT 百分数值 / SCORE 分差',
    action_type VARCHAR(24) NOT NULL COMMENT 'FORCE_MANUAL / CEILING_GRADE / BOTH',
    ceiling_grade VARCHAR(16) NULL COMMENT '封顶等级（CEILING_GRADE/BOTH 时必填）',
    enabled TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否启用',
    remark VARCHAR(255) NULL COMMENT '口径说明',
    create_by BIGINT UNSIGNED NULL COMMENT '创建人 user_id',
    update_by BIGINT UNSIGNED NULL COMMENT '最后修改人 user_id',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT(1) NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 已删',
    PRIMARY KEY (id),
    UNIQUE KEY uk_scheme_hc (scheme_id, constraint_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='硬约束配置表';

-- 3.3 等级分档表
CREATE TABLE perf_grade_band (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    scheme_id BIGINT UNSIGNED NOT NULL COMMENT '所属方案',
    grade_code VARCHAR(16) NOT NULL COMMENT 'S/A/B_PLUS/B/C/D',
    grade_name VARCHAR(16) NOT NULL COMMENT '显示名（卓越/优秀/良好+/良好/待改进/不合格）',
    min_score DECIMAL(5,2) NOT NULL COMMENT '下限（含）',
    max_score DECIMAL(5,2) NOT NULL COMMENT '上限（不含；S 档用 999.00）',
    sort_no INT NOT NULL COMMENT '从高到低排序',
    create_by BIGINT UNSIGNED NULL COMMENT '创建人 user_id',
    update_by BIGINT UNSIGNED NULL COMMENT '最后修改人 user_id',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT(1) NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 已删',
    PRIMARY KEY (id),
    UNIQUE KEY uk_scheme_grade (scheme_id, grade_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='等级分档表';

-- -------------------------------------------------------------
-- 4. 目标域
-- -------------------------------------------------------------

-- 4.1 员工目标主表
CREATE TABLE perf_target (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    cycle_id BIGINT UNSIGNED NOT NULL COMMENT '周期',
    employee_id BIGINT UNSIGNED NOT NULL COMMENT '员工 user_id',
    dept_id BIGINT UNSIGNED NOT NULL COMMENT '下达时部门快照',
    scheme_id BIGINT UNSIGNED NOT NULL COMMENT '适用方案',
    status VARCHAR(16) NOT NULL DEFAULT 'DRAFT' COMMENT 'DRAFT/DISTRIBUTED/CONFIRMED/DISPUTED',
    distributed_at DATETIME NULL COMMENT '下达时间',
    confirmed_at DATETIME NULL COMMENT '员工确认时间',
    dispute_reason VARCHAR(255) NULL COMMENT '异议理由',
    create_by BIGINT UNSIGNED NULL COMMENT '创建人 user_id',
    update_by BIGINT UNSIGNED NULL COMMENT '最后修改人 user_id',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT(1) NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 已删',
    version INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
    PRIMARY KEY (id),
    UNIQUE KEY uk_cycle_employee (cycle_id, employee_id),
    KEY idx_employee (employee_id, status),
    KEY idx_dept_status (dept_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='员工目标主表';

-- 4.2 目标明细表
CREATE TABLE perf_target_item (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    target_id BIGINT UNSIGNED NOT NULL COMMENT '目标主表',
    scheme_item_id BIGINT UNSIGNED NOT NULL COMMENT '方案指标项',
    indicator_id BIGINT UNSIGNED NOT NULL COMMENT '指标 id（冗余便于查询）',
    factor_code VARCHAR(16) NOT NULL COMMENT '因子归属快照',
    target_value DECIMAL(12,2) NULL COMMENT '目标值（定性指标可空）',
    challenge_value DECIMAL(12,2) NULL COMMENT '挑战值（可选）',
    weight_snapshot DECIMAL(5,2) NOT NULL COMMENT '下达时权重快照',
    employee_comment VARCHAR(255) NULL COMMENT '员工备注/异议说明',
    create_by BIGINT UNSIGNED NULL COMMENT '创建人 user_id',
    update_by BIGINT UNSIGNED NULL COMMENT '最后修改人 user_id',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT(1) NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 已删',
    PRIMARY KEY (id),
    UNIQUE KEY uk_target_indicator (target_id, indicator_id),
    KEY idx_target (target_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='目标明细表';

-- -------------------------------------------------------------
-- 5. 执行与评价域
-- -------------------------------------------------------------

-- 5.1 绩效考评单表（状态机主实体）
CREATE TABLE perf_record (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    record_no VARCHAR(32) NOT NULL COMMENT '单号：RC+yyyyMMdd+4位序列',
    cycle_id BIGINT UNSIGNED NOT NULL COMMENT '周期',
    employee_id BIGINT UNSIGNED NOT NULL COMMENT '被考核人',
    dept_id BIGINT UNSIGNED NOT NULL COMMENT '被考核人部门（子树查询用）',
    scheme_id BIGINT UNSIGNED NOT NULL COMMENT '采用的方案',
    target_id BIGINT UNSIGNED NOT NULL COMMENT '对应目标',
    status VARCHAR(24) NOT NULL DEFAULT 'DRAFT' COMMENT '主状态机状态',
    current_node_code VARCHAR(24) NULL COMMENT '当前审批节点：N1_DEPT/N2_HR/N3_FINAL',
    self_total DECIMAL(5,2) NULL COMMENT '自评总分',
    manager_total DECIMAL(5,2) NULL COMMENT '部门评审总分',
    hr_total DECIMAL(5,2) NULL COMMENT 'HR 复核后总分',
    final_total DECIMAL(5,2) NULL COMMENT '终审总分',
    final_grade VARCHAR(16) NULL COMMENT '终审等级',
    submitted_at DATETIME NULL COMMENT '最近一次提交时间',
    dept_passed_at DATETIME NULL COMMENT '部门通过时间',
    hr_passed_at DATETIME NULL COMMENT 'HR 通过时间',
    finalized_at DATETIME NULL COMMENT '终审时间（申诉时限起点）',
    result_confirmed_at DATETIME NULL COMMENT '员工确认结果时间',
    closed_at DATETIME NULL COMMENT '办结时间',
    pre_appeal_status VARCHAR(24) NULL COMMENT '申诉发起时的状态快照',
    deadline_at DATETIME NULL COMMENT '当前节点处理期限',
    latest_snapshot_id BIGINT UNSIGNED NULL COMMENT '最新正式引擎建议快照',
    aux_data JSON NULL COMMENT '非指标类结构化取数（F4/F5/F6 与硬约束输入）',
    remark VARCHAR(255) NULL COMMENT '备注',
    create_by BIGINT UNSIGNED NULL COMMENT '创建人 user_id',
    update_by BIGINT UNSIGNED NULL COMMENT '最后修改人 user_id',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT(1) NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 已删',
    version INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
    PRIMARY KEY (id),
    UNIQUE KEY uk_record_no (record_no),
    UNIQUE KEY uk_record_cycle_emp (cycle_id, employee_id),
    KEY idx_emp_status (employee_id, status),
    KEY idx_dept_status (dept_id, status),
    KEY idx_status_node (status, current_node_code),
    KEY idx_cycle (cycle_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='绩效考评单表';

-- 5.2 考评指标明细表
CREATE TABLE perf_record_item (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    record_id BIGINT UNSIGNED NOT NULL COMMENT '考评单',
    scheme_item_id BIGINT UNSIGNED NOT NULL COMMENT '方案指标项',
    indicator_id BIGINT UNSIGNED NOT NULL COMMENT '指标',
    factor_code VARCHAR(16) NOT NULL COMMENT '因子归属快照 F1-F6',
    weight_snapshot DECIMAL(5,2) NOT NULL COMMENT '权重快照',
    target_value_snapshot DECIMAL(12,2) NULL COMMENT '目标值快照',
    actual_value DECIMAL(12,2) NULL COMMENT '实际完成值',
    achievement_rate DECIMAL(5,2) NULL COMMENT '达成率（封顶按 scoring_rule.rateCap）',
    self_score DECIMAL(5,2) NULL COMMENT '自评分（0-100）',
    manager_score DECIMAL(5,2) NULL COMMENT '部门评分',
    hr_score DECIMAL(5,2) NULL COMMENT 'HR 调整分（空则视同 manager_score）',
    final_score DECIMAL(5,2) NULL COMMENT '该指标最终采用分',
    self_comment VARCHAR(500) NULL COMMENT '自评说明',
    manager_comment VARCHAR(500) NULL COMMENT '评分说明',
    data_source VARCHAR(16) NOT NULL DEFAULT 'MANUAL' COMMENT 'MANUAL/IMPORT/SEED',
    create_by BIGINT UNSIGNED NULL COMMENT '创建人 user_id',
    update_by BIGINT UNSIGNED NULL COMMENT '最后修改人 user_id',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT(1) NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 已删',
    PRIMARY KEY (id),
    UNIQUE KEY uk_record_indicator (record_id, indicator_id),
    KEY idx_record_factor (record_id, factor_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='考评指标明细表';

-- 5.3 材料表（逻辑组）
CREATE TABLE perf_material (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    record_id BIGINT UNSIGNED NOT NULL COMMENT '所属考评单',
    record_item_id BIGINT UNSIGNED NULL COMMENT '关联考评明细（周期级通用材料可空）',
    material_name VARCHAR(128) NOT NULL COMMENT '材料名称（不含版本）',
    material_type VARCHAR(16) NOT NULL COMMENT 'docx/pdf/xlsx/img/other',
    current_version INT NOT NULL DEFAULT 1 COMMENT '当前版本号',
    status TINYINT NOT NULL DEFAULT 1 COMMENT '1 有效 0 移除',
    create_by BIGINT UNSIGNED NULL COMMENT '创建人 user_id',
    update_by BIGINT UNSIGNED NULL COMMENT '最后修改人 user_id',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT(1) NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 已删',
    PRIMARY KEY (id),
    KEY idx_record (record_id),
    KEY idx_record_item (record_item_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='材料表';

-- 5.4 材料版本表（只增不改）
CREATE TABLE perf_material_version (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    material_id BIGINT UNSIGNED NOT NULL COMMENT '材料 id',
    version_no INT NOT NULL COMMENT '版本号，从 1 起',
    file_path VARCHAR(255) NOT NULL COMMENT '相对 epms.file.base-dir 的存储路径',
    file_hash VARCHAR(64) NOT NULL COMMENT '文件 SHA-256',
    file_size BIGINT NOT NULL COMMENT '字节数（≤50MB）',
    change_note VARCHAR(255) NULL COMMENT '本版变更说明',
    uploaded_by BIGINT UNSIGNED NOT NULL COMMENT '上传人 user_id',
    uploaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '上传时间',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (id),
    UNIQUE KEY uk_material_version (material_id, version_no),
    KEY idx_hash (file_hash)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='材料版本表';

-- 5.5 阶段评分单表
CREATE TABLE perf_score_sheet (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    record_id BIGINT UNSIGNED NOT NULL COMMENT '考评单',
    stage VARCHAR(16) NOT NULL COMMENT 'SELF/DEPT/HR/FINAL',
    evaluator_id BIGINT UNSIGNED NOT NULL COMMENT '评审人 user_id（SELF=员工本人）',
    total_score DECIMAL(5,2) NOT NULL COMMENT '该阶段给出的总分',
    grade_suggestion VARCHAR(16) NULL COMMENT '该阶段建议等级（终审前可空）',
    overall_comment VARCHAR(1000) NULL COMMENT '综合评语',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '提交时间',
    PRIMARY KEY (id),
    UNIQUE KEY uk_record_stage_evaluator (record_id, stage, evaluator_id),
    KEY idx_record_stage (record_id, stage)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='阶段评分单表';

-- 5.6 评分单明细表（会签场景逐人逐指标）
CREATE TABLE perf_score_detail (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    sheet_id BIGINT UNSIGNED NOT NULL COMMENT '评分单',
    record_item_id BIGINT UNSIGNED NOT NULL COMMENT '考评明细',
    factor_code VARCHAR(16) NOT NULL COMMENT '因子（汇总用）',
    score DECIMAL(5,2) NOT NULL COMMENT '该评审人对该指标的打分',
    comment VARCHAR(255) NULL COMMENT '打分说明',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (id),
    KEY idx_sheet (sheet_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='评分单明细表';

-- -------------------------------------------------------------
-- 6. 引擎留痕与人工结论域
-- -------------------------------------------------------------

-- 6.1 系统建议快照表（只增不改）
CREATE TABLE perf_recommendation_snapshot (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    snapshot_no VARCHAR(32) NOT NULL COMMENT '快照号：SN+yyyyMMdd+4位序列',
    record_id BIGINT UNSIGNED NOT NULL COMMENT '考评单',
    scheme_id BIGINT UNSIGNED NOT NULL COMMENT '方案',
    rule_version INT NOT NULL COMMENT '计算时方案规则版本',
    engine_version VARCHAR(16) NOT NULL COMMENT '引擎代码版本（如 v1.0）',
    trigger_stage VARCHAR(16) NOT NULL COMMENT 'AFTER_SELF/AFTER_DEPT/MANUAL_RERUN',
    factor_results JSON NOT NULL COMMENT '六因子明细数组',
    hard_constraint_results JSON NOT NULL COMMENT '各硬约束是否命中及证据',
    total_score DECIMAL(5,2) NULL COMMENT '建议总分；数据严重缺失时为空',
    suggested_grade VARCHAR(16) NOT NULL COMMENT '建议等级；无法给档时为 MANUAL_REQUIRED',
    confidence DECIMAL(4,3) NOT NULL COMMENT '置信度 0.000-1.000',
    need_manual_confirm TINYINT(1) NOT NULL COMMENT '是否必须人工确认',
    manual_reasons JSON NULL COMMENT '需要人工的原因码数组',
    evidence_list JSON NOT NULL COMMENT '依据列表',
    create_by BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '0=系统自动；人工重算记触发人',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '计算时间',
    PRIMARY KEY (id),
    UNIQUE KEY uk_snapshot_no (snapshot_no),
    KEY idx_record (record_id, created_at),
    KEY idx_record_stage (record_id, trigger_stage)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='系统建议快照表（不可变）';

-- 6.2 人工结论表（当前生效结论，每单一行）
CREATE TABLE perf_manual_conclusion (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    record_id BIGINT UNSIGNED NOT NULL COMMENT '考评单',
    snapshot_id BIGINT UNSIGNED NOT NULL COMMENT '所依据的建议快照',
    is_adjusted TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否调整了引擎建议',
    engine_score DECIMAL(5,2) NOT NULL COMMENT '采纳时快照的建议总分',
    engine_grade VARCHAR(16) NOT NULL COMMENT '采纳时快照的建议等级',
    final_score DECIMAL(5,2) NOT NULL COMMENT '人工最终总分',
    final_grade VARCHAR(16) NOT NULL COMMENT '人工最终等级（六档之一）',
    adjust_reason VARCHAR(500) NULL COMMENT '调整理由（is_adjusted=1 时必填且≥10 字）',
    confirmer_id BIGINT UNSIGNED NOT NULL COMMENT '确认人（终审人 user_id）',
    confirmer_role VARCHAR(16) NOT NULL COMMENT 'HR/FINAL',
    confirmed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '确认时间',
    create_by BIGINT UNSIGNED NULL COMMENT '创建人 user_id',
    update_by BIGINT UNSIGNED NULL COMMENT '最后修改人 user_id',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT(1) NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 已删',
    version INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
    PRIMARY KEY (id),
    UNIQUE KEY uk_record (record_id),
    KEY idx_snapshot (snapshot_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='人工结论表';

-- 6.3 人工结论变更历史表（只增）
CREATE TABLE perf_conclusion_history (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    conclusion_id BIGINT UNSIGNED NOT NULL COMMENT '结论 id',
    change_type VARCHAR(16) NOT NULL COMMENT 'CREATE/MODIFY/OVERRIDE',
    before_json JSON NULL COMMENT '变更前完整字段（CREATE 时为空）',
    after_json JSON NOT NULL COMMENT '变更后完整字段',
    reason VARCHAR(500) NULL COMMENT '变更原因',
    operator_id BIGINT UNSIGNED NOT NULL COMMENT '操作人',
    operator_role VARCHAR(16) NOT NULL COMMENT '操作人角色',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (id),
    KEY idx_conclusion (conclusion_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='人工结论变更历史表';

-- -------------------------------------------------------------
-- 7. 申诉与改进域
-- -------------------------------------------------------------

-- 7.1 申诉复核表
CREATE TABLE perf_appeal (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    appeal_no VARCHAR(32) NOT NULL COMMENT '申诉号：AP+yyyyMMdd+4位序列',
    record_id BIGINT UNSIGNED NOT NULL COMMENT '考评单',
    appellant_id BIGINT UNSIGNED NOT NULL COMMENT '申诉人（被考核员工）',
    from_status VARCHAR(24) NOT NULL COMMENT '发起申诉时考评单状态',
    reason VARCHAR(1000) NOT NULL COMMENT '申诉理由',
    evidence_material_ids VARCHAR(255) NULL COMMENT '证据材料 id 列表，逗号分隔',
    status VARCHAR(16) NOT NULL DEFAULT 'SUBMITTED' COMMENT 'SUBMITTED/REVIEWING/SUSTAINED/REJECTED/WITHDRAWN',
    handler_id BIGINT UNSIGNED NULL COMMENT '复核责任人',
    handler_role VARCHAR(16) NULL COMMENT 'HR_SPECIALIST/EXECUTIVE',
    handle_comment VARCHAR(1000) NULL COMMENT '复核意见（成立/驳回必填）',
    handled_at DATETIME NULL COMMENT '处理时间',
    withdrawn_at DATETIME NULL COMMENT '撤回时间',
    create_by BIGINT UNSIGNED NULL COMMENT '创建人 user_id',
    update_by BIGINT UNSIGNED NULL COMMENT '最后修改人 user_id',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT(1) NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 已删',
    version INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
    PRIMARY KEY (id),
    UNIQUE KEY uk_appeal_no (appeal_no),
    KEY idx_record (record_id),
    KEY idx_appellant_status (appellant_id, status),
    KEY idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='申诉复核表';

-- 7.2 改进计划表
CREATE TABLE perf_improvement_plan (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    plan_no VARCHAR(32) NOT NULL COMMENT '计划号：IP+yyyyMMdd+4位序列',
    record_id BIGINT UNSIGNED NOT NULL COMMENT '来源考评单',
    employee_id BIGINT UNSIGNED NOT NULL COMMENT '改进人',
    manager_id BIGINT UNSIGNED NOT NULL COMMENT '跟踪负责人',
    source VARCHAR(16) NOT NULL COMMENT 'LOW_GRADE/APPEAL/MANUAL',
    content TEXT NOT NULL COMMENT '改进总体目标与说明',
    start_date DATE NOT NULL COMMENT '开始日',
    due_date DATE NOT NULL COMMENT '计划完成日',
    status VARCHAR(16) NOT NULL DEFAULT 'IN_PROGRESS' COMMENT 'IN_PROGRESS/COMPLETED/CANCELLED',
    result_comment VARCHAR(1000) NULL COMMENT '完成/取消说明',
    completed_at DATETIME NULL COMMENT '办结时间',
    create_by BIGINT UNSIGNED NULL COMMENT '创建人 user_id',
    update_by BIGINT UNSIGNED NULL COMMENT '最后修改人 user_id',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT(1) NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 已删',
    version INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
    PRIMARY KEY (id),
    UNIQUE KEY uk_plan_no (plan_no),
    KEY idx_employee_status (employee_id, status),
    KEY idx_record (record_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='改进计划表';

-- 7.3 改进任务表
CREATE TABLE perf_improvement_task (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    plan_id BIGINT UNSIGNED NOT NULL COMMENT '改进计划',
    action_content VARCHAR(500) NOT NULL COMMENT '具体改进行动',
    due_date DATE NOT NULL COMMENT '任务截止日',
    status VARCHAR(16) NOT NULL DEFAULT 'TODO' COMMENT 'TODO/DONE/OVERDUE',
    completed_at DATETIME NULL COMMENT '完成时间',
    verify_comment VARCHAR(255) NULL COMMENT '负责人验证意见',
    sort_no INT NOT NULL DEFAULT 0 COMMENT '顺序',
    create_by BIGINT UNSIGNED NULL COMMENT '创建人 user_id',
    update_by BIGINT UNSIGNED NULL COMMENT '最后修改人 user_id',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT(1) NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 已删',
    PRIMARY KEY (id),
    KEY idx_plan_status (plan_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='改进任务表';

-- -------------------------------------------------------------
-- 8. 审批域
-- -------------------------------------------------------------

-- 8.1 审批节点配置表
CREATE TABLE appr_node_config (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    biz_type VARCHAR(24) NOT NULL DEFAULT 'PERF_RECORD' COMMENT 'PERF_RECORD/APPEAL',
    scope_type VARCHAR(16) NOT NULL COMMENT 'GLOBAL/CYCLE/SCHEME',
    scope_id BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '作用域 id（GLOBAL=0）',
    node_code VARCHAR(24) NOT NULL COMMENT 'N1_DEPT/N2_HR/N3_FINAL/APPEAL_REVIEW',
    node_name VARCHAR(64) NOT NULL COMMENT '节点显示名',
    node_seq INT NOT NULL COMMENT '节点顺序（10/20/30）',
    assignee_type VARCHAR(20) NOT NULL COMMENT 'ROLE/DEPT_LEADER/DESIGNATED_USER',
    assignee_value VARCHAR(128) NOT NULL COMMENT 'ROLE→角色码；DESIGNATED_USER→user_id；DEPT_LEADER→*',
    sign_type VARCHAR(8) NOT NULL DEFAULT 'ANY' COMMENT 'ANY 单人/ALL 会签',
    allow_return TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否允许退回',
    return_to_node VARCHAR(24) NULL COMMENT '退回到的节点（NULL=退回员工草稿）',
    due_hours INT NOT NULL DEFAULT 24 COMMENT '处理期限（小时）',
    remind_times INT NOT NULL DEFAULT 3 COMMENT '催办上限',
    enabled TINYINT(1) NOT NULL DEFAULT 1 COMMENT '启用标志',
    create_by BIGINT UNSIGNED NULL COMMENT '创建人 user_id',
    update_by BIGINT UNSIGNED NULL COMMENT '最后修改人 user_id',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT(1) NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 已删',
    version INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
    PRIMARY KEY (id),
    UNIQUE KEY uk_node (biz_type, scope_type, scope_id, node_code),
    KEY idx_enabled (enabled)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='审批节点配置表';

-- 8.2 审批任务表
CREATE TABLE appr_task (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    biz_type VARCHAR(24) NOT NULL COMMENT 'PERF_RECORD/APPEAL',
    biz_id BIGINT UNSIGNED NOT NULL COMMENT '业务单 id',
    node_code VARCHAR(24) NOT NULL COMMENT '节点码',
    node_seq INT NOT NULL COMMENT '节点顺序快照',
    assignee_id BIGINT UNSIGNED NOT NULL COMMENT '责任人 user_id',
    assignee_role VARCHAR(32) NOT NULL COMMENT '责任人当时角色快照',
    sign_type VARCHAR(8) NOT NULL COMMENT 'ANY/ALL 快照',
    status VARCHAR(12) NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING/APPROVED/RETURNED/REJECTED/SKIPPED',
    action_comment VARCHAR(500) NULL COMMENT '审批意见（退回/驳回必填）',
    handled_at DATETIME NULL COMMENT '处理时间',
    remind_count INT NOT NULL DEFAULT 0 COMMENT '已催办次数',
    next_remind_at DATETIME NULL COMMENT '下次催办时间',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '生成时间',
    PRIMARY KEY (id),
    KEY idx_todo (assignee_id, status),
    KEY idx_biz_node (biz_type, biz_id, node_seq),
    KEY idx_remind (next_remind_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='审批任务表';

-- -------------------------------------------------------------
-- 9. 智能域
-- -------------------------------------------------------------

-- 9.1 知识文档表
CREATE TABLE ai_kb_document (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    doc_title VARCHAR(255) NOT NULL COMMENT '文档标题',
    doc_category VARCHAR(32) NOT NULL COMMENT 'PERFORMANCE/ATTENDANCE/REWARD/PROMOTION/OTHER',
    file_path VARCHAR(255) NOT NULL COMMENT '原文件存储路径',
    file_hash VARCHAR(64) NOT NULL COMMENT 'SHA-256',
    version_no INT NOT NULL DEFAULT 1 COMMENT '文档版本',
    chunk_size INT NOT NULL DEFAULT 500 COMMENT '切块字符数',
    overlap INT NOT NULL DEFAULT 80 COMMENT '相邻块重叠字符数',
    chunk_count INT NOT NULL DEFAULT 0 COMMENT '切块数量',
    tags VARCHAR(255) NULL COMMENT '文档级标签（逗号分隔）',
    status VARCHAR(20) NOT NULL DEFAULT 'UPLOADED' COMMENT 'UPLOADED/CHUNKED/EMBEDDING/READY/EMBED_PARTIAL/FAILED',
    enabled TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否参与检索',
    remark VARCHAR(255) NULL COMMENT '备注',
    create_by BIGINT UNSIGNED NULL COMMENT '创建人 user_id',
    update_by BIGINT UNSIGNED NULL COMMENT '最后修改人 user_id',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT(1) NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 已删',
    PRIMARY KEY (id),
    KEY idx_status_enabled (status, enabled),
    KEY idx_category (doc_category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='知识文档表';

-- 9.2 文档切块表（向量与 BM25 双路数据）
CREATE TABLE ai_kb_chunk (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    doc_id BIGINT UNSIGNED NOT NULL COMMENT '所属文档',
    chunk_index INT NOT NULL COMMENT '块序号（从 0 起）',
    content TEXT NOT NULL COMMENT '文本块原文（约 500 字）',
    char_count INT NOT NULL COMMENT '字符数',
    section_path VARCHAR(255) NULL COMMENT '章节路径，作为出处展示',
    tags VARCHAR(255) NULL COMMENT '块标签（逗号分隔）',
    keywords VARCHAR(255) NULL COMMENT '关键词（逗号分隔）',
    embedding TEXT NULL COMMENT 'embedding 向量的 JSON 数组字符串',
    embedding_model VARCHAR(64) NULL COMMENT '生成向量的模型名',
    embedding_dim INT NULL COMMENT '向量维度',
    embedding_status VARCHAR(16) NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING/SUCCESS/FAILED/SKIPPED',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT(1) NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 已删',
    PRIMARY KEY (id),
    UNIQUE KEY uk_doc_chunk (doc_id, chunk_index),
    KEY idx_doc (doc_id),
    KEY idx_embedding (embedding_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='文档切块表';

-- 9.3 对话会话表
CREATE TABLE ai_chat_session (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    user_id BIGINT UNSIGNED NOT NULL COMMENT '发起人',
    title VARCHAR(128) NULL COMMENT '会话标题（取首条提问前 20 字）',
    ever_degraded TINYINT(1) NOT NULL DEFAULT 0 COMMENT '本会话是否出现过降级',
    last_message_at DATETIME NOT NULL COMMENT '最近消息时间',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (id),
    KEY idx_user_time (user_id, last_message_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='对话会话表';

-- 9.4 对话消息表
CREATE TABLE ai_chat_message (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    session_id BIGINT UNSIGNED NOT NULL COMMENT '会话',
    role VARCHAR(16) NOT NULL COMMENT 'USER/ASSISTANT/TOOL',
    content TEXT NOT NULL COMMENT '消息正文',
    tool_calls JSON NULL COMMENT '工具调用数组',
    citations JSON NULL COMMENT '出处数组',
    retrieval_mode VARCHAR(8) NULL COMMENT 'VECTOR/BM25/NONE',
    degraded TINYINT(1) NOT NULL DEFAULT 0 COMMENT '本条是否降级输出',
    fail_reason VARCHAR(16) NULL COMMENT 'TIMEOUT/QUOTA/NETWORK/NO_KEY/TOOL_ERROR',
    token_prompt INT NULL COMMENT '输入 token',
    token_completion INT NULL COMMENT '输出 token',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (id),
    KEY idx_session_time (session_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='对话消息表';

-- 9.5 Agent 调用日志表（每次能力调用一条）
CREATE TABLE agent_call_log (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    session_id BIGINT UNSIGNED NULL COMMENT '关联会话（独立页面调用为空）',
    capability VARCHAR(16) NOT NULL COMMENT 'DRAFT_SCHEME/EXPLAIN_EVAL/INSPECTION/CHAT',
    user_id BIGINT UNSIGNED NOT NULL COMMENT '调用用户',
    user_role VARCHAR(32) NOT NULL COMMENT '调用时角色快照',
    biz_ref_type VARCHAR(24) NULL COMMENT 'PERF_CYCLE/PERF_RECORD/PERF_SCHEME',
    biz_ref_id BIGINT UNSIGNED NULL COMMENT '锚定对象 id',
    input_summary VARCHAR(1000) NOT NULL COMMENT '输入摘要',
    tool_chain JSON NOT NULL COMMENT '工具调用链',
    output_summary VARCHAR(2000) NULL COMMENT '输出摘要',
    citations JSON NULL COMMENT '出处数组',
    retrieval_mode VARCHAR(8) NULL COMMENT 'VECTOR/BM25/NONE',
    degraded TINYINT(1) NOT NULL DEFAULT 0 COMMENT '本次是否降级',
    fail_reason VARCHAR(16) NULL COMMENT 'TIMEOUT/QUOTA/NETWORK/NO_KEY/TOOL_ERROR',
    adopted TINYINT(1) NOT NULL DEFAULT 0 COMMENT '草案/建议是否被人工采纳并落库',
    adopted_biz_type VARCHAR(24) NULL COMMENT '采纳后写入对象类型',
    adopted_biz_id BIGINT UNSIGNED NULL COMMENT '采纳后业务 id',
    cost_ms INT NOT NULL COMMENT '本次调用总耗时（≤8000 为正常）',
    token_prompt INT NULL COMMENT '输入 token',
    token_completion INT NULL COMMENT '输出 token',
    error_info VARCHAR(1000) NULL COMMENT '异常摘要',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '调用时间',
    PRIMARY KEY (id),
    KEY idx_user_time (user_id, created_at),
    KEY idx_cap_time (capability, created_at),
    KEY idx_session (session_id),
    KEY idx_adopted (adopted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Agent 调用日志表';
