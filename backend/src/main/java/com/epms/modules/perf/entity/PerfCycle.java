package com.epms.modules.perf.entity;

import com.baomidou.mybatisplus.annotation.Version;
import com.epms.common.BaseEntity;
import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 考核周期实体
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class PerfCycle extends BaseEntity {

    /**
     * 周期编码，如 2026-Q4
     */
    private String cycleCode;

    /**
     * 周期名称
     */
    private String cycleName;

    /**
     * 周期类型：MONTH/QUARTER/YEAR/CUSTOM
     */
    private String cycleType;

    /**
     * 周期开始日
     */
    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate startDate;

    /**
     * 周期结束日
     */
    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate endDate;

    /**
     * 员工自评截止
     */
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime selfDeadline;

    /**
     * 部门评审截止
     */
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime managerDeadline;

    /**
     * HR 复核截止
     */
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime hrDeadline;

    /**
     * 终审截止
     */
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime finalDeadline;

    /**
     * 状态：DRAFT/IN_PROGRESS/CLOSED
     */
    private String status;

    /**
     * 启动时间（发布周期时由 Service 写入）
     */
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime publishedAt;

    /**
     * 结束时间
     */
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime finishedAt;

    /**
     * 备注
     */
    private String remark;

    /**
     * 乐观锁版本号
     */
    @Version
    private Integer version;
}
