package com.epms.modules.system.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.epms.common.BizException;
import com.epms.common.ErrorCode;
import com.epms.modules.system.entity.SysDept;
import com.epms.modules.system.entity.SysRole;
import com.epms.modules.system.entity.SysUser;
import com.epms.modules.system.entity.SysUserRole;
import com.epms.modules.system.mapper.SysDeptMapper;
import com.epms.modules.system.mapper.SysRoleMapper;
import com.epms.modules.system.mapper.SysUserMapper;
import com.epms.modules.system.mapper.SysUserRoleMapper;
import com.epms.security.JwtUtil;
import com.epms.security.UserContext;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final SysUserMapper userMapper;
    private final SysDeptMapper deptMapper;
    private final SysRoleMapper roleMapper;
    private final SysUserRoleMapper userRoleMapper;
    private final JwtUtil jwtUtil;
    private final StringRedisTemplate redisTemplate;

    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    @Data
    public static class LoginResult {
        private String accessToken;
        private String refreshToken;
        private UserInfo userInfo;

        @Data
        public static class UserInfo {
            private Long id;
            private String username;
            private String realName;
            private Long deptId;
            private String deptName;
        }
    }

    public LoginResult login(String username, String password) {
        // 查询用户
        SysUser user = userMapper.selectOne(
                new LambdaQueryWrapper<SysUser>()
                        .eq(SysUser::getUsername, username)
                        .eq(SysUser::getStatus, 1)
        );

        if (user == null) {
            throw new BizException(ErrorCode.UNAUTHORIZED, "用户名或密码错误");
        }

        // BCrypt 密码校验
        if (!passwordEncoder.matches(password, user.getPasswordHash())) {
            throw new BizException(ErrorCode.UNAUTHORIZED, "用户名或密码错误");
        }

        // 检查账号状态
        if (user.getStatus() != 1) {
            throw new BizException(ErrorCode.UNAUTHORIZED, "账号已停用");
        }

        // 生成 token
        String jti = jwtUtil.generateJti();
        String accessToken = jwtUtil.generateAccessToken(user.getId(), username, jti);
        String refreshToken = jwtUtil.generateRefreshToken(jti);

        // 获取角色
        Set<String> roles = getUserRoles(user.getId());

        // 获取部门名称
        String deptName = null;
        if (user.getDeptId() != null) {
            SysDept dept = deptMapper.selectById(user.getDeptId());
            deptName = dept != null ? dept.getDeptName() : null;
        }

        // 设置用户上下文
        UserContext.UserInfo userInfo = new UserContext.UserInfo();
        userInfo.setUserId(user.getId());
        userInfo.setUsername(username);
        userInfo.setRealName(user.getRealName());
        userInfo.setRoles(roles);
        userInfo.setDeptId(user.getDeptId());
        userInfo.setJti(jti);

        // 保存到 Redis
        String sessionKey = "epms:auth:session:" + user.getId() + ":" + jti;
        String roleStr = String.join(",", roles);
        redisTemplate.opsForValue().set(sessionKey, roleStr, 7200, TimeUnit.SECONDS);

        // 保存 refreshToken
        String refreshKey = "epms:auth:refresh:" + refreshToken;
        redisTemplate.opsForValue().set(refreshKey, user.getId() + ":" + jti, 604800, TimeUnit.SECONDS);

        // 更新最后登录信息
        user.setLastLoginAt(LocalDateTime.now());
        userMapper.updateById(user);

        // 返回结果
        LoginResult result = new LoginResult();
        result.setAccessToken(accessToken);
        result.setRefreshToken(refreshToken);

        LoginResult.UserInfo info = new LoginResult.UserInfo();
        info.setId(user.getId());
        info.setUsername(username);
        info.setRealName(user.getRealName());
        info.setDeptId(user.getDeptId());
        info.setDeptName(deptName);
        result.setUserInfo(info);

        return result;
    }

    public void logout(Long userId, String jti, String refreshToken) {
        // 删除会话
        String sessionKey = "epms:auth:session:" + userId + ":" + jti;
        redisTemplate.delete(sessionKey);

        // 删除 refreshToken
        if (StringUtils.hasText(refreshToken)) {
            String refreshKey = "epms:auth:refresh:" + refreshToken;
            redisTemplate.delete(refreshKey);
        }
    }

    public Map<String, String> refresh(String refreshToken) {
        // 解析 refreshToken
        String jti = jwtUtil.getJti(refreshToken);

        // 检查 refreshToken 是否有效
        String refreshKey = "epms:auth:refresh:" + refreshToken;
        String sessionData = redisTemplate.opsForValue().get(refreshKey);
        if (sessionData == null) {
            throw new BizException(ErrorCode.TOKEN_EXPIRED);
        }

        String[] parts = sessionData.split(":");
        Long userId = Long.parseLong(parts[0]);
        String oldJti = parts[1];

        // 获取用户信息
        SysUser user = userMapper.selectById(userId);
        if (user == null || user.getStatus() != 1) {
            throw new BizException(ErrorCode.UNAUTHORIZED, "用户不存在或已停用");
        }

        // 生成新 token
        String newJti = jwtUtil.generateJti();
        String newAccessToken = jwtUtil.generateAccessToken(userId, user.getUsername(), newJti);

        // 删旧会话，建新会话
        String oldSessionKey = "epms:auth:session:" + userId + ":" + oldJti;
        redisTemplate.delete(oldSessionKey);

        Set<String> roles = getUserRoles(userId);
        String roleStr = String.join(",", roles);
        String newSessionKey = "epms:auth:session:" + userId + ":" + newJti;
        redisTemplate.opsForValue().set(newSessionKey, roleStr, 7200, TimeUnit.SECONDS);

        // 删除旧的 refreshToken，生成新的
        redisTemplate.delete(refreshKey);
        String newRefreshToken = jwtUtil.generateRefreshToken(newJti);
        String newRefreshKey = "epms:auth:refresh:" + newRefreshToken;
        redisTemplate.opsForValue().set(newRefreshKey, userId + ":" + newJti, 604800, TimeUnit.SECONDS);

        // 同时返回新的 accessToken 和 refreshToken，前端需要更新本地存储
        return Map.of(
                "accessToken", newAccessToken,
                "refreshToken", newRefreshToken
        );
    }

    public LoginResult.UserInfo getCurrentUser() {
        UserContext.UserInfo ctx = UserContext.getUser();
        if (ctx == null) {
            return null;
        }

        // 过滤器只从 Redis 拿到 userId/username/roles/jti，realName 和 deptId 需查库
        SysUser user = userMapper.selectById(ctx.getUserId());
        if (user == null) {
            throw new BizException(ErrorCode.UNAUTHORIZED, "用户不存在");
        }

        LoginResult.UserInfo info = new LoginResult.UserInfo();
        info.setId(user.getId());
        info.setUsername(user.getUsername());
        info.setRealName(user.getRealName());
        info.setDeptId(user.getDeptId());

        // 获取部门名称
        if (user.getDeptId() != null) {
            SysDept dept = deptMapper.selectById(user.getDeptId());
            info.setDeptName(dept != null ? dept.getDeptName() : null);
        }

        return info;
    }

    private Set<String> getUserRoles(Long userId) {
        return userRoleMapper.selectList(
                        new LambdaQueryWrapper<SysUserRole>()
                                .eq(SysUserRole::getUserId, userId)
                ).stream()
                .map(ur -> {
                    SysRole role = roleMapper.selectById(ur.getRoleId());
                    return role != null ? role.getRoleCode() : null;
                })
                .filter(StringUtils::hasText)
                .collect(Collectors.toSet());
    }
}
