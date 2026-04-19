package com.freefitness.dietary;

import com.freefitness.common.Result;
import com.freefitness.dietary.dto.DailySummary;
import com.freefitness.dietary.entity.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;

/**
 * 饮食管理接口
 */
@Slf4j
@Tag(name = "饮食管理", description = "食物库 / 营养素规格 / 每日饮食条目 / 营养汇总 / 餐次照片")
@RestController
@RequestMapping("/api/v1/dietary")
@RequiredArgsConstructor
public class DietaryController {

    private final DietaryService dietaryService;
    private final AiDietaryService aiDietaryService;

    // ──────── 4.2 食物库 ────────

    @Operation(summary = "搜索食物库（category/keyword 过滤，自动过滤软删除）")
    @GetMapping("/foods")
    public Result<Page<Food>> searchFoods(
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "0")  int page,
            @RequestParam(defaultValue = "20") int size) {
        return Result.success(dietaryService.searchFoods(category, keyword, page, size));
    }

    @Operation(summary = "查询食物详情")
    @GetMapping("/foods/{foodId}")
    public Result<Food> getFood(@PathVariable Long foodId) {
        return Result.success(dietaryService.getFood(foodId));
    }

    @Operation(summary = "新增食物（用户自定义；系统食物只读）")
    @PostMapping("/foods")
    public Result<Food> createFood(@RequestBody Food req) {
        return Result.success(dietaryService.createFood(req));
    }

    @Operation(summary = "更新食物信息（系统食物禁止修改）")
    @PutMapping("/foods/{foodId}")
    public Result<Food> updateFood(@PathVariable Long foodId, @RequestBody Food req) {
        return Result.success(dietaryService.updateFood(foodId, req));
    }

    @Operation(summary = "软删除食物（isDeleted=true，数据保留）")
    @DeleteMapping("/foods/{foodId}")
    public Result<Void> deleteFood(@PathVariable Long foodId) {
        dietaryService.softDeleteFood(foodId);
        return Result.success();
    }

    // ──────── 4.3 营养素规格 ────────

    @Operation(summary = "查询食物的所有营养素规格")
    @GetMapping("/foods/{foodId}/serving-infos")
    public Result<List<ServingInfo>> getServingInfos(@PathVariable Long foodId) {
        return Result.success(dietaryService.getServingInfos(foodId));
    }

    @Operation(summary = "为食物新增营养素规格")
    @PostMapping("/foods/{foodId}/serving-infos")
    public Result<ServingInfo> addServingInfo(@PathVariable Long foodId,
                                              @RequestBody ServingInfo req) {
        return Result.success(dietaryService.addServingInfo(foodId, req));
    }

    @Operation(summary = "软删除营养素规格")
    @DeleteMapping("/foods/{foodId}/serving-infos/{servingInfoId}")
    public Result<Void> deleteServingInfo(@PathVariable Long foodId,
                                          @PathVariable Long servingInfoId) {
        dietaryService.deleteServingInfo(servingInfoId);
        return Result.success();
    }

    // ──────── 4.4 每日饮食条目 ────────

    @Operation(summary = "查询当天饮食条目（可按 mealCategory 过滤）")
    @GetMapping("/daily-items")
    public Result<List<DailyFoodItem>> getDailyItems(
            @AuthenticationPrincipal Long userId,
            @RequestParam String date,
            @RequestParam(required = false) String mealCategory) {
        return Result.success(dietaryService.getDailyItems(userId, date, mealCategory));
    }

    @Operation(summary = "按日期范围查询饮食条目详情")
    @GetMapping("/logs/detail")
    public Result<List<com.freefitness.dietary.dto.DailyItemDetail>> getDailyItemsDetail(
            @AuthenticationPrincipal Long userId,
            @RequestParam(required = false) String startDate,
            @RequestParam(required = false) String endDate,
            @RequestParam(required = false) String mealCategory) {
        return Result.success(dietaryService.getDailyItemsDetailRange(userId, startDate, endDate, mealCategory));
    }

    @Operation(summary = "添加饮食条目")
    @PostMapping("/daily-items")
    public Result<DailyFoodItem> addDailyItem(@AuthenticationPrincipal Long userId,
                                              @RequestBody DailyFoodItem req) {
        return Result.success(dietaryService.addDailyItem(userId, req));
    }

    @Operation(summary = "更新饮食条目（仅摄入量/餐次等）")
    @PutMapping("/daily-items/{itemId}")
    public Result<DailyFoodItem> updateDailyItem(@AuthenticationPrincipal Long userId,
                                                  @PathVariable Long itemId,
                                                  @RequestBody DailyFoodItem req) {
        return Result.success(dietaryService.updateDailyItem(userId, itemId, req));
    }

    @Operation(summary = "删除饮食条目")
    @DeleteMapping("/daily-items/{itemId}")
    public Result<Void> deleteDailyItem(@AuthenticationPrincipal Long userId,
                                        @PathVariable Long itemId) {
        dietaryService.deleteDailyItem(userId, itemId);
        return Result.success();
    }

    // ──────── 4.5 每日营养汇总 ────────

    @Operation(summary = "今日营养摄入汇总（按餐次分组，含总量和各餐次明细）")
    @GetMapping("/daily-summary")
    public Result<DailySummary> getDailySummary(
            @AuthenticationPrincipal Long userId,
            @RequestParam(required = false) String date) {
        String d = date != null ? date : LocalDate.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd"));
        return Result.success(dietaryService.getDailySummary(userId, d));
    }

    // ──────── 4.6 餐次照片 ────────

    @Operation(summary = "上传餐次照片（multipart/form-data）")
    @PostMapping("/meal-photos")
    public Result<MealPhoto> uploadMealPhoto(
            @AuthenticationPrincipal Long userId,
            @RequestParam String date,
            @RequestParam String mealCategory,
            @RequestParam("file") MultipartFile file) throws IOException {
        return Result.success(dietaryService.uploadMealPhoto(userId, date, mealCategory, file));
    }

    @Operation(summary = "查询当天所有餐次照片")
    @GetMapping("/meal-photos")
    public Result<List<MealPhoto>> getMealPhotos(
            @AuthenticationPrincipal Long userId,
            @RequestParam String date) {
        return Result.success(dietaryService.getMealPhotos(userId, date));
    }

    // ──────── 4.7 AI 辅助 ────────

    @Operation(summary = "AI 模糊识别饮食文本")
    @PostMapping("/parse-ai")
    public Result<com.freefitness.dietary.dto.AiParseResponse> parseAi(@RequestBody String text) {
        return Result.success(aiDietaryService.parseText(text));
    }

    @Operation(summary = "获取当日营养分析与建议")
    @GetMapping("/analysis")
    public Result<com.freefitness.dietary.dto.NutritionAnalysis> getAnalysis(
            @AuthenticationPrincipal Long userId,
            @RequestParam(required = false) String date) {
        String d = date != null ? date : LocalDate.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd"));
        return Result.success(dietaryService.getNutritionAnalysis(userId, d));
    }
}
