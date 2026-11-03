package com.epms.security;

import lombok.Data;

import java.util.Set;

@Data
public class UserContext {
    private static final ThreadLocal<UserInfo> USER_HOLDER = new ThreadLocal<>();

    public static void setUser(UserInfo user) {
        USER_HOLDER.set(user);
    }

    public static UserInfo getUser() {
        return USER_HOLDER.get();
    }

    public static Long getUserId() {
        UserInfo user = getUser();
        return user != null ? user.getUserId() : null;
    }

    public static String getUsername() {
        UserInfo user = getUser();
        return user != null ? user.getUsername() : null;
    }

    public static Set<String> getRoles() {
        UserInfo user = getUser();
        return user != null ? user.getRoles() : null;
    }

    public static Long getDeptId() {
        UserInfo user = getUser();
        return user != null ? user.getDeptId() : null;
    }

    public static String getJti() {
        UserInfo user = getUser();
        return user != null ? user.getJti() : null;
    }

    public static void clear() {
        USER_HOLDER.remove();
    }

    @Data
    public static class UserInfo {
        private Long userId;
        private String username;
        private String realName;
        private Set<String> roles;
        private Long deptId;
        private String jti;
    }
}
