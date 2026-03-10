package com.freefitness.training.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 训练计划与动作组的关联（对应 ff_plan_has_group 表）
 * dayNumber 表示该 Group 属于计划的第几天
 */
@Data
@NoArgsConstructor
@Entity
@Table(name = "ff_plan_has_group")
public class PlanHasGroup {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "plan_has_group_id")
    private Long planHasGroupId;

    @Column(name = "plan_id", nullable = false)
    private Long planId;

    @Column(name = "group_id", nullable = false)
    private Long groupId;

    @Column(name = "day_number", nullable = false)
    private Integer dayNumber;
}
