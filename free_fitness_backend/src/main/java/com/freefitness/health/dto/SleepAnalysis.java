package com.freefitness.health.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SleepAnalysis {
    private List<DailyStat> weeklyData;
    private String feedback;
    private int score; // 0-100

    @Data
    @AllArgsConstructor
    @NoArgsConstructor
    public static class DailyStat {
        private String date;
        private double duration; // hours
        private int quality;
    }
}
