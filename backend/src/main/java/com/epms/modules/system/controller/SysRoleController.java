package com.epms.modules.system.controller;

import com.epms.common.R;
import com.epms.modules.system.entity.SysRole;
import com.epms.modules.system.mapper.SysRoleMapper;
import com.epms.security.RequireRole;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 角色管理控制器
 */
@RestController
@RequestMapping("/system/roles")
@RequiredArgsConstructor
public class SysRoleController {
    
    private final SysRoleMapper roleMapper;
    
    /**
     * 获取角色列表
     * 权限：ADMIN, HR_SPECIALIST
     */
    @GetMapping
    @RequireRole({"ADMIN", "HR_SPECIALIST"})
    public R<List<SysRole>> getRoleList() {
        List<SysRole> roles = roleMapper.selectList(null);
        return R.ok(roles);
    }
    
    /**
     * 获取角色详情
     * 权限：ADMIN, HR_SPECIALIST
     */
    @GetMapping("/{id}")
    @RequireRole({"ADMIN", "HR_SPECIALIST"})
    public R<SysRole> getRoleById(@PathVariable Long id) {
        SysRole role = roleMapper.selectById(id);
        return R.ok(role);
    }
}
