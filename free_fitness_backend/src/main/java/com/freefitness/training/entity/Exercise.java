package com.freefitness.training.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 基础动作库（对应 ff_exercise 表）
 * isCustom=false 为系统内置，只读；isCustom=true 为用户自定义，可删改
 */
@Data
@NoArgsConstructor
@Entity
@Table(name = "ff_exercise")
public class Exercise {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "exercise_id")
    private Long exerciseId;

    @Column(name = "exercise_code", nullable = false, unique = true, length = 64)
    private String exerciseCode;

    @Column(name = "exercise_name", nullable = false, unique = true, length = 128)
    private String exerciseName;

    @Column(name = "`force`", length = 32)
    private String force;

    @Column(name = "`level`", length = 32)
    private String level;

    @Column(name = "mechanic", length = 32)
    private String mechanic;

    @Column(name = "equipment", length = 64)
    private String equipment;

    @Column(name = "counting_mode", nullable = false, length = 16)
    private String countingMode;

    @Column(name = "standard_duration", nullable = false)
    private Integer standardDuration = 1;

    @Column(name = "instructions", columnDefinition = "TEXT")
    private String instructions;

    @Column(name = "tts_notes", columnDefinition = "TEXT")
    private String ttsNotes;

    @Column(name = "category", nullable = false, length = 64)
    private String category;

    @Column(name = "primary_muscles", columnDefinition = "TEXT")
    private String primaryMuscles;

    @Column(name = "secondary_muscles", columnDefinition = "TEXT")
    private String secondaryMuscles;

    @Column(name = "images", columnDefinition = "TEXT")
    private String images;

    @Column(name = "is_custom", columnDefinition = "TINYINT")
    private Boolean isCustom = false;

    @Column(name = "contributor", length = 64)
    private String contributor;

    @Column(name = "gmt_create", length = 30)
    private String gmtCreate;

    @Column(name = "gmt_modified", length = 30)
    private String gmtModified;
}
