package com.freefitness.health;

import com.freefitness.common.Result;
import com.freefitness.health.dto.AssessmentResponse;
import com.freefitness.health.dto.SyncRequest;
import com.freefitness.health.entity.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 健康仪表板接口
 * 所有接口均通过 JWT 鉴权，userId 从 Token 解析
 */
@Slf4j
@Tag(name = "健康仪表板", description = "步数 / 睡眠 / 简版饮食 / 运动会话 / 数据同步 / 健康评估")
@RestController
@RequestMapping("/api/v1/health")
@RequiredArgsConstructor
public class HealthController {

    private final HealthService healthService;

    // ─────────────── 步数 2.2 ───────────────

    @Operation(summary = "上报/更新每日步数（同一天自动 upsert）")
    @PostMapping("/steps")
    public Result<DailySteps> upsertSteps(@AuthenticationPrincipal Long userId,
                                          @RequestBody DailySteps req) {
        return Result.success(healthService.upsertSteps(userId, req));
    }

    @Operation(summary = "查询步数历史")
    @GetMapping("/steps")
    public Result<List<DailySteps>> getSteps(@AuthenticationPrincipal Long userId,
                                             @RequestParam String startDate,
                                             @RequestParam String endDate) {
        return Result.success(healthService.getSteps(userId, startDate, endDate));
    }

    // ─────────────── 睡眠 2.3 ───────────────

    @Operation(summary = "新增睡眠记录")
    @PostMapping("/sleeps")
    public Result<SleepRecord> addSleep(@AuthenticationPrincipal Long userId,
                                        @RequestBody SleepRecord req) {
        return Result.success(healthService.addSleep(userId, req));
    }

    @Operation(summary = "查询最近睡眠记录")
    @GetMapping("/sleeps")
    public Result<List<SleepRecord>> getSleeps(@AuthenticationPrincipal Long userId,
                                               @RequestParam(defaultValue = "10") int limit) {
        return Result.success(healthService.getRecentSleeps(userId, limit));
    }

    @Operation(summary = "删除睡眠记录")
    @DeleteMapping("/sleeps/{sleepId}")
    public Result<Void> deleteSleep(@AuthenticationPrincipal Long userId,
                                    @PathVariable Long sleepId) {
        healthService.deleteSleep(userId, sleepId);
        return Result.success();
    }


    // ─────────────── 简版饮食 2.4 ───────────────

    @Operation(summary = "新增简版饮食记录（仪表板来源）")
    @PostMapping("/diet-logs")
    public Result<DietLog> addDietLog(@AuthenticationPrincipal Long userId,
                                      @RequestBody DietLog req) {
        return Result.success(healthService.addDietLog(userId, req));
    }

    @Operation(summary = "查询当天简版饮食记录")
    @GetMapping("/diet-logs")
    public Result<List<DietLog>> getDietLogs(@AuthenticationPrincipal Long userId,
                                             @RequestParam String date) {
        return Result.success(healthService.getDietLogs(userId, date));
    }

    // ─────────────── 运动会话 2.5 ───────────────

    @Operation(summary = "上报运动会话结果（含 GPS 轨迹）")
    @PostMapping("/exercise-sessions")
    public Result<ExerciseSession> addSession(@AuthenticationPrincipal Long userId,
                                              @RequestBody ExerciseSession req) {
        return Result.success(healthService.addSession(userId, req));
    }

    @Operation(summary = "查询运动会话历史")
    @GetMapping("/exercise-sessions")
    public Result<List<ExerciseSession>> getSessions(@AuthenticationPrincipal Long userId,
                                                     @RequestParam(defaultValue = "20") int limit) {
        return Result.success(healthService.getSessions(userId, limit));
    }

    // ─────────────── 批量同步 2.6 ───────────────

    @Operation(summary = "批量健康数据同步（对接前端 SyncService.syncData()）",
               description = "接受步数、睡眠、饮食列表，逐类 upsert 入库。" +
                             "前端 SyncService 中路径为 /api/health/sync，部署时通过 nginx 重写或直接匹配此路径。")
    @PostMapping("/sync")
    public Result<Map<String, Object>> sync(@AuthenticationPrincipal Long userId,
                                            @RequestBody SyncRequest req) {
        if (userId == null) userId = req.getUserId();
        if (userId == null) return Result.error("未识别的用户ID (X-User-Id header missing)");
        req.setUserId(userId);
        return Result.success(healthService.syncData(userId, req));
    }

    // ─────────────── 健康评估 2.7 ───────────────

    @Operation(summary = "获取健康评估报告（基于近7天数据）")
    @GetMapping("/assessment")
    public Result<AssessmentResponse> assess(@AuthenticationPrincipal Long userId,
                                             @RequestParam(required = false) String date) {
        return Result.success(healthService.assess(userId, date));
    }

    @Operation(summary = "获取运动分析与AI建议（含最近一周曲线数据）", 
               description = "默认优先读缓存，force=true 则强制重新调用 AI 分析")
    @GetMapping("/exercise/analysis")
    public Result<com.freefitness.health.dto.ExerciseAnalysis> getExerciseAnalysis(
            @AuthenticationPrincipal Long userId,
            @RequestParam(defaultValue = "false") boolean force) {
        return Result.success(healthService.getExerciseAnalysis(userId, force));
    }

    @Operation(summary = "获取睡眠分析与AI建议", 
               description = "默认优先读缓存，force=true 则强制重新调用 AI 分析")
    @GetMapping("/sleep/analysis")
    public Result<com.freefitness.health.dto.SleepAnalysis> getSleepAnalysis(
            @AuthenticationPrincipal Long userId,
            @RequestParam(defaultValue = "false") boolean force) {
        return Result.success(healthService.getSleepAnalysis(userId, force));
    }

    @Operation(summary = "后端模拟走路（随机增加 50-300 步，用于演示目标）")
    @PostMapping("/simulate-walk")
    public Result<DailySteps> simulateWalk(@AuthenticationPrincipal Long userId) {
        return Result.success(healthService.simulateWalk(userId));
    }
}
