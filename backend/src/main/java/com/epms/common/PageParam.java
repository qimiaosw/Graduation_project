package com.epms.common;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.Data;

/**
 * 分页请求参数
 */
@Data
public class PageParam {
    
    /**
     * 默认页码
     */
    private static final int DEFAULT_PAGE_NUM = 1;
    
    /**
     * 默认每页条数
     */
    private static final int DEFAULT_PAGE_SIZE = 10;
    
    /**
     * 最大每页条数
     */
    private static final int MAX_PAGE_SIZE = 100;
    
    /**
     * 页码，从 1 开始
     */
    @Min(value = 1, message = "pageNum must be >= 1")
    private Integer pageNum = DEFAULT_PAGE_NUM;
    
    /**
     * 每页条数
     */
    @Min(value = 1, message = "pageSize must be >= 1")
    @Max(value = 100, message = "pageSize must be <= 100")
    private Integer pageSize = DEFAULT_PAGE_SIZE;
    
    /**
     * 排序字段
     */
    private String orderBy;
    
    /**
     * 排序方向：asc/desc
     */
    private String orderDirection = "desc";
}
