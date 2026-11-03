package com.epms.security;

import com.epms.common.BizException;
import com.epms.common.ErrorCode;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.HandlerInterceptor;

import java.util.Arrays;
import java.util.Set;

@Slf4j
@Component
public class RoleInterceptor implements HandlerInterceptor {

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler)
            throws Exception {
        if (!(handler instanceof HandlerMethod)) {
            return true;
        }
        HandlerMethod handlerMethod = (HandlerMethod) handler;

        RequireRole requireRole = handlerMethod.getMethodAnnotation(RequireRole.class);
        if (requireRole == null) {
            requireRole = handlerMethod.getBeanType().getAnnotation(RequireRole.class);
        }

        // 没有 @RequireRole 注解，直接放行
        if (requireRole == null) {
            return true;
        }

        String[] requiredRoles = requireRole.value();

        // 空数组表示只要已登录即可（不需要特定角色）
        if (requiredRoles == null || requiredRoles.length == 0) {
            // 检查是否已登录（UserContext 是否有值）
            if (UserContext.getUser() == null) {
                throw new BizException(ErrorCode.UNAUTHORIZED);
            }
            return true;
        }

        Set<String> userRoles = UserContext.getRoles();
        if (userRoles == null || userRoles.isEmpty()) {
            throw new BizException(ErrorCode.UNAUTHORIZED);
        }

        boolean hasRole = Arrays.stream(requiredRoles)
                .anyMatch(role -> userRoles.contains(role));

        if (!hasRole) {
            throw new BizException(ErrorCode.FORBIDDEN);
        }

        return true;
    }
}
