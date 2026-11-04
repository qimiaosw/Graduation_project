package com.epms.modules.perf.controller;

import com.epms.common.BizException;
import com.epms.common.ErrorCode;
import com.epms.common.PageParam;
import com.epms.common.PageResult;
import com.epms.common.R;
import com.epms.modules.perf.entity.PerfCycle;
import com.epms.modules.perf.service.PerfCycleService;
import com.epms.security.RequireRole;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 考核周期 Controller
 */
@RestController
@RequestMapping("/perf/cycles")
@Tag(name = "考核周期管理")
@RequiredArgsConstructor
public class PerfCycleController {

    private final PerfCycleService perfCycleService;

    @GetMapping
    @Operation(summary = "分页查询周期")
    @RequireRole({"ADMIN", "HR_SPECIALIST"})
    public R<PageResult<PerfCycle>> getPage(
            @Valid PageParam pageParam,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String status) {
        return R.ok(perfCycleService.getPage(pageParam, keyword, status));
    }

    @GetMapping("/all")
    @Operation(summary = "获取所有周期")
    @RequireRole({"ADMIN", "HR_SPECIALIST"})
    public R<List<PerfCycle>> getAll() {
        return R.ok(perfCycleService.getAll());
    }

    @GetMapping("/active")
    @Operation(summary = "获取进行中的周期（下拉选择用）")
    @RequireRole({"ADMIN", "HR_SPECIALIST", "DEPT_MANAGER"})
    public R<List<PerfCycle>> getActiveCycles() {
        return R.ok(perfCycleService.getActiveCycles());
    }

    @GetMapping("/{id}")
    @Operation(summary = "获取周期详情")
    @RequireRole({"ADMIN", "HR_SPECIALIST"})
    public R<PerfCycle> getById(@PathVariable Long id) {
        return R.ok(perfCycleService.getById(id));
    }

    @PostMapping
    @Operation(summary = "创建周期")
    @RequireRole({"ADMIN", "HR_SPECIALIST"})
    public R<PerfCycle> create(@RequestBody PerfCycle cycle) {
        return R.ok(perfCycleService.create(cycle));
    }

    @PutMapping("/{id}")
    @Operation(summary = "更新周期")
    @RequireRole({"ADMIN", "HR_SPECIALIST"})
    public R<PerfCycle> update(@PathVariable Long id, @RequestBody PerfCycle cycle) {
        cycle.setId(id);
        return R.ok(perfCycleService.update(cycle));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "删除周期")
    @RequireRole({"ADMIN", "HR_SPECIALIST"})
    public R<Boolean> delete(@PathVariable Long id) {
        return R.ok(perfCycleService.delete(id));
    }

    @PostMapping("/{id}/publish")
    @Operation(summary = "发布周期")
    @RequireRole({"ADMIN", "HR_SPECIALIST"})
    public R<PerfCycle> publish(@PathVariable Long id) {
        return R.ok(perfCycleService.publish(id));
    }

    @PostMapping("/{id}/close")
    @Operation(summary = "关闭周期")
    @RequireRole({"ADMIN", "HR_SPECIALIST"})
    public R<PerfCycle> close(@PathVariable Long id) {
        return R.ok(perfCycleService.close(id));
    }

    @GetMapping("/{id}/can-add-record")
    @Operation(summary = "校验该周期是否允许新增绩效记录（已关闭周期返回 allowed=false）")
    @RequireRole({"ADMIN", "HR_SPECIALIST", "DEPT_MANAGER"})
    public R<Map<String, Object>> canAddRecord(@PathVariable Long id) {
        PerfCycle cycle = perfCycleService.getById(id);
        if (cycle == null) {
            throw new BizException(ErrorCode.NOT_FOUND, "周期不存在");
        }
        boolean allowed = perfCycleService.canAddRecord(id);
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("cycleId", id);
        data.put("cycleStatus", cycle.getStatus());
        data.put("allowed", allowed);
        data.put("reason", allowed ? null : ("CLOSED".equals(cycle.getStatus())
                ? "已关闭的周期不允许新增绩效记录" : "周期未发布，不允许新增绩效记录"));
        return R.ok(data);
    }
}
