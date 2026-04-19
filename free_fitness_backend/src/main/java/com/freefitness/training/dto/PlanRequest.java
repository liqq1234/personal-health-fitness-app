package com.freefitness.training.dto;

import lombok.Data;
import java.util.List;

/**
 * 创建/更新训练计划的请求体
 */
@Data
public class PlanRequest {
    private String planCode;
    private String planName;
    private String planCategory;
    private String planLevel;
    private Integer planPeriod;
    private Integer totalSets;
    private String sportType;
    private Integer restDuration;
    private String startTime;
    private Integer reminderMinutes;
    private String description;
    /** 每天对应的 Group 映射列表 */
    private List<DayGroupMapping> days;

    @Data
    public static class DayGroupMapping {
        private Integer dayNumber;
        private Long groupId;
    }
}
