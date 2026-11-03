package com.epms.modules.system.controller;

import com.epms.common.PageParam;
import com.epms.common.PageResult;
import com.epms.common.R;
import com.epms.modules.system.entity.SysDept;
import com.epms.modules.system.service.SysDeptService;
import com.epms.security.RequireRole;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 部门管理控制器
 */
@RestController
@RequestMapping("/system/depts")
@RequiredArgsConstructor
public class SysDeptController {
    
    private final SysDeptService deptService;
    
    /**
     * 获取部门树
     * 权限：只需登录
     */
    @GetMapping("/tree")
    @RequireRole({})
    public R<List<Map<String, Object>>> getDeptTree() {
        List<Map<String, Object>> tree = deptService.getDeptTree();
        return R.ok(tree);
    }
    
    /**
     * 获取所有部门列表（扁平）
     * 权限：ADMIN, HR_SPECIALIST
     */
    @GetMapping
    @RequireRole({"ADMIN", "HR_SPECIALIST"})
    public R<List<SysDept>> getDeptList() {
        List<SysDept> list = deptService.list();
        return R.ok(list);
    }
    
    /**
     * 获取部门详情
     * 权限：ADMIN, HR_SPECIALIST
     */
    @GetMapping("/{id}")
    @RequireRole({"ADMIN", "HR_SPECIALIST"})
    public R<SysDept> getDeptById(@PathVariable Long id) {
        SysDept dept = deptService.getById(id);
        if (dept == null) {
            return R.fail(40400, "部门不存在");
        }
        return R.ok(dept);
    }
}
