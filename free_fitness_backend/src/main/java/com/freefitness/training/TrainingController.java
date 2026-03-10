package com.freefitness.training;

import com.freefitness.common.Result;
import com.freefitness.training.dto.*;
import com.freefitness.training.entity.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 运动训练接口
 */
@Tag(name = "运动训练", description = "动作库 / 动作组 / 训练计划 / 训练日志 / 统计报告")
@RestController
@RequestMapping("/api/v1/training")
@RequiredArgsConstructor
public class TrainingController {

    private final TrainingService trainingService;

    // ──────── 3.2 动作库 ────────

    @Operation(summary = "搜索动作库（支持 category/level/keyword 过滤，分页）")
    @GetMapping("/exercises")
    public Result<Page<Exercise>> searchExercises(
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String level,
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "0")  int page,
            @RequestParam(defaultValue = "20") int size) {
        return Result.success(trainingService.searchExercises(category, level, keyword, page, size));
    }

    @Operation(summary = "查询单个动作详情")
    @GetMapping("/exercises/{exerciseId}")
    public Result<Exercise> getExercise(@PathVariable Long exerciseId) {
        return Result.success(trainingService.getExercise(exerciseId));
    }

    @Operation(summary = "新增自定义动作（isCustom 自动为 true）")
    @PostMapping("/exercises")
    public Result<Exercise> createExercise(@RequestBody Exercise req) {
        return Result.success(trainingService.createExercise(req));
    }

    @Operation(summary = "更新自定义动作（系统内置只读）")
    @PutMapping("/exercises/{exerciseId}")
    public Result<Exercise> updateExercise(@PathVariable Long exerciseId,
                                           @RequestBody Exercise req) {
        return Result.success(trainingService.updateExercise(exerciseId, req));
    }

    @Operation(summary = "删除自定义动作（系统内置不可删）")
    @DeleteMapping("/exercises/{exerciseId}")
    public Result<Void> deleteExercise(@PathVariable Long exerciseId) {
        trainingService.deleteExercise(exerciseId);
        return Result.success();
    }

    // ──────── 3.3 动作组内动作 ────────

    @Operation(summary = "查询动作组内的所有动作（含 Exercise 详情）")
    @GetMapping("/groups/{groupId}/actions")
    public Result<List<ActionDetail>> getGroupActions(@PathVariable Long groupId) {
        return Result.success(trainingService.getGroupActions(groupId));
    }

    @Operation(summary = "批量替换动作组内的动作列表（先删后插）")
    @PutMapping("/groups/{groupId}/actions")
    public Result<List<ActionDetail>> replaceGroupActions(@PathVariable Long groupId,
                                                          @RequestBody List<Action> actions) {
        return Result.success(trainingService.replaceGroupActions(groupId, actions));
    }

    // ──────── 3.4 动作组 CRUD ────────

    @Operation(summary = "搜索动作组（支持 category/level/keyword 过滤，分页）")
    @GetMapping("/groups")
    public Result<Page<TrainingGroup>> searchGroups(
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String level,
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "0")  int page,
            @RequestParam(defaultValue = "20") int size) {
        return Result.success(trainingService.searchGroups(category, level, keyword, page, size));
    }

    @Operation(summary = "查询动作组详情（含嵌套 Action 列表）")
    @GetMapping("/groups/{groupId}")
    public Result<GroupDetail> getGroupDetail(@PathVariable Long groupId) {
        return Result.success(trainingService.getGroupDetail(groupId));
    }

    @Operation(summary = "创建动作组（可同时传入初始 actions）")
    @PostMapping("/groups")
    public Result<GroupDetail> createGroup(
            @RequestBody GroupCreateRequest req) {
        return Result.success(trainingService.createGroup(req.getGroup(), req.getActions()));
    }

    @Operation(summary = "更新动作组基本信息")
    @PutMapping("/groups/{groupId}")
    public Result<TrainingGroup> updateGroup(@PathVariable Long groupId,
                                             @RequestBody TrainingGroup req) {
        return Result.success(trainingService.updateGroup(groupId, req));
    }

    @Operation(summary = "删除动作组（被计划引用时拒绝删除）")
    @DeleteMapping("/groups/{groupId}")
    public Result<Void> deleteGroup(@PathVariable Long groupId) {
        trainingService.deleteGroup(groupId);
        return Result.success();
    }

    // ──────── 3.5 训练计划 CRUD ────────

    @Operation(summary = "搜索训练计划（支持 category/level/keyword 过滤，分页）")
    @GetMapping("/plans")
    public Result<Page<Plan>> searchPlans(
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String level,
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "0")  int page,
            @RequestParam(defaultValue = "20") int size) {
        return Result.success(trainingService.searchPlans(category, level, keyword, page, size));
    }

    @Operation(summary = "查询训练计划详情（含完整嵌套：天→组→动作）")
    @GetMapping("/plans/{planId}")
    public Result<PlanDetail> getPlanDetail(@PathVariable Long planId) {
        return Result.success(trainingService.getPlanDetail(planId));
    }

    @Operation(summary = "创建训练计划（含每天动作组分配）")
    @PostMapping("/plans")
    public Result<PlanDetail> createPlan(@RequestBody PlanRequest req) {
        return Result.success(trainingService.createPlan(req));
    }

    @Operation(summary = "更新训练计划（支持更新days分配）")
    @PutMapping("/plans/{planId}")
    public Result<PlanDetail> updatePlan(@PathVariable Long planId,
                                         @RequestBody PlanRequest req) {
        return Result.success(trainingService.updatePlan(planId, req));
    }

    @Operation(summary = "删除训练计划（同时清理关联关系）")
    @DeleteMapping("/plans/{planId}")
    public Result<Void> deletePlan(@PathVariable Long planId) {
        trainingService.deletePlan(planId);
        return Result.success();
    }

    // ──────── 3.6 训练日志 ────────

    @Operation(summary = "提交训练完成日志")
    @PostMapping("/logs")
    public Result<TrainedDetailLog> addLog(@AuthenticationPrincipal Long userId,
                                           @RequestBody TrainedDetailLog req) {
        return Result.success(trainingService.addLog(userId, req));
    }

    @Operation(summary = "查询训练日志历史（分页，按时间倒序）")
    @GetMapping("/logs")
    public Result<Page<TrainedDetailLog>> getLogs(
            @AuthenticationPrincipal Long userId,
            @RequestParam(defaultValue = "0")  int page,
            @RequestParam(defaultValue = "20") int size) {
        return Result.success(trainingService.getLogs(userId, page, size));
    }

    // ──────── 3.7 训练报告 ────────

    @Operation(summary = "训练统计报告（period: week/month/year）")
    @GetMapping("/reports")
    public Result<TrainingReport> getReport(@AuthenticationPrincipal Long userId,
                                            @RequestParam(defaultValue = "week") String period) {
        return Result.success(trainingService.getReport(userId, period));
    }

    // ──────── 内部 DTO ────────

    /** 创建动作组的包装请求体（含 Group 基本信息 + 初始 actions） */
    @lombok.Data
    public static class GroupCreateRequest {
        private TrainingGroup group;
        private List<Action> actions;
    }
}
