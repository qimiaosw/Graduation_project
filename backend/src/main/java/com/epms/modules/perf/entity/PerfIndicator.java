package com.epms.modules.perf.entity;

import com.epms.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.math.BigDecimal;

/**
 * 指标库实体
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class PerfIndicator extends BaseEntity {

    /**
     * 指标编码，如 KPI-SALE-01
     */
    private String indicatorCode;

    /**
     * 指标名称
     */
    private String indicatorName;

    /**
     * 业务分类：PERFORMANCE 业绩 / ABILITY 能力 / ATTITUDE 态度
     */
    private String bizCategory;

    /**
     * 评分类型：QUANTITATIVE 定量 / QUALITATIVE 定性
     */
    private String scoringType;

    /**
     * 单位：%、万元、个、项、分等
     */
    private String unit;

    /**
     * 默认权重
     */
    private BigDecimal defaultWeight;

    /**
     * 默认归属决策因子：F1-F6
     */
    private String defaultFactorCode;

    /**
     * 数据来源口径
     */
    private String dataSource;

    /**
     * 计分口径文字说明
     */
    private String scoringDesc;

    /**
     * 1 可用 0 停用
     */
    private Integer status;
}
