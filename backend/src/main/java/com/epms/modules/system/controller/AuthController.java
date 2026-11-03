package com.epms.modules.system.controller;

import com.epms.common.R;
import com.epms.modules.system.service.AuthService;
import com.epms.security.RequireRole;
import com.epms.security.UserContext;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/auth")
@Tag(name = "认证管理")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @Data
    public static class LoginRequest {
        @NotBlank(message = "用户名不能为空")
        private String username;
        @NotBlank(message = "密码不能为空")
        private String password;
    }

    @Data
    public static class RefreshRequest {
        @NotBlank(message = "refreshToken 不能为空")
        private String refreshToken;
    }

    @PostMapping("/login")
    @Operation(summary = "用户登录")
    public R<AuthService.LoginResult> login(@RequestBody @Validated LoginRequest request) {
        AuthService.LoginResult result = authService.login(request.getUsername(), request.getPassword());
        return R.ok(result);
    }

    @PostMapping("/logout")
    @Operation(summary = "退出登录")
    @RequireRole
    public R<Void> logout(@RequestBody(required = false) Map<String, String> body) {
        UserContext.UserInfo user = UserContext.getUser();
        String refreshToken = body != null ? body.get("refreshToken") : null;
        if (user != null) {
            authService.logout(user.getUserId(), user.getJti(), refreshToken);
        }
        return R.ok();
    }

    @PostMapping("/refresh")
    @Operation(summary = "刷新令牌")
    public R<Map<String, String>> refresh(@RequestBody @Validated RefreshRequest request) {
        // 同时返回新的 accessToken 和 refreshToken，前端需更新本地存储
        Map<String, String> tokens = authService.refresh(request.getRefreshToken());
        return R.ok(tokens);
    }

    @GetMapping("/me")
    @Operation(summary = "获取当前用户信息")
    @RequireRole
    public R<AuthService.LoginResult.UserInfo> getCurrentUser() {
        AuthService.LoginResult.UserInfo userInfo = authService.getCurrentUser();
        return R.ok(userInfo);
    }
}
