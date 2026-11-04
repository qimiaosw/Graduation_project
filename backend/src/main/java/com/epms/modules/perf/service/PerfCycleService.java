package com.epms.modules.perf.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.epms.common.BizException;
import com.epms.common.ErrorCode;
import com.epms.common.PageParam;
import com.epms.common.PageResult;
import com.epms.modules.perf.entity.PerfCycle;
import com.epms.modules.perf.mapper.PerfCycleMapper;
import com.epms.security.UserContext;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;

/**
 * 考核周期 Service
 */
@Service
@RequiredArgsConstructor
public class PerfCycleService extends ServiceImpl<PerfCycleMapper, PerfCycle> {

    /** 周期类型枚举，取值依据 db/schema.sql 中 cycle_type 的注释 */
    private static final Set<String> CYCLE_TYPES = Set.of("MONTH", "QUARTER", "YEAR", "CUSTOM");

    /**
     * 分页查询
     */
    public PageResult<PerfCycle> getPage(PageParam pageParam, String keyword, String status) {
        Page<PerfCycle> page = new Page<>(pageParam.getPageNum(), pageParam.getPageSize());
        LambdaQueryWrapper<PerfCycle> wrapper = new LambdaQueryWrapper<>();
        
        if (StringUtils.hasText(keyword)) {
            wrapper.and(w -> w
                    .like(PerfCycle::getCycleCode, keyword)
                    .or()
                    .like(PerfCycle::getCycleName, keyword)
            );
        }
        if (StringUtils.hasText(status)) {
            wrapper.eq(PerfCycle::getStatus, status);
        }
        
        wrapper.orderByDesc(PerfCycle::getCreatedAt);
        IPage<PerfCycle> result = this.page(page, wrapper);
        return new PageResult<>(result.getTotal(), (int) result.getCurrent(), (int) result.getSize(), result.getRecords());
    }

    /**
     * 创建周期
     */
    public PerfCycle create(PerfCycle cycle) {
        // 必填校验：全部字段在入库前显式拦截，避免 NOT NULL 约束导致 50000
        requireText(cycle.getCycleCode(), "周期编码");
        requireText(cycle.getCycleName(), "周期名称");
        requireText(cycle.getCycleType(), "周期类型");
        requireDate(cycle.getStartDate(), "开始日期");
        requireDate(cycle.getEndDate(), "结束日期");
        requireDate(cycle.getSelfDeadline(), "自评截止时间");
        requireDate(cycle.getManagerDeadline(), "部门评审截止时间");
        requireDate(cycle.getHrDeadline(), "HR 复核截止时间");
        requireDate(cycle.getFinalDeadline(), "终审截止时间");

        // 编码格式校验（长度限制）
        if (cycle.getCycleCode().length() > 32) {
            throw new BizException(ErrorCode.VALIDATION_ERROR, "周期编码不能超过32个字符");
        }

        // 周期类型枚举校验
        if (!CYCLE_TYPES.contains(cycle.getCycleType())) {
            throw new BizException(ErrorCode.VALIDATION_ERROR,
                    "周期类型只能是 MONTH/QUARTER/YEAR/CUSTOM");
        }

        // 业务校验：结束日必须晚于开始日
        if (!cycle.getEndDate().isAfter(cycle.getStartDate())) {
            throw new BizException(ErrorCode.VALIDATION_ERROR, "结束日期必须晚于开始日期");
        }

        // 业务校验：四个截止时间必须按 自评 < 部门评审 < HR 复核 < 终审 递增，且落在考核区间内
        validateDeadlines(cycle);
        
        // 检查编码唯一性（排除已删除的）
        LambdaQueryWrapper<PerfCycle> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(PerfCycle::getCycleCode, cycle.getCycleCode());
        if (this.count(wrapper) > 0) {
            throw new BizException(ErrorCode.UNIQUE_CONFLICT, "周期编码已存在");
        }
        
        cycle.setStatus("DRAFT");
        cycle.setCreateBy(UserContext.getUserId());
        cycle.setUpdateBy(UserContext.getUserId());
        this.save(cycle);
        return cycle;
    }

    private void requireText(String value, String fieldName) {
        if (!StringUtils.hasText(value)) {
            throw new BizException(ErrorCode.VALIDATION_ERROR, fieldName + "不能为空");
        }
    }

    private void requireDate(Object value, String fieldName) {
        if (value == null) {
            throw new BizException(ErrorCode.VALIDATION_ERROR, fieldName + "不能为空");
        }
    }

    /**
     * 更新周期
     */
    public PerfCycle update(PerfCycle cycle) {
        PerfCycle existing = this.getById(cycle.getId());
        if (existing == null) {
            throw new BizException(ErrorCode.NOT_FOUND, "周期不存在");
        }
        
        // 已发布或已关闭的周期不能修改
        if ("IN_PROGRESS".equals(existing.getStatus()) || "CLOSED".equals(existing.getStatus())) {
            throw new BizException(ErrorCode.STATE_CONFLICT, "已发布或已关闭的周期不能修改");
        }
        
        // 不允许通过 update 接口修改状态
        cycle.setStatus(null);
        cycle.setPublishedAt(null);
        cycle.setFinishedAt(null);
        // 周期编码创建后不可修改：置空即不参与 UPDATE，避免改成已有编码撞唯一索引
        cycle.setCycleCode(null);

        // 周期类型若传了，必须是合法枚举
        if (StringUtils.hasText(cycle.getCycleType()) && !CYCLE_TYPES.contains(cycle.getCycleType())) {
            throw new BizException(ErrorCode.VALIDATION_ERROR,
                    "周期类型只能是 MONTH/QUARTER/YEAR/CUSTOM");
        }

        // 业务校验：结束日必须晚于开始日
        LocalDate startDate = cycle.getStartDate() != null ? cycle.getStartDate() : existing.getStartDate();
        LocalDate endDate = cycle.getEndDate() != null ? cycle.getEndDate() : existing.getEndDate();
        if (endDate != null && startDate != null && !endDate.isAfter(startDate)) {
            throw new BizException(ErrorCode.VALIDATION_ERROR, "结束日期必须晚于开始日期");
        }

        // 校验截止时间：入参未传的字段用库里的旧值参与校验
        PerfCycle merged = new PerfCycle();
        merged.setStartDate(startDate);
        merged.setEndDate(endDate);
        merged.setSelfDeadline(cycle.getSelfDeadline() != null ? cycle.getSelfDeadline() : existing.getSelfDeadline());
        merged.setManagerDeadline(cycle.getManagerDeadline() != null ? cycle.getManagerDeadline() : existing.getManagerDeadline());
        merged.setHrDeadline(cycle.getHrDeadline() != null ? cycle.getHrDeadline() : existing.getHrDeadline());
        merged.setFinalDeadline(cycle.getFinalDeadline() != null ? cycle.getFinalDeadline() : existing.getFinalDeadline());
        validateDeadlines(merged);
        
        cycle.setUpdateBy(UserContext.getUserId());
        if (!this.updateById(cycle)) {
            throw new BizException(ErrorCode.LOCK_CONFLICT, "数据已被他人修改，请刷新后重试");
        }
        return this.getById(cycle.getId());
    }

    /**
     * 校验四个截止时间：顺序递增且落在 [startDate, endDate] 内。
     * 任一字段为空时跳过对应校验（发布前会强制要求四项齐全）。
     */
    private void validateDeadlines(PerfCycle cycle) {
        LocalDateTime self = cycle.getSelfDeadline();
        LocalDateTime manager = cycle.getManagerDeadline();
        LocalDateTime hr = cycle.getHrDeadline();
        LocalDateTime fin = cycle.getFinalDeadline();

        if (self != null && manager != null && !manager.isAfter(self)) {
            throw new BizException(ErrorCode.VALIDATION_ERROR, "部门评审截止时间必须晚于自评截止时间");
        }
        if (manager != null && hr != null && !hr.isAfter(manager)) {
            throw new BizException(ErrorCode.VALIDATION_ERROR, "HR 复核截止时间必须晚于部门评审截止时间");
        }
        if (hr != null && fin != null && !fin.isAfter(hr)) {
            throw new BizException(ErrorCode.VALIDATION_ERROR, "终审截止时间必须晚于 HR 复核截止时间");
        }

        LocalDate start = cycle.getStartDate();
        LocalDate end = cycle.getEndDate();
        if (start != null && end != null) {
            for (LocalDateTime d : new LocalDateTime[]{self, manager, hr, fin}) {
                if (d == null) {
                    continue;
                }
                LocalDate day = d.toLocalDate();
                if (day.isBefore(start) || day.isAfter(end)) {
                    throw new BizException(ErrorCode.VALIDATION_ERROR, "截止时间必须落在考核开始与结束日期之间");
                }
            }
        }
    }

    /**
     * 发布周期
     */
    public PerfCycle publish(Long id) {
        PerfCycle cycle = this.getById(id);
        if (cycle == null) {
            throw new BizException(ErrorCode.NOT_FOUND, "周期不存在");
        }
        if (!"DRAFT".equals(cycle.getStatus())) {
            throw new BizException(ErrorCode.STATE_CONFLICT, "只有草稿状态的周期可以发布");
        }
        
        // 业务校验：确保有时间设置
        if (cycle.getStartDate() == null || cycle.getEndDate() == null) {
            throw new BizException(ErrorCode.VALIDATION_ERROR, "请先设置考核时间");
        }
        if (cycle.getSelfDeadline() == null || cycle.getManagerDeadline() == null
                || cycle.getHrDeadline() == null || cycle.getFinalDeadline() == null) {
            throw new BizException(ErrorCode.VALIDATION_ERROR, "请先设置自评、部门评审、HR 复核、终审四个截止时间");
        }
        validateDeadlines(cycle);
        
        cycle.setStatus("IN_PROGRESS");
        cycle.setPublishedAt(LocalDateTime.now());
        cycle.setUpdateBy(UserContext.getUserId());
        if (!this.updateById(cycle)) {
            throw new BizException(ErrorCode.LOCK_CONFLICT, "数据已被他人修改，请刷新后重试");
        }
        return cycle;
    }

    /**
     * 关闭周期
     */
    public PerfCycle close(Long id) {
        PerfCycle cycle = this.getById(id);
        if (cycle == null) {
            throw new BizException(ErrorCode.NOT_FOUND, "周期不存在");
        }
        if (!"IN_PROGRESS".equals(cycle.getStatus())) {
            throw new BizException(ErrorCode.STATE_CONFLICT, "只有进行中的周期可以关闭");
        }
        
        cycle.setStatus("CLOSED");
        cycle.setFinishedAt(LocalDateTime.now());
        cycle.setUpdateBy(UserContext.getUserId());
        if (!this.updateById(cycle)) {
            throw new BizException(ErrorCode.LOCK_CONFLICT, "数据已被他人修改，请刷新后重试");
        }
        return cycle;
    }

    /**
     * 删除周期（逻辑删除，同时释放唯一编码避免重建冲突）
     */
    public boolean delete(Long id) {
        PerfCycle cycle = this.getById(id);
        if (cycle == null) {
            throw new BizException(ErrorCode.NOT_FOUND, "周期不存在");
        }
        if (!"DRAFT".equals(cycle.getStatus())) {
            throw new BizException(ErrorCode.STATE_CONFLICT, "只有草稿状态的周期可以删除");
        }
        // 逻辑删除前把编码改名，释放唯一索引（uk_cycle_code 不含 deleted 列）。
        // 用 "DEL" + 雪花ID 保证唯一且不超过 cycle_code 的 VARCHAR(32) 长度。
        PerfCycle release = new PerfCycle();
        release.setId(id);
        release.setCycleCode("DEL" + id);
        if (!this.updateById(release)) {
            throw new BizException(ErrorCode.LOCK_CONFLICT, "数据已被他人修改，请刷新后重试");
        }
        return this.removeById(id);
    }

    /**
     * 获取所有进行中的周期（下拉选择用）
     */
    public List<PerfCycle> getActiveCycles() {
        LambdaQueryWrapper<PerfCycle> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(PerfCycle::getStatus, "IN_PROGRESS");
        wrapper.orderByDesc(PerfCycle::getStartDate);
        return this.list(wrapper);
    }

    /**
     * 检查周期是否允许新增绩效记录
     */
    public boolean canAddRecord(Long cycleId) {
        PerfCycle cycle = this.getById(cycleId);
        if (cycle == null) {
            return false;
        }
        return "IN_PROGRESS".equals(cycle.getStatus());
    }

    /**
     * 校验周期允许新增绩效记录，否则抛出业务异常。
     * 供考评单等下游模块在创建记录前调用（接口层拦截）。
     */
    public void assertCanAddRecord(Long cycleId) {
        PerfCycle cycle = this.getById(cycleId);
        if (cycle == null) {
            throw new BizException(ErrorCode.NOT_FOUND, "周期不存在");
        }
        if ("CLOSED".equals(cycle.getStatus())) {
            throw new BizException(ErrorCode.BUSINESS_ERROR, "已关闭的周期不允许新增绩效记录");
        }
        if (!"IN_PROGRESS".equals(cycle.getStatus())) {
            throw new BizException(ErrorCode.BUSINESS_ERROR, "周期未发布，不允许新增绩效记录");
        }
    }

    /**
     * 获取所有周期列表
     */
    public List<PerfCycle> getAll() {
        return this.list(new LambdaQueryWrapper<PerfCycle>().orderByDesc(PerfCycle::getCreatedAt));
    }
}
