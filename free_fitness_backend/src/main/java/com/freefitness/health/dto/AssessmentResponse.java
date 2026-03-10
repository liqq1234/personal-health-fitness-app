package com.freefitness.health.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

/**
 * 健康评估结果
 */
@Data
@AllArgsConstructor
public class AssessmentResponse {
    private int score;                 // 0-100
    private String suggestion;         // 主要建议文本
    private String stepsRating;        // 优秀/良好/中等/不足
    private String sleepRating;
    private String dietRating;
    private int avgSteps;              // 近7天平均步数
    private double avgSleepHours;      // 近7天平均睡眠
    private double avgCalories;        // 近7天平均热量
}
