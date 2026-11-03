package com.epms.modules.system.controller;

import com.epms.common.PageParam;
import com.epms.common.PageResult;
import com.epms.common.R;
import com.epms.modules.system.service.SysUserService;
import com.epms.security.RequireRole;
import com.epms.security.UserContext;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

/**
 * 用户管理控制器
 */
@RestController
@RequestMapping("/system/users")
@RequiredArgsConstructor
public class SysUserController {
    
    private final SysUserService userService;
    
    /**
     * 获取用户分页列表
     * 权限：ADMIN, HR_SPECIALIST
     */
    @GetMapping
    @RequireRole({"ADMIN", "HR_SPECIALIST"})
    public R<PageResult<SysUserService.UserVO>> getUserPage(
            @Valid PageParam pageParam,
            @RequestParam(required = false) Long deptId,
            @RequestParam(required = false) Integer roleId,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Integer status) {
        
        // roleId 筛选需要特殊处理（用户角色关联查询）
        // 这里先简化处理，实际应该用子查询
        PageResult<SysUserService.UserVO> result = userService.getUserPage(pageParam, deptId, roleId, keyword, status);
        return R.ok(result);
    }
    
    /**
     * 获取用户详情
     * 权限：ADMIN, HR_SPECIALIST
     */
    @GetMapping("/{id}")
    @RequireRole({"ADMIN", "HR_SPECIALIST"})
    public R<SysUserService.UserVO> getUserById(@PathVariable Long id) {
        SysUserService.UserVO user = userService.getUserById(id);
        return R.ok(user);
    }
    
    /**
     * 新增用户
     */
    @PostMapping
    @RequireRole({"ADMIN"})
    public R<Long> createUser(@Valid @RequestBody SysUserService.CreateUserDTO dto) {
        Long userId = userService.createUser(dto);
        return R.ok(userId);
    }
    
    /**
     * 更新用户
     */
    @PutMapping("/{id}")
    @RequireRole({"ADMIN"})
    public R<Void> updateUser(@PathVariable Long id, @Valid @RequestBody SysUserService.UpdateUserDTO dto) {
        userService.updateUser(id, dto);
        return R.ok();
    }
    
    /**
     * 重置密码
     */
    @PostMapping("/{id}/reset-password")
    @RequireRole({"ADMIN"})
    public R<Void> resetPassword(@PathVariable Long id) {
        userService.resetPassword(id);
        return R.ok();
    }
    
    /**
     * 更新用户状态（停用/启用）
     */
    @PostMapping("/{id}/status")
    @RequireRole({"ADMIN"})
    public R<Void> updateUserStatus(@PathVariable Long id, @RequestParam Integer status) {
        userService.updateUserStatus(id, status);
        return R.ok();
    }
}
