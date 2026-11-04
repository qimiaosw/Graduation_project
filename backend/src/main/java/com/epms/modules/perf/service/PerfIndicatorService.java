package com.epms.modules.perf.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.epms.common.BizException;
import com.epms.common.ErrorCode;
import com.epms.common.PageParam;
import com.epms.common.PageResult;
import com.epms.modules.perf.entity.PerfIndicator;
import com.epms.modules.perf.mapper.PerfIndicatorMapper;
import com.epms.security.UserContext;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.util.List;
import java.util.Set;

/**
 * 指标库 Service
 */
@Service
@RequiredArgsConstructor
public class PerfIndicatorService extends ServiceImpl<PerfIndicatorMapper, PerfIndicator> {

    /** 业务分类枚举：业绩 / 能力 / 态度 */
    private static final Set<String> BIZ_CATEGORIES = Set.of("PERFORMANCE", "ABILITY", "ATTITUDE");

    /** 评分类型枚举：定量 / 定性 */
    private static final Set<String> SCORING_TYPES = Set.of("QUANTITATIVE", "QUALITATIVE");

    /**
     * 分页查询
     */
    public PageResult<PerfIndicator> getPage(PageParam pageParam, String keyword, String bizCategory, Integer status) {
        Page<PerfIndicator> page = new Page<>(pageParam.getPageNum(), pageParam.getPageSize());
        LambdaQueryWrapper<PerfIndicator> wrapper = new LambdaQueryWrapper<>();
        
        if (StringUtils.hasText(keyword)) {
            wrapper.and(w -> w
                    .like(PerfIndicator::getIndicatorCode, keyword)
                    .or()
                    .like(PerfIndicator::getIndicatorName, keyword)
            );
        }
        if (StringUtils.hasText(bizCategory)) {
            wrapper.eq(PerfIndicator::getBizCategory, bizCategory);
        }
        if (status != null) {
            wrapper.eq(PerfIndicator::getStatus, status);
        }
        
        wrapper.orderByDesc(PerfIndicator::getCreatedAt);
        IPage<PerfIndicator> result = this.page(page, wrapper);
        return new PageResult<>(result.getTotal(), (int) result.getCurrent(), (int) result.getSize(), result.getRecords());
    }

    /**
     * 创建指标
     */
    public PerfIndicator create(PerfIndicator indicator) {
        // 必填校验
        if (!StringUtils.hasText(indicator.getIndicatorCode())) {
            throw new BizException(ErrorCode.VALIDATION_ERROR, "指标编码不能为空");
        }
        if (!StringUtils.hasText(indicator.getIndicatorName())) {
            throw new BizException(ErrorCode.VALIDATION_ERROR, "指标名称不能为空");
        }
        if (!StringUtils.hasText(indicator.getBizCategory())) {
            throw new BizException(ErrorCode.VALIDATION_ERROR, "请选择业务分类");
        }
        if (!StringUtils.hasText(indicator.getScoringType())) {
            throw new BizException(ErrorCode.VALIDATION_ERROR, "请选择评分类型");
        }
        if (!StringUtils.hasText(indicator.getDefaultFactorCode())) {
            throw new BizException(ErrorCode.VALIDATION_ERROR, "请选择决策因子");
        }

        // 枚举校验：分类、评分类型只允许约定的取值
        if (!BIZ_CATEGORIES.contains(indicator.getBizCategory())) {
            throw new BizException(ErrorCode.VALIDATION_ERROR,
                    "业务分类只能是 PERFORMANCE/ABILITY/ATTITUDE");
        }
        if (!SCORING_TYPES.contains(indicator.getScoringType())) {
            throw new BizException(ErrorCode.VALIDATION_ERROR,
                    "评分类型只能是 QUANTITATIVE/QUALITATIVE");
        }
        
        // 权重校验：0-100
        if (indicator.getDefaultWeight() == null) {
            indicator.setDefaultWeight(new BigDecimal("10.00"));
        } else if (indicator.getDefaultWeight().compareTo(BigDecimal.ZERO) < 0 
                || indicator.getDefaultWeight().compareTo(new BigDecimal("100")) > 0) {
            throw new BizException(ErrorCode.VALIDATION_ERROR, "默认权重必须在 0-100 之间");
        }
        
        // 检查编码唯一性（排除已删除的）
        LambdaQueryWrapper<PerfIndicator> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(PerfIndicator::getIndicatorCode, indicator.getIndicatorCode());
        if (this.count(wrapper) > 0) {
            throw new BizException(ErrorCode.UNIQUE_CONFLICT, "指标编码已存在");
        }
        
        if (indicator.getStatus() == null) {
            indicator.setStatus(1);
        }
        indicator.setCreateBy(UserContext.getUserId());
        indicator.setUpdateBy(UserContext.getUserId());
        this.save(indicator);
        return indicator;
    }

    /**
     * 更新指标
     */
    public PerfIndicator update(PerfIndicator indicator) {
        PerfIndicator existing = this.getById(indicator.getId());
        if (existing == null) {
            throw new BizException(ErrorCode.NOT_FOUND, "指标不存在");
        }
        
        // 权重校验：0-100
        if (indicator.getDefaultWeight() != null) {
            if (indicator.getDefaultWeight().compareTo(BigDecimal.ZERO) < 0 
                    || indicator.getDefaultWeight().compareTo(new BigDecimal("100")) > 0) {
                throw new BizException(ErrorCode.VALIDATION_ERROR, "默认权重必须在 0-100 之间");
            }
        }
        
        // 不允许修改编码
        indicator.setIndicatorCode(null);

        // 枚举校验：更新时若传了分类/评分类型，也必须是合法取值
        if (StringUtils.hasText(indicator.getBizCategory()) && !BIZ_CATEGORIES.contains(indicator.getBizCategory())) {
            throw new BizException(ErrorCode.VALIDATION_ERROR,
                    "业务分类只能是 PERFORMANCE/ABILITY/ATTITUDE");
        }
        if (StringUtils.hasText(indicator.getScoringType()) && !SCORING_TYPES.contains(indicator.getScoringType())) {
            throw new BizException(ErrorCode.VALIDATION_ERROR,
                    "评分类型只能是 QUANTITATIVE/QUALITATIVE");
        }

        indicator.setUpdateBy(UserContext.getUserId());
        if (!this.updateById(indicator)) {
            throw new BizException(ErrorCode.LOCK_CONFLICT, "数据已被他人修改，请刷新后重试");
        }
        return this.getById(indicator.getId());
    }

    /**
     * 删除指标（逻辑删除，同时释放唯一编码避免重建冲突）
     */
    public boolean delete(Long id) {
        PerfIndicator indicator = this.getById(id);
        if (indicator == null) {
            throw new BizException(ErrorCode.NOT_FOUND, "指标不存在");
        }
        // 逻辑删除前把编码改名，释放唯一索引（uk_indicator_code 不含 deleted 列）。
        // 用 "DEL" + 雪花ID 保证唯一且不超过 indicator_code 的 VARCHAR(32) 长度。
        PerfIndicator release = new PerfIndicator();
        release.setId(id);
        release.setIndicatorCode("DEL" + id);
        if (!this.updateById(release)) {
            throw new BizException(ErrorCode.LOCK_CONFLICT, "数据已被他人修改，请刷新后重试");
        }
        return this.removeById(id);
    }

    /**
     * 启用/停用指标
     */
    public PerfIndicator updateStatus(Long id, Integer status) {
        PerfIndicator indicator = this.getById(id);
        if (indicator == null) {
            throw new BizException(ErrorCode.NOT_FOUND, "指标不存在");
        }
        
        if (status != 0 && status != 1) {
            throw new BizException(ErrorCode.VALIDATION_ERROR, "状态值只能是 0 或 1");
        }
        
        indicator.setStatus(status);
        indicator.setUpdateBy(UserContext.getUserId());
        if (!this.updateById(indicator)) {
            throw new BizException(ErrorCode.LOCK_CONFLICT, "数据已被他人修改，请刷新后重试");
        }
        return indicator;
    }

    /**
     * 根据分类获取指标列表
     */
    public List<PerfIndicator> getByCategory(String bizCategory) {
        LambdaQueryWrapper<PerfIndicator> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(PerfIndicator::getBizCategory, bizCategory);
        wrapper.eq(PerfIndicator::getStatus, 1);
        wrapper.orderByAsc(PerfIndicator::getIndicatorCode);
        return this.list(wrapper);
    }

    /**
     * 获取所有启用的指标
     */
    public List<PerfIndicator> getActiveIndicators() {
        LambdaQueryWrapper<PerfIndicator> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(PerfIndicator::getStatus, 1);
        wrapper.orderByAsc(PerfIndicator::getBizCategory, PerfIndicator::getIndicatorCode);
        return this.list(wrapper);
    }
}
