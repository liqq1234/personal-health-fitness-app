package com.freefitness.dietary.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 餐次照片（对应 ff_meal_photo 表）
 * photos 字段存储 JSON 数组格式的图片 URL 列表
 */
@Data
@NoArgsConstructor
@Entity
@Table(name = "ff_meal_photo")
public class MealPhoto {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "meal_photo_id")
    private Long mealPhotoId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "`date`", nullable = false, length = 12)
    private String date;

    @Column(name = "meal_category", nullable = false, length = 20)
    private String mealCategory;

    @Column(name = "photos", nullable = false, columnDefinition = "TEXT")
    private String photos;   // JSON 数组：["url1","url2"]

    @Column(name = "gmt_create", nullable = false, length = 30)
    private String gmtCreate;
}
