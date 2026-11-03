package com.epms.modules.system.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.epms.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

@Data
@EqualsAndHashCode(callSuper = true)
@TableName("sys_dept")
public class SysDept extends BaseEntity {
    private Long parentId;
    private String ancestors;
    private String deptCode;
    private String deptName;
    private Long leaderUserId;
    private Integer sortNo;
    private Integer status;
}
