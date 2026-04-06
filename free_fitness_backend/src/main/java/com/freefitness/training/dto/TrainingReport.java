package com.freefitness.training.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

/**
 * 训练统计报告
 */
@Data
@AllArgsConstructor
public class TrainingReport {
    private int totalSessions;
    private long totalDurationSeconds;
    private int totalCalories;
    private double avgDurationMinutes;
    private double totalVolume; // 权重计算后的训练量
    private String mostFrequentCategory;
    private String period;     // week / month / year
}
