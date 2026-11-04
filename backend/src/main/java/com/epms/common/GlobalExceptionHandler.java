package com.epms.common;

import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.validation.BindException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

import java.util.UUID;

/**
 * 全局异常处理器
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {
    
    /**
     * 生成 traceId
     */
    private String generateTraceId() {
        return UUID.randomUUID().toString().substring(0, 8);
    }
    
    /**
     * 处理业务异常
     */
    @ExceptionHandler(BizException.class)
    public R<Object> handleBizException(BizException e, HttpServletRequest request) {
        String traceId = generateTraceId();
        log.error("BizException: {} - traceId: {}", e.getMessage(), traceId);
        return R.fail(e.getCode(), e.getMessage()).trace(traceId);
    }
    
    /**
     * 处理参数校验异常（JSR-303）
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public R<Object> handleValidationException(MethodArgumentNotValidException e, HttpServletRequest request) {
        String traceId = generateTraceId();
        String message = e.getBindingResult().getFieldErrors().stream()
                .map(err -> err.getField() + ": " + err.getDefaultMessage())
                .reduce((a, b) -> a + "; " + b)
                .orElse("Validation failed");
        log.error("ValidationException: {} - traceId: {}", message, traceId);
        return R.fail(40001, message).trace(traceId);
    }

    /**
     * 处理 @Valid 绑定到查询参数对象时的校验异常（如 PageParam）
     */
    @ExceptionHandler(BindException.class)
    public R<Object> handleBindException(BindException e, HttpServletRequest request) {
        String traceId = generateTraceId();
        String message = e.getBindingResult().getFieldErrors().stream()
                .map(FieldError::getDefaultMessage)
                .reduce((a, b) -> a + "; " + b)
                .orElse("Validation failed");
        log.error("BindException: {} - traceId: {}", message, traceId);
        return R.fail(40001, message).trace(traceId);
    }
    
    /**
     * 处理参数类型不匹配异常
     */
    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public R<Object> handleTypeMismatchException(MethodArgumentTypeMismatchException e, HttpServletRequest request) {
        String traceId = generateTraceId();
        String message = "Parameter '" + e.getName() + "' type mismatch: " + e.getMessage();
        log.error("TypeMismatchException: {} - traceId: {}", message, traceId);
        return R.fail(40001, message).trace(traceId);
    }
    
    /**
     * 处理其他异常（不允许抛出 500）
     */
    @ExceptionHandler(Exception.class)
    public R<Object> handleException(Exception e, HttpServletRequest request) {
        String traceId = generateTraceId();
        log.error("Unexpected error - traceId: {}", traceId, e);
        // 不允许抛 500，返回统一的服务器错误码
        return R.fail(50000, "Internal server error").trace(traceId);
    }
}
