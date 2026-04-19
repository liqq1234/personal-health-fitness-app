package com.freefitness.training.dto;

import com.freefitness.training.entity.Plan;
import lombok.Data;

import java.util.List;

/**
 * 训练计划详情：Plan + 嵌套的每天 GroupDetail
 */
@Data
public class PlanDetail {
    private Long planId;
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
    /** key = dayNumber, value = GroupDetail */
    private List<DayGroup> days;

    @Data
    public static class DayGroup {
        private Integer dayNumber;
        private GroupDetail group;
    }

    public static PlanDetail from(Plan p, List<DayGroup> days) {
        PlanDetail d = new PlanDetail();
        d.setPlanId(p.getPlanId());
        d.setPlanCode(p.getPlanCode());
        d.setPlanName(p.getPlanName());
        d.setPlanCategory(p.getPlanCategory());
        d.setPlanLevel(p.getPlanLevel());
        d.setPlanPeriod(p.getPlanPeriod());
        d.setTotalSets(p.getTotalSets());
        d.setSportType(p.getSportType());
        d.setRestDuration(p.getRestDuration());
        d.setStartTime(p.getStartTime());
        d.setReminderMinutes(p.getReminderMinutes());
        d.setDescription(p.getDescription());
        d.setDays(days);
        return d;
    }
}
