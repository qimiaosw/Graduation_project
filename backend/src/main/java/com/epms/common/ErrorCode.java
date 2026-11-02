package com.epms.common;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public enum ErrorCode {
    SUCCESS(0, "ok"),
    BAD_REQUEST(40000, "Bad request"),
    VALIDATION_ERROR(40001, "Validation failed"),
    UNAUTHORIZED(40100, "Unauthorized"),
    TOKEN_EXPIRED(40101, "Token expired"),
    TOKEN_KICKED(40102, "Session kicked"),
    FORBIDDEN(40300, "Forbidden"),
    DATA_FORBIDDEN(40301, "Data access denied"),
    NOT_FOUND(40400, "Resource not found"),
    STATE_CONFLICT(40900, "State conflict"),
    LOCK_CONFLICT(40901, "Resource locked by another user"),
    UNIQUE_CONFLICT(40902, "Unique constraint violated"),
    BUSINESS_ERROR(42201, "Business rule violation"),
    RATE_LIMIT(42900, "Rate limit exceeded"),
    INTERNAL_ERROR(50000, "Internal server error"),
    SERVICE_UNAVAILABLE(50300, "Service unavailable"),
    AI_DISABLED(50301, "AI service disabled");

    private final int code;
    private final String message;
}
