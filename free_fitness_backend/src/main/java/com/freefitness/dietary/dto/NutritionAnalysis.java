package com.freefitness.dietary.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NutritionAnalysis {
    private String date;
    
    // Intake
    private Double currentCalories;
    private Double currentProtein;
    private Double currentFat;
    private Double currentCarbs;
    
    // Goals
    private Double targetCalories;
    private Double targetProtein;
    private Double targetFat;
    private Double targetCarbs;
    
    // Gaps
    private Double calorieGap;
    private Double proteinGap;
    private Double fatGap;
    private Double carbsGap;
    private Double waterGap;
    
    // Intake
    private Double currentWater;
    private Double targetWater;
    
    // Recommendations
    private List<String> recommendations;
    private String statusSummary; // e.g. "Excellent", "Protein Deficit", "Too much Fat"
}
