package com.freefitness.health.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 轻量饮食记录 - 简版（对应 ff_diet_logs 表）
 * 区别于饮食模块的完整 DailyFoodItem，这是仪表板的快速录入
 */
@Data
@NoArgsConstructor
@Entity
@Table(name = "ff_diet_logs")
public class DietLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "diet_id")
    private Long dietId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "`date`", nullable = false, length = 12)
    private String date;

    @Column(name = "category", nullable = false, length = 30)
    private String category;

    @Column(name = "food_name", nullable = false, length = 128)
    private String foodName;

    @Column(name = "calories", nullable = false)
    private Double calories;

    @Column(name = "protein", nullable = false)
    private Double protein;

    @Column(name = "fat")
    private Double fat;

    @Column(name = "carbs")
    private Double carbs;

    @Column(name = "water")
    private Double water;

    @Column(name = "gmt_create", nullable = false, length = 30)
    private String gmtCreate;
}
