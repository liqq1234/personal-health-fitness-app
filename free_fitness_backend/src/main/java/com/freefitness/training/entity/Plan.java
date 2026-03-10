package com.freefitness.training.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 训练计划（对应 ff_plan 表）
 */
@Data
@NoArgsConstructor
@Entity
@Table(name = "ff_plan")
public class Plan {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "plan_id")
    private Long planId;

    @Column(name = "plan_code", nullable = false, unique = true, length = 64)
    private String planCode;

    @Column(name = "plan_name", nullable = false, unique = true, length = 128)
    private String planName;

    @Column(name = "plan_category", nullable = false, length = 64)
    private String planCategory;

    @Column(name = "plan_level", nullable = false, length = 32)
    private String planLevel;

    @Column(name = "plan_period", nullable = false)
    private Integer planPeriod;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "contributor", length = 64)
    private String contributor;

    @Column(name = "gmt_create", length = 30)
    private String gmtCreate;

    @Column(name = "gmt_modified", length = 30)
    private String gmtModified;
}
