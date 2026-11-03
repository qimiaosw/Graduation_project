package com.epms.modules.system.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.baomidou.mybatisplus.annotation.Version;
import com.epms.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

@Data
@EqualsAndHashCode(callSuper = true)
@TableName("sys_user")
public class SysUser extends BaseEntity {
    private String username;
    private String passwordHash;
    private String realName;
    private String employeeNo;
    private Long deptId;
    private String positionTitle;
    private String mobile;
    private String email;
    private Integer status;
    private LocalDateTime pwdChangedAt;
    private LocalDateTime lastLoginAt;
    private String lastLoginIp;

    @Version
    private Integer version;
}
