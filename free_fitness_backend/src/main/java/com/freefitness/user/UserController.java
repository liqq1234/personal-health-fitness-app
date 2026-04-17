package com.freefitness.user;

import com.freefitness.common.Result;
import com.freefitness.user.dto.UpdateUserRequest;
import com.freefitness.user.dto.WeightTrendRequest;
import com.freefitness.user.dto.WeightTrendResponse;
import com.freefitness.user.entity.IntakeDailyGoal;
import com.freefitness.user.entity.User;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.Map;

/**
 * 用户接口：个人信息 / 头像 / 体重趋势 / 每日摄入目标
 */
@Slf4j
@Tag(name = "用户管理", description = "基本信息 / 体重记录 / 目标设定 / 头像上传")
@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    /** 1.5 GET /api/v1/users/{userId} */
    @Operation(summary = "查询用户信息")
    @GetMapping("/{userId}")
    public Result<User> getUser(@PathVariable Long userId,
                                @AuthenticationPrincipal Long currentUserId) {
        // 2026-04-17 如果 currentUserId 为空（Header 识别失败），在 permitAll 模式下暂且信任 path 的 ID
        if (currentUserId != null && !userId.equals(currentUserId)) {
            return Result.forbidden("无权访问他人数据");
        }
        return Result.success(userService.getUser(userId));
    }

    /** 1.5 PUT /api/v1/users/{userId} */
    @Operation(summary = "更新用户信息（PATCH 语义，仅传需修改字段）")
    @PutMapping("/{userId}")
    public Result<User> updateUser(@PathVariable Long userId,
                                   @AuthenticationPrincipal Long currentUserId,
                                   @RequestBody UpdateUserRequest req) {
        if (currentUserId != null && !userId.equals(currentUserId)) return Result.forbidden("无权修改他人数据");
        return Result.success(userService.updateUser(userId, req));
    }

    /** 1.6 POST /api/v1/users/{userId}/avatar */
    @Operation(summary = "上传用户头像")
    @PostMapping("/{userId}/avatar")
    public Result<Map<String, String>> uploadAvatar(@PathVariable Long userId,
                                                    @AuthenticationPrincipal Long currentUserId,
                                                    @RequestParam("file") MultipartFile file) throws IOException {
        if (currentUserId != null && !userId.equals(currentUserId)) return Result.forbidden("无权操作");
        String url = userService.uploadAvatar(userId, file);
        return Result.success(Map.of("avatarUrl", url));
    }

    /** 1.7 POST /api/v1/users/{userId}/weight-trends */
    @Operation(summary = "新增体重记录（weight 和 bmi 将 AES-256 加密存储）")
    @PostMapping("/{userId}/weight-trends")
    public Result<WeightTrendResponse> addWeightTrend(@PathVariable Long userId,
                                                      @AuthenticationPrincipal Long currentUserId,
                                                      @Valid @RequestBody WeightTrendRequest req) {
        if (currentUserId != null && !userId.equals(currentUserId)) return Result.forbidden("无权操作");
        return Result.success(userService.addWeightTrend(userId, req));
    }

    /** 1.7 GET /api/v1/users/{userId}/weight-trends */
    @Operation(summary = "查询体重趋势列表（返回解密后的明文）")
    @GetMapping("/{userId}/weight-trends")
    public Result<List<WeightTrendResponse>> getWeightTrends(
            @PathVariable Long userId,
            @AuthenticationPrincipal Long currentUserId,
            @RequestParam(required = false) String startDate,
            @RequestParam(required = false) String endDate) {
        if (currentUserId != null && !userId.equals(currentUserId)) return Result.forbidden("无权访问");
        return Result.success(userService.getWeightTrends(userId, startDate, endDate));
    }

    /** 1.8 GET /api/v1/users/{userId}/intake-goals */
    @Operation(summary = "查询每日摄入目标（7天）")
    @GetMapping("/{userId}/intake-goals")
    public Result<List<IntakeDailyGoal>> getIntakeGoals(@PathVariable Long userId,
                                                        @AuthenticationPrincipal Long currentUserId) {
        if (currentUserId != null && !userId.equals(currentUserId)) return Result.forbidden("无权访问");
        return Result.success(userService.getIntakeGoals(userId));
    }

    /** 1.8 PUT /api/v1/users/{userId}/intake-goals */
    @Operation(summary = "批量 upsert 每日摄入目标（传入 7 条，按 dayOfWeek 去重）")
    @PutMapping("/{userId}/intake-goals")
    public Result<List<IntakeDailyGoal>> upsertIntakeGoals(@PathVariable Long userId,
                                                           @AuthenticationPrincipal Long currentUserId,
                                                           @RequestBody List<IntakeDailyGoal> goals) {
        if (currentUserId != null && !userId.equals(currentUserId)) return Result.forbidden("无权操作");
        return Result.success(userService.upsertIntakeGoals(userId, goals));
    }
}
