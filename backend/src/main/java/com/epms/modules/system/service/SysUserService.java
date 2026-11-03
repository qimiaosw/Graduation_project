package com.epms.modules.system.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.epms.common.BizException;
import com.epms.common.ErrorCode;
import com.epms.common.PageParam;
import com.epms.common.PageResult;
import com.epms.modules.system.entity.SysDept;
import com.epms.modules.system.entity.SysRole;
import com.epms.modules.system.entity.SysUser;
import com.epms.modules.system.entity.SysUserRole;
import com.epms.modules.system.mapper.SysRoleMapper;
import com.epms.modules.system.mapper.SysUserMapper;
import com.epms.modules.system.mapper.SysUserRoleMapper;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * 用户管理服务
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class SysUserService extends ServiceImpl<SysUserMapper, SysUser> {
    
    private final SysUserRoleMapper userRoleMapper;
    private final SysRoleMapper roleMapper;
    private final SysDeptService deptService;
    private final StringRedisTemplate redisTemplate;
    
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();
    
    /**
     * 默认密码
     */
    private static final String DEFAULT_PASSWORD = "Epms@123456";
    
    /**
     * 分页查询用户列表（优化：批量查询避免 N+1）
     */
    public PageResult<UserVO> getUserPage(PageParam pageParam, Long deptId, Integer roleId, String keyword, Integer status) {
        // 构建查询条件
        LambdaQueryWrapper<SysUser> wrapper = new LambdaQueryWrapper<>();
        
        if (deptId != null) {
            wrapper.eq(SysUser::getDeptId, deptId);
        }
        if (StringUtils.hasText(keyword)) {
            wrapper.and(w -> w
                    .like(SysUser::getUsername, keyword)
                    .or().like(SysUser::getRealName, keyword)
                    .or().like(SysUser::getEmployeeNo, keyword)
            );
        }
        if (status != null) {
            wrapper.eq(SysUser::getStatus, status);
        }
        
        wrapper.orderByDesc(SysUser::getCreatedAt);
        
        // 分页查询
        IPage<SysUser> page = baseMapper.selectPage(new Page<>(pageParam.getPageNum(), pageParam.getPageSize()), wrapper);
        
        List<SysUser> users = page.getRecords();
        if (users.isEmpty()) {
            return new PageResult<>(page.getTotal(), pageParam.getPageNum(), pageParam.getPageSize(), Collections.emptyList());
        }
        
        // 批量查询：收集所有 deptId
        Set<Long> deptIds = users.stream()
                .map(SysUser::getDeptId)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());
        
        // 批量查询：收集所有 userId
        Set<Long> userIds = users.stream()
                .map(SysUser::getId)
                .collect(Collectors.toSet());
        
        // 批量查询部门
        Map<Long, SysDept> deptMap = Collections.emptyMap();
        if (!deptIds.isEmpty()) {
            List<SysDept> depts = deptService.listByIds(deptIds);
            deptMap = depts.stream().collect(Collectors.toMap(SysDept::getId, d -> d));
        }
        
        // 批量查询用户角色
        Map<Long, List<SysRole>> userRoleMap = Collections.emptyMap();
        Map<Long, SysRole> roleMap = Collections.emptyMap();
        if (!userIds.isEmpty()) {
            List<SysUserRole> userRoles = userRoleMapper.selectList(
                    new LambdaQueryWrapper<SysUserRole>().in(SysUserRole::getUserId, userIds)
            );
            Set<Long> roleIds = userRoles.stream().map(SysUserRole::getRoleId).collect(Collectors.toSet());
            if (!roleIds.isEmpty()) {
                List<SysRole> roles = roleMapper.selectBatchIds(roleIds);
                roleMap = roles.stream().collect(Collectors.toMap(SysRole::getId, r -> r));
            }
            // 按用户分组
            userRoleMap = userRoles.stream()
                    .collect(Collectors.groupingBy(SysUserRole::getUserId));
        }
        
        // 转换为 VO（使用批量查询的结果）
        List<UserVO> voList = users.stream()
                .map(user -> toUserVO(user, deptMap, userRoleMap, roleMap))
                .collect(Collectors.toList());
        
        return new PageResult<>(page.getTotal(), pageParam.getPageNum(), pageParam.getPageSize(), voList);
    }
    
    /**
     * 新增用户
     */
    @Transactional(rollbackFor = Exception.class)
    public Long createUser(CreateUserDTO dto) {
        // 检查用户名唯一性
        SysUser existUser = baseMapper.selectOne(
                new LambdaQueryWrapper<SysUser>().eq(SysUser::getUsername, dto.getUsername())
        );
        if (existUser != null) {
            throw new BizException(ErrorCode.UNIQUE_CONFLICT, "用户名已存在");
        }
        
        // 检查工号唯一性
        if (StringUtils.hasText(dto.getEmployeeNo())) {
            SysUser existEmpNo = baseMapper.selectOne(
                    new LambdaQueryWrapper<SysUser>().eq(SysUser::getEmployeeNo, dto.getEmployeeNo())
            );
            if (existEmpNo != null) {
                throw new BizException(ErrorCode.UNIQUE_CONFLICT, "工号已存在");
            }
        }
        
        // 创建用户
        SysUser user = new SysUser();
        user.setUsername(dto.getUsername());
        user.setPasswordHash(passwordEncoder.encode(DEFAULT_PASSWORD));
        user.setRealName(dto.getRealName());
        user.setEmployeeNo(dto.getEmployeeNo());
        user.setDeptId(dto.getDeptId());
        user.setPositionTitle(dto.getPositionTitle());
        user.setMobile(dto.getMobile());
        user.setEmail(dto.getEmail());
        user.setStatus(1); // 启用
        user.setPwdChangedAt(null);
        
        baseMapper.insert(user);
        
        // 分配角色
        if (dto.getRoleIds() != null && !dto.getRoleIds().isEmpty()) {
            for (Long roleId : dto.getRoleIds()) {
                SysUserRole userRole = new SysUserRole();
                userRole.setUserId(user.getId());
                userRole.setRoleId(roleId);
                userRoleMapper.insert(userRole);
            }
        }
        
        return user.getId();
    }
    
    /**
     * 更新用户
     */
    @Transactional(rollbackFor = Exception.class)
    public void updateUser(Long userId, UpdateUserDTO dto) {
        SysUser user = baseMapper.selectById(userId);
        if (user == null) {
            throw new BizException(ErrorCode.NOT_FOUND, "用户不存在");
        }
        
        // 更新基本信息
        if (StringUtils.hasText(dto.getRealName())) {
            user.setRealName(dto.getRealName());
        }
        if (dto.getDeptId() != null) {
            user.setDeptId(dto.getDeptId());
        }
        if (StringUtils.hasText(dto.getPositionTitle())) {
            user.setPositionTitle(dto.getPositionTitle());
        }
        if (StringUtils.hasText(dto.getMobile())) {
            user.setMobile(dto.getMobile());
        }
        if (StringUtils.hasText(dto.getEmail())) {
            user.setEmail(dto.getEmail());
        }
        
        baseMapper.updateById(user);
        
        // 更新角色
        if (dto.getRoleIds() != null) {
            // 删除旧角色
            userRoleMapper.delete(new LambdaQueryWrapper<SysUserRole>().eq(SysUserRole::getUserId, userId));
            
            // 添加新角色
            for (Long roleId : dto.getRoleIds()) {
                SysUserRole userRole = new SysUserRole();
                userRole.setUserId(userId);
                userRole.setRoleId(roleId);
                userRoleMapper.insert(userRole);
            }
        }
    }
    
    /**
     * 重置密码
     */
    public void resetPassword(Long userId) {
        SysUser user = baseMapper.selectById(userId);
        if (user == null) {
            throw new BizException(ErrorCode.NOT_FOUND, "用户不存在");
        }
        
        user.setPasswordHash(passwordEncoder.encode(DEFAULT_PASSWORD));
        user.setPwdChangedAt(null);
        baseMapper.updateById(user);
    }
    
    /**
     * 更新用户状态（停用/启用）
     */
    public void updateUserStatus(Long userId, Integer status) {
        SysUser user = baseMapper.selectById(userId);
        if (user == null) {
            throw new BizException(ErrorCode.NOT_FOUND, "用户不存在");
        }
        
        if (status != 0 && status != 1) {
            throw new BizException(ErrorCode.BAD_REQUEST, "状态值必须是 0 或 1");
        }
        
        user.setStatus(status);
        baseMapper.updateById(user);
        
        // 如果是停用，踢掉该用户的 Redis 会话
        if (status == 0) {
            // 删除该用户所有会话 key
            Set<String> keys = redisTemplate.keys("epms:auth:session:" + userId + ":*");
            if (keys != null && !keys.isEmpty()) {
                redisTemplate.delete(keys);
                log.info("Kicked user {} sessions, count: {}", userId, keys.size());
            }
        }
    }
    
    /**
     * 获取用户详情
     */
    public UserVO getUserById(Long userId) {
        SysUser user = baseMapper.selectById(userId);
        if (user == null) {
            throw new BizException(ErrorCode.NOT_FOUND, "用户不存在");
        }
        return toUserVO(user);
    }
    
    /**
     * 转换为 VO（单条查询，用于详情）
     */
    private UserVO toUserVO(SysUser user) {
        UserVO vo = new UserVO();
        vo.setId(user.getId());
        vo.setUsername(user.getUsername());
        vo.setRealName(user.getRealName());
        vo.setEmployeeNo(user.getEmployeeNo());
        vo.setDeptId(user.getDeptId());
        vo.setPositionTitle(user.getPositionTitle());
        vo.setMobile(user.getMobile());
        vo.setEmail(user.getEmail());
        vo.setStatus(user.getStatus());
        vo.setCreatedAt(user.getCreatedAt());
        
        // 获取部门名称
        if (user.getDeptId() != null) {
            com.epms.modules.system.entity.SysDept dept = baseMapper.selectDeptById(user.getDeptId());
            if (dept != null) {
                vo.setDeptName(dept.getDeptName());
            }
        }
        
        // 获取角色列表
        List<SysUserRole> userRoles = userRoleMapper.selectList(
                new LambdaQueryWrapper<SysUserRole>().eq(SysUserRole::getUserId, user.getId())
        );
        List<RoleDTO> roles = userRoles.stream()
                .map(ur -> {
                    SysRole role = roleMapper.selectById(ur.getRoleId());
                    if (role == null) return null;
                    RoleDTO roleDTO = new RoleDTO();
                    roleDTO.setId(role.getId());
                    roleDTO.setRoleCode(role.getRoleCode());
                    roleDTO.setRoleName(role.getRoleName());
                    return roleDTO;
                })
                .filter(Objects::nonNull)
                .collect(Collectors.toList());
        vo.setRoles(roles);
        
        return vo;
    }
    
    /**
     * 转换为 VO（批量查询，用于列表）
     */
    private UserVO toUserVO(SysUser user, Map<Long, SysDept> deptMap, 
                           Map<Long, List<SysRole>> userRoleMap, Map<Long, SysRole> roleMap) {
        UserVO vo = new UserVO();
        vo.setId(user.getId());
        vo.setUsername(user.getUsername());
        vo.setRealName(user.getRealName());
        vo.setEmployeeNo(user.getEmployeeNo());
        vo.setDeptId(user.getDeptId());
        vo.setPositionTitle(user.getPositionTitle());
        vo.setMobile(user.getMobile());
        vo.setEmail(user.getEmail());
        vo.setStatus(user.getStatus());
        vo.setCreatedAt(user.getCreatedAt());
        
        // 从 deptMap 获取部门名称
        if (user.getDeptId() != null && deptMap.containsKey(user.getDeptId())) {
            vo.setDeptName(deptMap.get(user.getDeptId()).getDeptName());
        }
        
        // 从 userRoleMap 和 roleMap 获取角色列表（内存查询，无 DB 访问）
        List<SysUserRole> userRoles = userRoleMap.getOrDefault(user.getId(), Collections.emptyList());
        List<RoleDTO> roles = userRoles.stream()
                .map(ur -> {
                    SysRole role = roleMap.get(ur.getRoleId());
                    if (role == null) return null;
                    RoleDTO roleDTO = new RoleDTO();
                    roleDTO.setId(role.getId());
                    roleDTO.setRoleCode(role.getRoleCode());
                    roleDTO.setRoleName(role.getRoleName());
                    return roleDTO;
                })
                .filter(Objects::nonNull)
                .collect(Collectors.toList());
        vo.setRoles(roles);
        
        return vo;
    }
    
    /**
     * 用户 VO
     */
    @Data
    public static class UserVO {
        private Long id;
        private String username;
        private String realName;
        private String employeeNo;
        private Long deptId;
        private String deptName;
        private String positionTitle;
        private String mobile;
        private String email;
        private Integer status;
        private LocalDateTime createdAt;
        private List<RoleDTO> roles;
    }
    
    /**
     * 角色 DTO
     */
    @Data
    public static class RoleDTO {
        private Long id;
        private String roleCode;
        private String roleName;
    }
    
    /**
     * 创建用户 DTO
     */
    @Data
    public static class CreateUserDTO {
        private String username;
        private String realName;
        private String employeeNo;
        private Long deptId;
        private String positionTitle;
        private String mobile;
        private String email;
        private List<Long> roleIds;
    }
    
    /**
     * 更新用户 DTO
     */
    @Data
    public static class UpdateUserDTO {
        private String realName;
        private Long deptId;
        private String positionTitle;
        private String mobile;
        private String email;
        private List<Long> roleIds;
    }
}
