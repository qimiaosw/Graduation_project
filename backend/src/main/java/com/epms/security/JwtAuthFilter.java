package com.epms.security;

import com.epms.common.BizException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.jsonwebtoken.Claims;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.TimeUnit;

@Slf4j
@Component
@RequiredArgsConstructor
public class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtUtil jwtUtil;
    private final StringRedisTemplate redisTemplate;
    private final ObjectMapper objectMapper = new ObjectMapper();

    private static final String BEARER_PREFIX = "Bearer ";

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        try {
            String token = extractToken(request);
            if (StringUtils.hasText(token)) {
                if (jwtUtil.isTokenExpired(token)) {
                    sendError(response, 40101, "Token expired");
                    return;
                }

                String jti = jwtUtil.getJti(token);
                Long userId = jwtUtil.getUserId(token);
                String username = jwtUtil.getUsername(token);

                // 检查 Redis 会话是否存在
                String sessionKey = "epms:auth:session:" + userId + ":" + jti;
                String sessionData = redisTemplate.opsForValue().get(sessionKey);
                if (sessionData == null) {
                    sendError(response, 40102, "Session kicked");
                    return;
                }

                // 解析角色
                Set<String> roles = Set.of(sessionData.split(","));

                // 设置用户上下文
                UserContext.UserInfo userInfo = new UserContext.UserInfo();
                userInfo.setUserId(userId);
                userInfo.setUsername(username);
                userInfo.setRoles(roles);
                userInfo.setJti(jti);
                UserContext.setUser(userInfo);

                // 滑动续期：剩余不足 30 分钟时续到 2 小时
                Long ttl = redisTemplate.getExpire(sessionKey, TimeUnit.SECONDS);
                if (ttl != null && ttl < 1800) {
                    redisTemplate.expire(sessionKey, 7200, TimeUnit.SECONDS);
                }
            }

            filterChain.doFilter(request, response);
        } catch (BizException e) {
            sendError(response, e.getCode(), e.getMessage());
        } catch (Exception e) {
            log.error("JWT filter error", e);
            sendError(response, 50000, "Internal server error");
        } finally {
            UserContext.clear();
        }
    }

    private void sendError(HttpServletResponse response, int code, String message) throws IOException {
        response.setStatus(HttpServletResponse.SC_OK);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setCharacterEncoding("UTF-8");

        Map<String, Object> result = new HashMap<>();
        result.put("code", code);
        result.put("message", message);

        response.getWriter().write(objectMapper.writeValueAsString(result));
    }

    private String extractToken(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        if (StringUtils.hasText(bearerToken) && bearerToken.startsWith(BEARER_PREFIX)) {
            return bearerToken.substring(BEARER_PREFIX.length());
        }
        return null;
    }
}
