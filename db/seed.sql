-- =============================================================
-- EPMS 初始化测试数据（seed）
-- 依据：docs/02-数据模型.md §12、docs/04-决策规则与验证.md §4/§7
-- 执行方式：mysql -u root -p
--          source D:/Graduation_project/db/seed.sql
-- 注意：本脚本只用于首次初始化，重复执行会因唯一键冲突而失败
-- 演示账号统一密码：Epms@123456（BCrypt cost=10）
-- =============================================================

USE epms;
SET NAMES utf8mb4;

START TRANSACTION;

-- -------------------------------------------------------------
-- 1. 角色（固定 5 个）
-- -------------------------------------------------------------
INSERT INTO sys_role (id, role_code, role_name, data_scope, status, remark) VALUES
(1, 'EMPLOYEE',       '员工',       'SELF',      1, '普通员工，只能查看本人数据'),
(2, 'DEPT_MANAGER',   '部门负责人', 'DEPT_TREE', 1, '负责本部门考核评审'),
(3, 'HR_SPECIALIST',  'HR 专员',    'ALL',       1, '负责绩效复核与配置'),
(4, 'EXECUTIVE',      '高管',       'ALL',       1, '负责终审'),
(5, 'ADMIN',          '系统管理员', 'ALL',       1, '系统配置与权限管理');

-- -------------------------------------------------------------
-- 2. 部门树：1 个公司根部门 + 3 个二级部门
-- -------------------------------------------------------------
INSERT INTO sys_dept (id, parent_id, ancestors, dept_code, dept_name, sort_no, status) VALUES
(1, 0, '0',     'COMPANY',   '示例科技有限公司', 1, 1),
(2, 1, '0,1',   'DEPT_SALES','销售部',           2, 1),
(3, 1, '0,1',   'DEPT_TECH', '技术部',           3, 1),
(4, 1, '0,1',   'DEPT_FUNC', '职能部',           4, 1);

-- -------------------------------------------------------------
-- 3. 用户（含 4 个演示账号 + 4 个引擎验证员工）
-- -------------------------------------------------------------
INSERT INTO sys_user (id, username, password_hash, real_name, employee_no, dept_id, position_title, mobile, email, status) VALUES
(1,  'admin',      '$2b$10$AgQHmU/x4F11kRdJGP//COx1q3GHXddc7bjrTLg3quRLhe8W1o3EW', '系统管理员', 'A0001', 1, '管理员',     '13800000001', 'admin@epms.demo',      1),
(2,  'hr01',       '$2b$10$AgQHmU/x4F11kRdJGP//COx1q3GHXddc7bjrTLg3quRLhe8W1o3EW', '李静',       'H0001', 4, 'HR 专员',      '13800000002', 'hr01@epms.demo',       1),
(3,  'manager01',  '$2b$10$AgQHmU/x4F11kRdJGP//COx1q3GHXddc7bjrTLg3quRLhe8W1o3EW', '陈刚',       'M0001', 2, '销售部负责人', '13800000003', 'manager01@epms.demo',  1),
(4,  'employee01', '$2b$10$AgQHmU/x4F11kRdJGP//COx1q3GHXddc7bjrTLg3quRLhe8W1o3EW', '刘洋',       'E0000', 2, '销售专员',     '13800000004', 'employee01@epms.demo', 1),
(5,  'e1001',      '$2b$10$AgQHmU/x4F11kRdJGP//COx1q3GHXddc7bjrTLg3quRLhe8W1o3EW', '张晓明',     'E1001', 2, '销售专员',     '13800001001', 'e1001@epms.demo',      1),
(6,  'e1002',      '$2b$10$AgQHmU/x4F11kRdJGP//COx1q3GHXddc7bjrTLg3quRLhe8W1o3EW', '李娜',       'E1002', 2, '销售专员',     '13800001002', 'e1002@epms.demo',      1),
(7,  'e1003',      '$2b$10$AgQHmU/x4F11kRdJGP//COx1q3GHXddc7bjrTLg3quRLhe8W1o3EW', '王强',       'E1003', 3, '技术专员',     '13800001003', 'e1003@epms.demo',      1),
(8,  'e1004',      '$2b$10$AgQHmU/x4F11kRdJGP//COx1q3GHXddc7bjrTLg3quRLhe8W1o3EW', '赵敏',       'E1004', 4, '行政专员',     '13800001004', 'e1004@epms.demo',      1),
(9,  'manager02',  '$2b$10$AgQHmU/x4F11kRdJGP//COx1q3GHXddc7bjrTLg3quRLhe8W1o3EW', '周涛',       'M0002', 3, '技术部负责人', '13800000009', 'manager02@epms.demo',  1),
(10, 'manager03',  '$2b$10$AgQHmU/x4F11kRdJGP//COx1q3GHXddc7bjrTLg3quRLhe8W1o3EW', '孙丽',       'M0003', 4, '职能部负责人', '13800000010', 'manager03@epms.demo',  1),
(11, 'exec01',     '$2b$10$AgQHmU/x4F11kRdJGP//COx1q3GHXddc7bjrTLg3quRLhe8W1o3EW', '王总',       'X0001', 1, '总经理',       '13800000011', 'exec01@epms.demo',     1);

-- 部门负责人
UPDATE sys_dept SET leader_user_id = 1  WHERE id = 1;
UPDATE sys_dept SET leader_user_id = 3  WHERE id = 2;
UPDATE sys_dept SET leader_user_id = 9  WHERE id = 3;
UPDATE sys_dept SET leader_user_id = 10 WHERE id = 4;

-- -------------------------------------------------------------
-- 4. 用户角色
-- -------------------------------------------------------------
INSERT INTO sys_user_role (user_id, role_id) VALUES
(1, 5),  -- admin: ADMIN
(2, 3),  -- hr01: HR_SPECIALIST
(2, 1),  -- hr01 同时也是员工
(3, 2),  -- manager01: DEPT_MANAGER
(3, 1),
(4, 1),
(5, 1),
(6, 1),
(7, 1),
(8, 1),
(9, 2),
(9, 1),
(10, 2),
(10, 1),
(11, 4); -- exec01: EXECUTIVE

-- -------------------------------------------------------------
-- 5. 系统参数（10 项）
-- -------------------------------------------------------------
INSERT INTO sys_config (config_key, config_value, value_type, group_code, remark, status) VALUES
('login.single-device',            'false', 'BOOLEAN', 'LOGIN',  '是否禁止同账号多点登录',           1),
('login.fail-max',                 '5',     'NUMBER',  'LOGIN',  '15 分钟内失败锁定阈值',            1),
('appeal.limit-days',              '7',     'NUMBER',  'SYS',    '申诉时限（自然日）',               1),
('remind.after-hours',             '24',    'NUMBER',  'REMIND', '审批任务生成后多少小时未处理开始催办', 1),
('remind.max-times',               '3',     'NUMBER',  'REMIND', '最大催办次数',                     1),
('ai.agent.enabled',               'true',  'BOOLEAN', 'AI',     '智能助手总开关',                   1),
('ai.chat.timeout-ms',             '8000',  'NUMBER',  'AI',     'Agent 接口超时（8 秒）',           1),
('ai.rerieve.top-k',               '4',     'NUMBER',  'AI',     'RAG 检索 top-k',                   1),
('ai.rerieve.score-threshold',     '0.75',  'NUMBER',  'AI',     '向量余弦阈值',                     1),
('engine.confidence.threshold',    '0.75',  'NUMBER',  'ENGINE', '低于该置信度强制人工确认',          1);

-- -------------------------------------------------------------
-- 6. 考核周期：2026-Q2 / Q3 历史，2026-Q4 当前
-- -------------------------------------------------------------
INSERT INTO perf_cycle (id, cycle_code, cycle_name, cycle_type, start_date, end_date, self_deadline, manager_deadline, hr_deadline, final_deadline, status, published_at, finished_at, remark) VALUES
(1, '2026-Q2', '2026 年第二季度考核', 'QUARTER', '2026-04-01', '2026-06-30',
 '2026-06-20 23:59:59', '2026-06-25 23:59:59', '2026-06-28 23:59:59', '2026-06-30 23:59:59',
 'FINISHED', '2026-04-05 09:00:00', '2026-07-01 10:00:00', '历史周期，用于 F6 历史趋势'),
(2, '2026-Q3', '2026 年第三季度考核', 'QUARTER', '2026-07-01', '2026-09-30',
 '2026-09-20 23:59:59', '2026-09-25 23:59:59', '2026-09-28 23:59:59', '2026-09-30 23:59:59',
 'FINISHED', '2026-07-05 09:00:00', '2026-10-01 10:00:00', '历史周期，用于 F6 历史趋势'),
(3, '2026-Q4', '2026 年第四季度考核', 'QUARTER', '2026-10-01', '2026-12-31',
 '2026-11-10 23:59:59', '2026-11-20 23:59:59', '2026-11-25 23:59:59', '2026-11-30 23:59:59',
 'PUBLISHED', '2026-10-08 09:00:00', NULL, '当前演示周期');

-- -------------------------------------------------------------
-- 7. 指标库（8 个 F1 定量 + 1 个 F2 定性 + 1 个 F3 定性）
-- -------------------------------------------------------------
INSERT INTO perf_indicator (id, indicator_code, indicator_name, category, unit, default_factor_code, data_source, scoring_desc, status) VALUES
(1,  'KPI-SALE-01',    '销售额',           'QUANTITATIVE', '万元', 'F1', '销售系统导出', '达成率=实际/目标×100，得分封顶 100', 1),
(2,  'KPI-COLLECT-02', '回款率',           'QUANTITATIVE', '%',    'F1', '财务系统导出', '达成率=实际/目标×100，得分封顶 100', 1),
(3,  'KPI-NEWCUST-03', '新客户数',         'QUANTITATIVE', '个',   'F1', 'CRM 导出',     '达成率=实际/目标×100，得分封顶 100', 1),
(4,  'KPI-GROSS-04',   '毛利率',           'QUANTITATIVE', '%',    'F1', '财务系统导出', '达成率=实际/目标×100，得分封顶 100', 1),
(5,  'KPI-COST-05',    '费用控制率',       'QUANTITATIVE', '%',    'F1', '财务系统导出', '达成率=实际/目标×100，得分封顶 100', 1),
(6,  'KPI-DELIVERY-06','交付及时率',       'QUANTITATIVE', '%',    'F1', '项目系统导出', '达成率=实际/目标×100，得分封顶 100', 1),
(7,  'KPI-SATISFY-07', '客户满意度',       'QUANTITATIVE', '%',    'F1', '满意度调研',   '达成率=实际/目标×100，得分封顶 100', 1),
(8,  'KPI-PROCESS-08', '流程规范执行率',   'QUANTITATIVE', '%',    'F1', '合规检查记录', '达成率=实际/目标×100，得分封顶 100', 1),
(9,  'QUA-PROJ-09',    '重点项目完成质量', 'QUALITATIVE',  '分',   'F2', '主管评分',     '按项目完成质量 0-100 打分',          1),
(10, 'QUA-VALUE-10',   '价值观与行为规范', 'QUALITATIVE',  '分',   'F3', '主管评分',     '按责任心/合规/协作 0-100 打分',      1);

-- -------------------------------------------------------------
-- 8. 指标方案（2026-Q4 全员方案，规则版本 1）
-- 注意：指标项只覆盖 F1/F2/F3，权重合计 75；F4/F5/F6 取 aux_data，无指标项。
--       docs/02 写的 total_weight=100 与 04 §6.1 的“三项合计 75”存在冲突，此处按 75 落数。
-- -------------------------------------------------------------
INSERT INTO perf_scheme (id, scheme_code, scheme_name, cycle_id, scope_type, scope_value, rule_version, total_weight, status, published_at, remark) VALUES
(1, 'SCH-2026Q4-ALL', '2026Q4 全员绩效方案', 3, 'ALL', '*', 1, 75.00, 'PUBLISHED', '2026-10-08 09:00:00', '指标项覆盖 F1-F3，F4-F6 走 aux_data');

INSERT INTO perf_scheme_item (id, scheme_id, indicator_id, factor_code, weight, target_required, scoring_rule, sort_no) VALUES
(1,  1, 1,  'F1', 18.00, 1, '{"rateCap":120,"scoreCap":100,"direction":"POSITIVE"}', 1),
(2,  1, 2,  'F1', 6.00,  1, '{"rateCap":120,"scoreCap":100,"direction":"POSITIVE"}', 2),
(3,  1, 3,  'F1', 5.00,  1, '{"rateCap":120,"scoreCap":100,"direction":"POSITIVE"}', 3),
(4,  1, 4,  'F1', 5.00,  1, '{"rateCap":120,"scoreCap":100,"direction":"POSITIVE"}', 4),
(5,  1, 5,  'F1', 2.00,  1, '{"rateCap":120,"scoreCap":100,"direction":"POSITIVE"}', 5),
(6,  1, 6,  'F1', 2.00,  1, '{"rateCap":120,"scoreCap":100,"direction":"POSITIVE"}', 6),
(7,  1, 7,  'F1', 1.00,  1, '{"rateCap":120,"scoreCap":100,"direction":"POSITIVE"}', 7),
(8,  1, 8,  'F1', 1.00,  1, '{"rateCap":120,"scoreCap":100,"direction":"POSITIVE"}', 8),
(9,  1, 9,  'F2', 20.00, 0, '{"scoreCap":100}', 9),
(10, 1, 10, 'F3', 15.00, 0, '{"scoreCap":100}', 10);

-- -------------------------------------------------------------
-- 9. 六因子权重（合计 100）
-- -------------------------------------------------------------
INSERT INTO perf_factor_config (scheme_id, factor_code, factor_name, weight, enabled, calc_params, sort_no) VALUES
(1, 'F1', '量化指标达成率',       40.00, 1, NULL, 1),
(1, 'F2', '重点工作完成质量',     20.00, 1, NULL, 2),
(1, 'F3', '价值观与行为规范',     15.00, 1, NULL, 3),
(1, 'F4', '出勤与合规',           10.00, 1, '{"deductPerEvent":10}', 4),
(1, 'F5', '能力成长',              5.00, 1, '{"requiredHours":24}', 5),
(1, 'F6', '协作评价与历史绩效趋势', 10.00, 1, NULL, 6);

-- -------------------------------------------------------------
-- 10. 五条硬约束
-- -------------------------------------------------------------
INSERT INTO perf_hard_constraint (scheme_id, constraint_code, constraint_name, threshold_value, threshold_unit, action_type, ceiling_grade, enabled, remark) VALUES
(1, 'HC_DISCIPLINE_VETO', '重大违纪一票否决',  0.00,  'PERCENT', 'BOTH',         'C',      1, 'disciplineLevel 为 DEMERIT/MAJOR 时触发，无实际阈值'),
(1, 'HC_ATTENDANCE',      '出勤不达标封顶',    80.00, 'PERCENT', 'CEILING_GRADE','B',      1, 'attendanceRate < 80.00 触发，等号不触发'),
(1, 'HC_KPI_LOW',         '关键量化指标严重未达', 60.00,'PERCENT', 'CEILING_GRADE','B_PLUS', 1, '存在 weight>=15 的 F1 指标 rate < 60.00 触发'),
(1, 'HC_DATA_MISSING',    '数据缺失超限',      20.00, 'PERCENT', 'FORCE_MANUAL', NULL,     1, '必填数据点缺失率 > 20.00% 触发'),
(1, 'HC_SCORE_GAP',       '自评主管评价差距过大', 25.00,'SCORE',  'FORCE_MANUAL', NULL,     1, '|self_total-manager_total| > 25.00 触发');

-- -------------------------------------------------------------
-- 11. 六档等级
-- -------------------------------------------------------------
INSERT INTO perf_grade_band (scheme_id, grade_code, grade_name, min_score, max_score, sort_no) VALUES
(1, 'S',      '卓越',   95.00, 999.00, 1),
(1, 'A',      '优秀',   90.00, 95.00,  2),
(1, 'B_PLUS', '良好+',  80.00, 90.00,  3),
(1, 'B',      '良好',   70.00, 80.00,  4),
(1, 'C',      '待改进', 60.00, 70.00,  5),
(1, 'D',      '不合格',  0.00, 60.00,  6);

-- -------------------------------------------------------------
-- 12. 审批节点配置
-- -------------------------------------------------------------
INSERT INTO appr_node_config (biz_type, scope_type, scope_id, node_code, node_name, node_seq, assignee_type, assignee_value, sign_type, allow_return, return_to_node, due_hours, remind_times, enabled) VALUES
('PERF_RECORD', 'GLOBAL', 0, 'N1_DEPT', '部门评审', 10, 'DEPT_LEADER',   '*',              'ANY', 1, NULL,      48, 3, 1),
('PERF_RECORD', 'GLOBAL', 0, 'N2_HR',   'HR 复核',  20, 'ROLE',          'HR_SPECIALIST', 'ANY', 1, 'N1_DEPT', 24, 3, 1),
('PERF_RECORD', 'GLOBAL', 0, 'N3_FINAL','终审',     30, 'ROLE',          'EXECUTIVE',     'ANY', 1, 'N2_HR',  24, 3, 1),
('APPEAL',      'GLOBAL', 0, 'APPEAL_REVIEW', '申诉复核', 10, 'ROLE',    'EXECUTIVE',     'ANY', 1, 'N1_DEPT', 48, 3, 1);

-- -------------------------------------------------------------
-- 13. 四名验证员工的目标（一员工一周期一份）
-- -------------------------------------------------------------
INSERT INTO perf_target (id, cycle_id, employee_id, dept_id, scheme_id, status, distributed_at, confirmed_at, dispute_reason) VALUES
(1, 3, 5, 2, 1, 'CONFIRMED', '2026-10-09 09:00:00', '2026-10-12 09:00:00', NULL),
(2, 3, 6, 2, 1, 'CONFIRMED', '2026-10-09 09:00:00', '2026-10-12 09:00:00', NULL),
(3, 3, 7, 3, 1, 'CONFIRMED', '2026-10-09 09:00:00', '2026-10-12 09:00:00', NULL),
(4, 3, 8, 4, 1, 'CONFIRMED', '2026-10-09 09:00:00', '2026-10-12 09:00:00', NULL);

-- 目标明细：4 人 × 10 项
INSERT INTO perf_target_item (id, target_id, scheme_item_id, indicator_id, factor_code, target_value, challenge_value, weight_snapshot) VALUES
(1,  1, 1,  1,  'F1', 200.00, 240.00, 18.00),
(2,  1, 2,  2,  'F1', 95.00,  100.00, 6.00),
(3,  1, 3,  3,  'F1', 12.00,  15.00,  5.00),
(4,  1, 4,  4,  'F1', 30.00,  36.00,  5.00),
(5,  1, 5,  5,  'F1', 90.00,  95.00,  2.00),
(6,  1, 6,  6,  'F1', 98.00,  100.00, 2.00),
(7,  1, 7,  7,  'F1', 100.00, 105.00, 1.00),
(8,  1, 8,  8,  'F1', 100.00, 105.00, 1.00),
(9,  1, 9,  9,  'F2', NULL,    NULL,    20.00),
(10, 1, 10, 10, 'F3', NULL,    NULL,    15.00),

(11, 2, 1,  1,  'F1', 200.00, 240.00, 18.00),
(12, 2, 2,  2,  'F1', 95.00,  100.00, 6.00),
(13, 2, 3,  3,  'F1', 12.00,  15.00,  5.00),
(14, 2, 4,  4,  'F1', 30.00,  36.00,  5.00),
(15, 2, 5,  5,  'F1', 90.00,  95.00,  2.00),
(16, 2, 6,  6,  'F1', 98.00,  100.00, 2.00),
(17, 2, 7,  7,  'F1', 100.00, 105.00, 1.00),
(18, 2, 8,  8,  'F1', 100.00, 105.00, 1.00),
(19, 2, 9,  9,  'F2', NULL,    NULL,    20.00),
(20, 2, 10, 10, 'F3', NULL,    NULL,    15.00),

(21, 3, 1,  1,  'F1', 200.00, 240.00, 18.00),
(22, 3, 2,  2,  'F1', 95.00,  100.00, 6.00),
(23, 3, 3,  3,  'F1', 12.00,  15.00,  5.00),
(24, 3, 4,  4,  'F1', 30.00,  36.00,  5.00),
(25, 3, 5,  5,  'F1', 90.00,  95.00,  2.00),
(26, 3, 6,  6,  'F1', 98.00,  100.00, 2.00),
(27, 3, 7,  7,  'F1', 100.00, 105.00, 1.00),
(28, 3, 8,  8,  'F1', 100.00, 105.00, 1.00),
(29, 3, 9,  9,  'F2', NULL,    NULL,    20.00),
(30, 3, 10, 10, 'F3', NULL,    NULL,    15.00),

(31, 4, 1,  1,  'F1', 200.00, 240.00, 18.00),
(32, 4, 2,  2,  'F1', 95.00,  100.00, 6.00),
(33, 4, 3,  3,  'F1', 12.00,  15.00,  5.00),
(34, 4, 4,  4,  'F1', 30.00,  36.00,  5.00),
(35, 4, 5,  5,  'F1', 90.00,  95.00,  2.00),
(36, 4, 6,  6,  'F1', 98.00,  100.00, 2.00),
(37, 4, 7,  7,  'F1', 100.00, 105.00, 1.00),
(38, 4, 8,  8,  'F1', 100.00, 105.00, 1.00),
(39, 4, 9,  9,  'F2', NULL,    NULL,    20.00),
(40, 4, 10, 10, 'F3', NULL,    NULL,    15.00);

-- -------------------------------------------------------------
-- 14. 历史已办结考评单（供 F6 历史趋势取数）
-- A=E1001 77/79，B=E1002 78/78，C=E1003 63/65，D=E1004 仅 73
-- -------------------------------------------------------------
INSERT INTO perf_record (id, record_no, cycle_id, employee_id, dept_id, scheme_id, target_id, status, self_total, manager_total, final_total, final_grade, submitted_at, dept_passed_at, hr_passed_at, finalized_at, closed_at, aux_data) VALUES
(1001, 'RC202606300001', 1, 5, 2, 1, 1, 'CLOSED', 80.00, 78.00, 77.00, 'B', '2026-06-18 10:00:00', '2026-06-22 10:00:00', '2026-06-26 10:00:00', '2026-06-29 10:00:00', '2026-06-30 10:00:00', NULL),
(1002, 'RC202609300002', 2, 5, 2, 1, 1, 'CLOSED', 82.00, 80.00, 79.00, 'B', '2026-09-18 10:00:00', '2026-09-22 10:00:00', '2026-09-26 10:00:00', '2026-09-29 10:00:00', '2026-09-30 10:00:00', NULL),
(1011, 'RC202606300011', 1, 6, 2, 1, 2, 'CLOSED', 79.00, 79.00, 78.00, 'B', '2026-06-18 10:00:00', '2026-06-22 10:00:00', '2026-06-26 10:00:00', '2026-06-29 10:00:00', '2026-06-30 10:00:00', NULL),
(1012, 'RC202609300012', 2, 6, 2, 1, 2, 'CLOSED', 79.00, 79.00, 78.00, 'B', '2026-09-18 10:00:00', '2026-09-22 10:00:00', '2026-09-26 10:00:00', '2026-09-29 10:00:00', '2026-09-30 10:00:00', NULL),
(1021, 'RC202606300021', 1, 7, 3, 1, 3, 'CLOSED', 70.00, 62.00, 63.00, 'C', '2026-06-18 10:00:00', '2026-06-22 10:00:00', '2026-06-26 10:00:00', '2026-06-29 10:00:00', '2026-06-30 10:00:00', NULL),
(1022, 'RC202609300022', 2, 7, 3, 1, 3, 'CLOSED', 71.00, 64.00, 65.00, 'C', '2026-09-18 10:00:00', '2026-09-22 10:00:00', '2026-09-26 10:00:00', '2026-09-29 10:00:00', '2026-09-30 10:00:00', NULL),
(1031, 'RC202609300031', 2, 8, 4, 1, 4, 'CLOSED', 75.00, 71.00, 73.00, 'B', '2026-09-18 10:00:00', '2026-09-22 10:00:00', '2026-09-26 10:00:00', '2026-09-29 10:00:00', '2026-09-30 10:00:00', NULL);

-- -------------------------------------------------------------
-- 15. 四张当前考评单（DEPT_PASSED，待 HR 复核 / AFTER_DEPT 口径）
-- -------------------------------------------------------------
INSERT INTO perf_record (id, record_no, cycle_id, employee_id, dept_id, scheme_id, target_id, status, current_node_code, self_total, manager_total, submitted_at, dept_passed_at, deadline_at, aux_data, remark) VALUES
(2001, 'RC202611020001', 3, 5, 2, 1, 1, 'DEPT_PASSED', 'N2_HR', 94.00, 88.00, '2026-10-28 10:00:00', '2026-11-01 10:00:00', '2026-11-20 23:59:59',
 '{"attendanceRate":92.00,"disciplineEvents":0,"disciplineLevel":"NONE","trainingHours":20,"requiredTrainingHours":24,"abilityTestAvg":85.00,"peerScore":80.00,"lastCycleCodes":["2026-Q2","2026-Q3"]}',
 '案例A 正常：期望 B_PLUS，无需人工'),
(2002, 'RC202611020002', 3, 6, 2, 1, 2, 'DEPT_PASSED', 'N2_HR', 80.00, 80.00, '2026-10-28 10:00:00', '2026-11-01 10:00:00', '2026-11-20 23:59:59',
 '{"attendanceRate":80.00,"disciplineEvents":0,"disciplineLevel":"NONE","trainingHours":20,"requiredTrainingHours":24,"abilityTestAvg":65.00,"peerScore":78.00,"lastCycleCodes":["2026-Q2","2026-Q3"]}',
 '案例B 临界：期望 79.94→B，边界等号不触发'),
(2003, 'RC202611020003', 3, 7, 3, 1, 3, 'DEPT_PASSED', 'N2_HR', 91.00, 64.00, '2026-10-28 10:00:00', '2026-11-01 10:00:00', '2026-11-20 23:59:59',
 '{"attendanceRate":76.00,"disciplineEvents":1,"disciplineLevel":"DEMERIT","trainingHours":20,"requiredTrainingHours":24,"abilityTestAvg":55.00,"peerScore":78.00,"lastCycleCodes":["2026-Q2","2026-Q3"]}',
 '案例C 冲突：期望 C，四条约束命中，强制人工'),
(2004, 'RC202611020004', 3, 8, 4, 1, 4, 'DEPT_PASSED', 'N2_HR', 78.00, 74.00, '2026-10-28 10:00:00', '2026-11-01 10:00:00', '2026-11-20 23:59:59',
 '{"attendanceRate":88.00,"disciplineEvents":0,"disciplineLevel":"NONE","requiredTrainingHours":24,"peerScore":74.00,"lastCycleCodes":["2026-Q3"]}',
 '案例D 缺失：期望 MANUAL_REQUIRED，F1 缺失 3 项');

-- -------------------------------------------------------------
-- 16. 当前考评单指标明细（4 人 × 10 项）
-- -------------------------------------------------------------
INSERT INTO perf_record_item (id, record_id, scheme_item_id, indicator_id, factor_code, weight_snapshot, target_value_snapshot, actual_value, achievement_rate, self_score, manager_score, hr_score, final_score, self_comment, manager_comment, data_source) VALUES
-- E1001 案例A：F1=90.00
(1,  2001, 1,  1,  'F1', 18.00, 200.00, 176.88, 88.44,  88.44,  88.44,  NULL, NULL, NULL, NULL, 'SEED'),
(2,  2001, 2,  2,  'F1', 6.00,  95.00,  64.60,  68.00,  68.00,  68.00,  NULL, NULL, NULL, NULL, 'SEED'),
(3,  2001, 3,  3,  'F1', 5.00,  12.00,  13.20,  110.00, 100.00, 100.00, NULL, NULL, NULL, NULL, 'SEED'),
(4,  2001, 4,  4,  'F1', 5.00,  30.00,  33.00,  110.00, 100.00, 100.00, NULL, NULL, NULL, NULL, 'SEED'),
(5,  2001, 5,  5,  'F1', 2.00,  90.00,  108.00, 120.00, 100.00, 100.00, NULL, NULL, NULL, NULL, 'SEED'),
(6,  2001, 6,  6,  'F1', 2.00,  98.00,  107.80, 110.00, 100.00, 100.00, NULL, NULL, NULL, NULL, 'SEED'),
(7,  2001, 7,  7,  'F1', 1.00,  100.00, 112.00, 112.00, 100.00, 100.00, NULL, NULL, NULL, NULL, 'SEED'),
(8,  2001, 8,  8,  'F1', 1.00,  100.00, 105.00, 105.00, 100.00, 100.00, NULL, NULL, NULL, NULL, 'SEED'),
(9,  2001, 9,  9,  'F2', 20.00, NULL,   NULL,   NULL,   85.00,  85.00,  NULL, NULL, NULL, '重点项目按期高质量完成', 'SEED'),
(10, 2001, 10, 10, 'F3', 15.00, NULL,   NULL,   NULL,   88.00,  88.00,  NULL, NULL, NULL, '责任心与协作表现良好',   'SEED'),

-- E1002 案例B：F1=81.85
(11, 2002, 1,  1,  'F1', 18.00, 200.00, 120.00, 60.00,  60.00,  60.00,  NULL, NULL, NULL, NULL, 'SEED'),
(12, 2002, 2,  2,  'F1', 6.00,  95.00,  94.05,  99.00,  99.00,  99.00,  NULL, NULL, NULL, NULL, 'SEED'),
(13, 2002, 3,  3,  'F1', 5.00,  12.00,  12.00,  100.00, 100.00, 100.00, NULL, NULL, NULL, NULL, 'SEED'),
(14, 2002, 4,  4,  'F1', 5.00,  30.00,  30.00,  100.00, 100.00, 100.00, NULL, NULL, NULL, NULL, 'SEED'),
(15, 2002, 5,  5,  'F1', 2.00,  90.00,  90.00,  100.00, 100.00, 100.00, NULL, NULL, NULL, NULL, 'SEED'),
(16, 2002, 6,  6,  'F1', 2.00,  98.00,  98.00,  100.00, 100.00, 100.00, NULL, NULL, NULL, NULL, 'SEED'),
(17, 2002, 7,  7,  'F1', 1.00,  100.00, 100.00, 100.00, 100.00, 100.00, NULL, NULL, NULL, NULL, 'SEED'),
(18, 2002, 8,  8,  'F1', 1.00,  100.00, 100.00, 100.00, 100.00, 100.00, NULL, NULL, NULL, NULL, 'SEED'),
(19, 2002, 9,  9,  'F2', 20.00, NULL,   NULL,   NULL,   78.00,  78.00,  NULL, NULL, NULL, '项目完成质量达标', 'SEED'),
(20, 2002, 10, 10, 'F3', 15.00, NULL,   NULL,   NULL,   80.00,  80.00,  NULL, NULL, NULL, '行为规范符合要求', 'SEED'),

-- E1003 案例C：F1=58.00
(21, 2003, 1,  1,  'F1', 18.00, 200.00, 110.00, 55.00,  55.00,  55.00,  NULL, NULL, NULL, NULL, 'SEED'),
(22, 2003, 2,  2,  'F1', 6.00,  95.00,  57.00,  60.00,  60.00,  60.00,  NULL, NULL, NULL, NULL, 'SEED'),
(23, 2003, 3,  3,  'F1', 5.00,  12.00,  7.20,   60.00,  60.00,  60.00,  NULL, NULL, NULL, NULL, 'SEED'),
(24, 2003, 4,  4,  'F1', 5.00,  30.00,  18.00,  60.00,  60.00,  60.00,  NULL, NULL, NULL, NULL, 'SEED'),
(25, 2003, 5,  5,  'F1', 2.00,  90.00,  54.00,  60.00,  60.00,  60.00,  NULL, NULL, NULL, NULL, 'SEED'),
(26, 2003, 6,  6,  'F1', 2.00,  98.00,  58.80,  60.00,  60.00,  60.00,  NULL, NULL, NULL, NULL, 'SEED'),
(27, 2003, 7,  7,  'F1', 1.00,  100.00, 65.00,  65.00,  65.00,  65.00,  NULL, NULL, NULL, NULL, 'SEED'),
(28, 2003, 8,  8,  'F1', 1.00,  100.00, 65.00,  65.00,  65.00,  65.00,  NULL, NULL, NULL, NULL, 'SEED'),
(29, 2003, 9,  9,  'F2', 20.00, NULL,   NULL,   NULL,   66.00,  66.00,  NULL, NULL, NULL, '项目延期，质量一般', 'SEED'),
(30, 2003, 10, 10, 'F3', 15.00, NULL,   NULL,   NULL,   70.00,  70.00,  NULL, NULL, NULL, '存在一次记过处分',   'SEED'),

-- E1004 案例D：F1=72.00（3 项缺失，权重 6+5+5）
(31, 2004, 1,  1,  'F1', 18.00, 200.00, 144.00, 72.00,  72.00,  72.00,  NULL, NULL, NULL, NULL, 'SEED'),
(32, 2004, 2,  2,  'F1', 6.00,  95.00,  NULL,   NULL,    NULL,   NULL,   NULL, NULL, '数据未提供', '数据未提供', 'SEED'),
(33, 2004, 3,  3,  'F1', 5.00,  12.00,  NULL,   NULL,    NULL,   NULL,   NULL, NULL, '数据未提供', '数据未提供', 'SEED'),
(34, 2004, 4,  4,  'F1', 5.00,  30.00,  NULL,   NULL,    NULL,   NULL,   NULL, NULL, '数据未提供', '数据未提供', 'SEED'),
(35, 2004, 5,  5,  'F1', 2.00,  90.00,  64.80,  72.00,  72.00,  72.00,  NULL, NULL, NULL, NULL, 'SEED'),
(36, 2004, 6,  6,  'F1', 2.00,  98.00,  70.56,  72.00,  72.00,  72.00,  NULL, NULL, NULL, NULL, 'SEED'),
(37, 2004, 7,  7,  'F1', 1.00,  100.00, 72.00,  72.00,  72.00,  72.00,  NULL, NULL, NULL, NULL, 'SEED'),
(38, 2004, 8,  8,  'F1', 1.00,  100.00, 72.00,  72.00,  72.00,  72.00,  NULL, NULL, NULL, NULL, 'SEED'),
(39, 2004, 9,  9,  'F2', 20.00, NULL,   NULL,   NULL,   80.00,  80.00,  NULL, NULL, NULL, '项目完成质量良好', 'SEED'),
(40, 2004, 10, 10, 'F3', 15.00, NULL,   NULL,   NULL,   82.00,  82.00,  NULL, NULL, NULL, '行为规范表现良好', 'SEED');

-- -------------------------------------------------------------
-- 17. 审批任务（每单：部门已过 + HR 待办）
-- -------------------------------------------------------------
INSERT INTO appr_task (id, biz_type, biz_id, node_code, node_seq, assignee_id, assignee_role, sign_type, status, action_comment, handled_at, remind_count, next_remind_at, created_at) VALUES
(1, 'PERF_RECORD', 2001, 'N1_DEPT', 10, 3, 'DEPT_MANAGER',  'ANY', 'APPROVED', '部门评审通过', '2026-11-01 10:00:00', 0, NULL, '2026-10-28 10:00:00'),
(2, 'PERF_RECORD', 2001, 'N2_HR',   20, 2, 'HR_SPECIALIST', 'ANY', 'PENDING',  NULL,           NULL,                  0, '2026-11-03 09:00:00', '2026-11-01 10:00:00'),
(3, 'PERF_RECORD', 2002, 'N1_DEPT', 10, 3, 'DEPT_MANAGER',  'ANY', 'APPROVED', '部门评审通过', '2026-11-01 10:00:00', 0, NULL, '2026-10-28 10:00:00'),
(4, 'PERF_RECORD', 2002, 'N2_HR',   20, 2, 'HR_SPECIALIST', 'ANY', 'PENDING',  NULL,           NULL,                  0, '2026-11-03 09:00:00', '2026-11-01 10:00:00'),
(5, 'PERF_RECORD', 2003, 'N1_DEPT', 10, 9, 'DEPT_MANAGER',  'ANY', 'APPROVED', '部门评审通过', '2026-11-01 10:00:00', 0, NULL, '2026-10-28 10:00:00'),
(6, 'PERF_RECORD', 2003, 'N2_HR',   20, 2, 'HR_SPECIALIST', 'ANY', 'PENDING',  NULL,           NULL,                  0, '2026-11-03 09:00:00', '2026-11-01 10:00:00'),
(7, 'PERF_RECORD', 2004, 'N1_DEPT', 10, 10,'DEPT_MANAGER',  'ANY', 'APPROVED', '部门评审通过', '2026-11-01 10:00:00', 0, NULL, '2026-10-28 10:00:00'),
(8, 'PERF_RECORD', 2004, 'N2_HR',   20, 2, 'HR_SPECIALIST', 'ANY', 'PENDING',  NULL,           NULL,                  0, '2026-11-03 09:00:00', '2026-11-01 10:00:00');

-- -------------------------------------------------------------
-- 18. 知识库演示文档 + 3 个切块（embedding 置 SKIPPED，配 Key 后可重建）
-- -------------------------------------------------------------
INSERT INTO ai_kb_document (id, doc_title, doc_category, file_path, file_hash, version_no, chunk_size, overlap, chunk_count, tags, status, enabled, remark, create_by) VALUES
(1, '绩效考核管理制度（演示样例）', 'PERFORMANCE', 'kb/demo-performance-policy.txt',
 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', 1, 500, 80, 3,
 '绩效,考核,申诉,改进', 'CHUNKED', 1, '虚构演示文档，仅用于 RAG 演示', 1);

INSERT INTO ai_kb_chunk (id, doc_id, chunk_index, content, char_count, section_path, tags, keywords, embedding, embedding_model, embedding_dim, embedding_status) VALUES
(1, 1, 0,
 '第一章 考核目的与范围。本制度适用于公司全体正式员工，考核周期分为月度、季度和年度。绩效考核旨在客观评价员工的工作业绩、能力成长与价值观表现，为薪酬调整、晋升和培训提供依据。考核结果分为 S、A、B+、B、C、D 六个等级。',
 121, '第一章 考核目的与范围', '绩效,考核,范围', '考核目的,适用范围,考核周期,等级',
 NULL, NULL, NULL, 'SKIPPED'),
(2, 1, 1,
 '第二章 考核流程。每个考核周期由 HR 发起，员工先完成自评，部门负责人进行部门评审，HR 专员复核后提交终审。自评与主管评分差距超过 25 分时，系统将强制要求人工确认。部门评审通过后，系统会自动生成系统建议等级，供 HR 参考。',
 118, '第二章 考核流程', '流程,评审,复核', '自评,部门评审,HR复核,终审,流程',
 NULL, NULL, NULL, 'SKIPPED'),
(3, 1, 2,
 '第三章 申诉与改进。员工对考核结果有异议的，应在结果发布后 7 个自然日内提交申诉，并提供相应证据材料。申诉由 HR 受理、高管裁定。申诉成立时，原考核结果按申诉结论调整并留痕。考核等级为 C 或 D 的员工，须制定改进计划，明确改进行动与完成时间。',
 126, '第三章 申诉与改进', '申诉,改进,时限', '申诉时限,证据材料,改进计划,留痕',
 NULL, NULL, NULL, 'SKIPPED');

COMMIT;
