package com.freefitness.dietary.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * 当天营养摄入汇总（按餐次分组）
 */
@Data
@AllArgsConstructor
@NoArgsConstructor
public class DailySummary {

    private String date;
    private double totalCalories;
    private double totalProtein;
    private double totalFat;
    private double totalCarbs;
    private double totalSodium;
    private double totalWater;

    private List<MealSummary> meals;

    @Data
    @AllArgsConstructor
    @NoArgsConstructor
    public static class MealSummary {
        private String mealCategory;
        private double calories;
        private double protein;
        private double fat;
        private double carbs;
        private int itemCount;
    }
}
