package com.epms.modules.system.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.epms.modules.system.entity.SysDept;
import com.epms.modules.system.entity.SysUser;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

@Mapper
public interface SysUserMapper extends BaseMapper<SysUser> {
    
    /**
     * 根据部门ID查询部门
     */
    @Select("SELECT * FROM sys_dept WHERE id = #{deptId}")
    SysDept selectDeptById(Long deptId);
}
