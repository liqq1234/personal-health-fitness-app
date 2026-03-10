package com.freefitness.health.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 每日步数（对应 ff_daily_steps 表）
 * date 字段唯一约束，同一天只保留一条，更新时覆盖
 */
@Data
@NoArgsConstructor
@Entity
@Table(name = "ff_daily_steps",
       uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "date"}))
public class DailySteps {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "steps_id")
    private Long stepsId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "`date`", nullable = false, length = 12)
    private String date;

    @Column(name = "steps", nullable = false)
    private Integer steps;

    @Column(name = "calories", nullable = false)
    private Double calories;

    @Column(name = "gmt_create", nullable = false, length = 30)
    private String gmtCreate;
}
