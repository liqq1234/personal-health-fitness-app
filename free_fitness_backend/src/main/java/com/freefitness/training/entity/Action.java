package com.freefitness.training.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 动作组内的具体动作配置（对应 ff_action 表）
 * 描述"在某动作组中，该基础动作的次数/时长/器械重量"
 */
@Data
@NoArgsConstructor
@Entity
@Table(name = "ff_action")
public class Action {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "action_id")
    private Long actionId;

    @Column(name = "group_id", nullable = false)
    private Long groupId;

    @Column(name = "exercise_id", nullable = false)
    private Long exerciseId;

    @Column(name = "frequency")
    private Integer frequency;

    @Column(name = "duration")
    private Integer duration;

    @Column(name = "equipment_weight")
    private Double equipmentWeight;
}
