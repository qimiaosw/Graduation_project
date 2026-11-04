package com.epms.modules.perf.controller;

import com.epms.common.PageParam;
import com.epms.common.PageResult;
import com.epms.common.R;
import com.epms.modules.perf.entity.PerfIndicator;
import com.epms.modules.perf.service.PerfIndicatorService;
import com.epms.security.RequireRole;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 指标库 Controller
 */
@RestController
@RequestMapping("/perf/indicators")
@Tag(name = "指标库管理")
@RequiredArgsConstructor
public class PerfIndicatorController {

    private final PerfIndicatorService perfIndicatorService;

    @GetMapping
    @Operation(summary = "分页查询指标")
    @RequireRole({"ADMIN", "HR_SPECIALIST"})
    public R<PageResult<PerfIndicator>> getPage(
            @Valid PageParam pageParam,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String bizCategory,
            @RequestParam(required = false) Integer status) {
        return R.ok(perfIndicatorService.getPage(pageParam, keyword, bizCategory, status));
    }

    @GetMapping("/active")
    @Operation(summary = "获取所有启用的指标")
    @RequireRole({"ADMIN", "HR_SPECIALIST"})
    public R<List<PerfIndicator>> getActiveIndicators() {
        return R.ok(perfIndicatorService.getActiveIndicators());
    }

    @GetMapping("/category/{bizCategory}")
    @Operation(summary = "按分类获取指标")
    @RequireRole({"ADMIN", "HR_SPECIALIST"})
    public R<List<PerfIndicator>> getByCategory(@PathVariable String bizCategory) {
        return R.ok(perfIndicatorService.getByCategory(bizCategory));
    }

    @GetMapping("/{id}")
    @Operation(summary = "获取指标详情")
    @RequireRole({"ADMIN", "HR_SPECIALIST"})
    public R<PerfIndicator> getById(@PathVariable Long id) {
        return R.ok(perfIndicatorService.getById(id));
    }

    @PostMapping
    @Operation(summary = "创建指标")
    @RequireRole({"ADMIN", "HR_SPECIALIST"})
    public R<PerfIndicator> create(@RequestBody PerfIndicator indicator) {
        return R.ok(perfIndicatorService.create(indicator));
    }

    @PutMapping("/{id}")
    @Operation(summary = "更新指标")
    @RequireRole({"ADMIN", "HR_SPECIALIST"})
    public R<PerfIndicator> update(@PathVariable Long id, @RequestBody PerfIndicator indicator) {
        indicator.setId(id);
        return R.ok(perfIndicatorService.update(indicator));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "删除指标")
    @RequireRole({"ADMIN", "HR_SPECIALIST"})
    public R<Boolean> delete(@PathVariable Long id) {
        return R.ok(perfIndicatorService.delete(id));
    }

    @PostMapping("/{id}/status")
    @Operation(summary = "启用/停用指标")
    @RequireRole({"ADMIN", "HR_SPECIALIST"})
    public R<PerfIndicator> updateStatus(@PathVariable Long id, @RequestParam Integer status) {
        return R.ok(perfIndicatorService.updateStatus(id, status));
    }
}
