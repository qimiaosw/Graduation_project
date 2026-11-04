package com.epms.modules.system.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.epms.common.BizException;
import com.epms.common.ErrorCode;
import com.epms.modules.system.entity.SysDept;
import com.epms.modules.system.entity.SysUser;
import com.epms.modules.system.mapper.SysDeptMapper;
import com.epms.modules.system.mapper.SysUserMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 部门管理服务
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class SysDeptService extends ServiceImpl<SysDeptMapper, SysDept> {

    private final SysUserMapper userMapper;

    /**
     * 获取部门树
     */
    public List<Map<String, Object>> getDeptTree() {
        // 获取所有启用的部门
        List<SysDept> allDepts = baseMapper.selectList(
                new LambdaQueryWrapper<SysDept>()
                        .eq(SysDept::getStatus, 1)
                        .orderByAsc(SysDept::getSortNo)
        );

        // 构建树形结构
        return buildTree(allDepts);
    }

    /**
     * 新增部门
     */
    @Transactional(rollbackFor = Exception.class)
    public SysDept create(SysDept dept) {
        if (!StringUtils.hasText(dept.getDeptCode())) {
            throw new BizException(ErrorCode.VALIDATION_ERROR, "部门编码不能为空");
        }
        if (dept.getDeptCode().length() > 32) {
            throw new BizException(ErrorCode.VALIDATION_ERROR, "部门编码不能超过32个字符");
        }
        if (!StringUtils.hasText(dept.getDeptName())) {
            throw new BizException(ErrorCode.VALIDATION_ERROR, "部门名称不能为空");
        }
        if (dept.getDeptName().length() > 64) {
            throw new BizException(ErrorCode.VALIDATION_ERROR, "部门名称不能超过64个字符");
        }

        Long parentId = dept.getParentId() == null ? 0L : dept.getParentId();
        SysDept parent = null;
        if (parentId != 0L) {
            parent = this.getById(parentId);
            if (parent == null) {
                throw new BizException(ErrorCode.NOT_FOUND, "上级部门不存在");
            }
        }

        // 编码唯一
        if (this.count(new LambdaQueryWrapper<SysDept>().eq(SysDept::getDeptCode, dept.getDeptCode())) > 0) {
            throw new BizException(ErrorCode.UNIQUE_CONFLICT, "部门编码已存在");
        }

        dept.setParentId(parentId);
        dept.setAncestors(parent == null ? "0" : parent.getAncestors() + "," + parent.getId());
        if (dept.getSortNo() == null) {
            dept.setSortNo(0);
        }
        if (dept.getStatus() == null) {
            dept.setStatus(1);
        }
        this.save(dept);
        return dept;
    }

    /**
     * 更新部门
     */
    @Transactional(rollbackFor = Exception.class)
    public SysDept update(SysDept dept) {
        SysDept existing = this.getById(dept.getId());
        if (existing == null) {
            throw new BizException(ErrorCode.NOT_FOUND, "部门不存在");
        }

        Long parentId = dept.getParentId() == null ? existing.getParentId() : dept.getParentId();
        SysDept parent = null;
        if (parentId != null && parentId != 0L) {
            if (parentId.equals(dept.getId())) {
                throw new BizException(ErrorCode.VALIDATION_ERROR, "上级部门不能是自己");
            }
            parent = this.getById(parentId);
            if (parent == null) {
                throw new BizException(ErrorCode.NOT_FOUND, "上级部门不存在");
            }
            // 不能移动到自己的子孙节点下
            if (parent.getAncestors() != null
                    && ("," + parent.getAncestors() + ",").contains("," + dept.getId() + ",")) {
                throw new BizException(ErrorCode.VALIDATION_ERROR, "不能把部门移动到自己的下级部门下");
            }
        }

        // 编码唯一（排除自己）
        if (StringUtils.hasText(dept.getDeptCode())) {
            long dup = this.count(new LambdaQueryWrapper<SysDept>()
                    .eq(SysDept::getDeptCode, dept.getDeptCode())
                    .ne(SysDept::getId, dept.getId()));
            if (dup > 0) {
                throw new BizException(ErrorCode.UNIQUE_CONFLICT, "部门编码已存在");
            }
        } else {
            dept.setDeptCode(null);
        }

        // 父节点变化时重算自己和所有子孙的 ancestors 链
        String newAncestors = existing.getAncestors();
        if (!parentId.equals(existing.getParentId())) {
            dept.setParentId(parentId);
            newAncestors = parent == null ? "0" : parent.getAncestors() + "," + parent.getId();
            dept.setAncestors(newAncestors);
        }

        if (!this.updateById(dept)) {
            throw new BizException(ErrorCode.LOCK_CONFLICT, "数据已被他人修改，请刷新后重试");
        }

        if (!parentId.equals(existing.getParentId())) {
            refreshChildrenAncestors(dept.getId(), newAncestors);
        }
        return this.getById(dept.getId());
    }

    /**
     * 逻辑删除部门（有下级部门或有用户时拒绝；删除前释放唯一编码）
     */
    @Transactional(rollbackFor = Exception.class)
    public void delete(Long id) {
        SysDept dept = this.getById(id);
        if (dept == null) {
            throw new BizException(ErrorCode.NOT_FOUND, "部门不存在");
        }

        long children = this.count(new LambdaQueryWrapper<SysDept>().eq(SysDept::getParentId, id));
        if (children > 0) {
            throw new BizException(ErrorCode.BUSINESS_ERROR, "该部门存在下级部门，不能删除");
        }

        long users = userMapper.selectCount(new LambdaQueryWrapper<SysUser>().eq(SysUser::getDeptId, id));
        if (users > 0) {
            throw new BizException(ErrorCode.BUSINESS_ERROR, "该部门下还有用户，不能删除");
        }

        // 释放唯一索引 uk_dept_code（该索引不含 deleted 列）。
        // 用 "DEL" + 主键保证唯一且不超过 dept_code 的 VARCHAR(32)；
        // 不能简单加 "_DEL" 后缀，否则同编码部门反复删除/重建会与历史已删行的编码撞唯一键。
        SysDept release = new SysDept();
        release.setId(id);
        release.setDeptCode("DEL" + id);
        if (!this.updateById(release)) {
            throw new BizException(ErrorCode.LOCK_CONFLICT, "数据已被他人修改，请刷新后重试");
        }
        this.removeById(id);
    }

    /**
     * 父节点移动后，递归刷新子孙的 ancestors
     */
    private void refreshChildrenAncestors(Long parentId, String parentAncestors) {
        List<SysDept> children = this.list(
                new LambdaQueryWrapper<SysDept>().eq(SysDept::getParentId, parentId));
        for (SysDept child : children) {
            String ancestors = parentAncestors + "," + parentId;
            SysDept patch = new SysDept();
            patch.setId(child.getId());
            patch.setAncestors(ancestors);
            this.updateById(patch);
            refreshChildrenAncestors(child.getId(), ancestors);
        }
    }

    /**
     * 构建部门树
     */
    private List<Map<String, Object>> buildTree(List<SysDept> depts) {
        // 按父ID分组
        Map<Long, List<SysDept>> deptMap = depts.stream()
                .collect(Collectors.groupingBy(dept -> dept.getParentId() == null ? 0L : dept.getParentId()));

        // 递归构建树
        return buildTreeRecursive(0L, deptMap);
    }

    /**
     * 递归构建树
     */
    private List<Map<String, Object>> buildTreeRecursive(Long parentId, Map<Long, List<SysDept>> deptMap) {
        List<Map<String, Object>> tree = new ArrayList<>();

        List<SysDept> children = deptMap.get(parentId);
        if (children == null || children.isEmpty()) {
            return tree;
        }

        for (SysDept dept : children) {
            Map<String, Object> node = new java.util.HashMap<>();
            node.put("id", dept.getId());
            node.put("deptCode", dept.getDeptCode());
            node.put("deptName", dept.getDeptName());
            node.put("parentId", dept.getParentId());
            node.put("ancestors", dept.getAncestors());
            node.put("leaderUserId", dept.getLeaderUserId());
            node.put("sortNo", dept.getSortNo());
            node.put("status", dept.getStatus());

            // 递归获取子节点
            List<Map<String, Object>> childrenNodes = buildTreeRecursive(dept.getId(), deptMap);
            if (!childrenNodes.isEmpty()) {
                node.put("children", childrenNodes);
            }

            tree.add(node);
        }

        return tree;
    }
}