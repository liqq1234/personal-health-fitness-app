package com.freefitness.dietary.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 每日饮食条目（对应 ff_daily_food_item 表）
 * 记录用户某天某餐次摄入的某份量食物
 */
@Data
@NoArgsConstructor
@Entity
@Table(name = "ff_daily_food_item")
public class DailyFoodItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "daily_food_item_id")
    private Long dailyFoodItemId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "`date`", nullable = false, length = 12)
    private String date;

    @Column(name = "meal_category", nullable = false, length = 20)
    private String mealCategory;   // 早餐/中餐/晚餐/加餐

    @Column(name = "food_id", nullable = false)
    private Long foodId;

    @Column(name = "food_intake_size", nullable = false)
    private Double foodIntakeSize;

    @Column(name = "serving_info_id", nullable = false)
    private Long servingInfoId;

    @Column(name = "gmt_create", length = 30)
    private String gmtCreate;

    @Column(name = "gmt_modified", length = 30)
    private String gmtModified;
}
