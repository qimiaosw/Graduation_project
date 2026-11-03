package com.epms.modules.system.service;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.epms.modules.system.entity.SysDept;
import com.epms.modules.system.mapper.SysDeptMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

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
    
    /**
     * 获取部门树
     */
    public List<Map<String, Object>> getDeptTree() {
        // 获取所有启用的部门
        List<SysDept> allDepts = baseMapper.selectList(
                new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<SysDept>()
                        .eq(SysDept::getStatus, 1)
                        .orderByAsc(SysDept::getSortNo)
        );
        
        // 构建树形结构
        return buildTree(allDepts);
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
            node.put("leaderUserId", dept.getLeaderUserId());
            node.put("sortNo", dept.getSortNo());
            
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
