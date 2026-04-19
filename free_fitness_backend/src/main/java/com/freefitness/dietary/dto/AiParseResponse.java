package com.freefitness.dietary.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class AiParseResponse {
    private String originalText;
    private List<ParsedFood> foods;
    private double totalCalories;
    private double totalProtein;
    private double totalCarbs;
    private double totalFat;
    private double totalWater;

    @Data
    @AllArgsConstructor
    @NoArgsConstructor
    public static class ParsedFood {
        private String foodName;
        private double amount;
        private String unit;
        private double calories;
        private double protein;
        private double carbs;
        private double fat;
    }
}
