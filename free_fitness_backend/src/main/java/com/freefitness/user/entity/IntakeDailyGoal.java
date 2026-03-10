package com.freefitness.user.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 每日营养摄入目标（对应 ff_intake_daily_goal 表）
 * dayOfWeek: MON / TUE / WED / THU / FRI / SAT / SUN
 */
@Data
@NoArgsConstructor
@Entity
@Table(name = "ff_intake_daily_goal")
public class IntakeDailyGoal {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "intake_daily_goal_id")
    private Long intakeDailyGoalId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "day_of_week", nullable = false, length = 10)
    private String dayOfWeek;

    @Column(name = "rda_daily_goal", nullable = false)
    private Integer rdaDailyGoal;

    @Column(name = "protein_daily_goal", nullable = false)
    private Double proteinDailyGoal;

    @Column(name = "fat_daily_goal", nullable = false)
    private Double fatDailyGoal;

    @Column(name = "cho_daily_goal", nullable = false)
    private Double choDailyGoal;
}
