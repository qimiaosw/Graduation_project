package com.epms.common;

import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.UUID;

@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(BizException.class)
    public R<Void> handleBizException(BizException e, HttpServletRequest request) {
        String traceId = UUID.randomUUID().toString().substring(0, 8);
        log.error("BizException: {} - traceId: {}", e.getMessage(), traceId);
        return R.fail(e.getCode(), e.getMessage()).trace(traceId);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public R<Void> handleValidationException(MethodArgumentNotValidException e, HttpServletRequest request) {
        String traceId = UUID.randomUUID().toString().substring(0, 8);
        String message = e.getBindingResult().getFieldErrors().stream()
                .map(err -> err.getField() + ": " + err.getDefaultMessage())
                .reduce((a, b) -> a + "; " + b)
                .orElse("Validation failed");
        log.error("ValidationException: {} - traceId: {}", message, traceId);
        return R.fail(40001, message).trace(traceId);
    }

    @ExceptionHandler(Exception.class)
    public R<Void> handleException(Exception e, HttpServletRequest request) {
        String traceId = UUID.randomUUID().toString().substring(0, 8);
        log.error("Unexpected error - traceId: {}", traceId, e);
        return R.fail(50000, "Internal server error").trace(traceId);
    }
}
