package com.freefitness.dietary.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 食物营养素规格（对应 ff_serving_info 表）
 * 同一食物可有多个份量规格（100g / 1杯 / 1片 等）
 */
@Data
@NoArgsConstructor
@Entity
@Table(name = "ff_serving_info",
       uniqueConstraints = @UniqueConstraint(columnNames = {"food_id", "serving_size", "serving_unit"}))
public class ServingInfo {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "serving_info_id")
    private Long servingInfoId;

    @Column(name = "food_id", nullable = false)
    private Long foodId;

    @Column(name = "serving_size", nullable = false)
    private Integer servingSize;

    @Column(name = "serving_unit", nullable = false, length = 20)
    private String servingUnit;

    @Column(name = "energy", nullable = false)
    private Double energy;

    @Column(name = "energy_kcal")
    private Double energyKcal;

    @Column(name = "protein", nullable = false)
    private Double protein;

    @Column(name = "total_fat", nullable = false)
    private Double totalFat;

    @Column(name = "saturated_fat")
    private Double saturatedFat;

    @Column(name = "trans_fat")
    private Double transFat;

    @Column(name = "polyunsaturated_fat")
    private Double polyunsaturatedFat;

    @Column(name = "monounsaturated_fat")
    private Double monounsaturatedFat;

    @Column(name = "cholesterol")
    private Double cholesterol;

    @Column(name = "total_carbohydrate", nullable = false)
    private Double totalCarbohydrate;

    @Column(name = "sugar")
    private Double sugar;

    @Column(name = "dietary_fiber")
    private Double dietaryFiber;

    @Column(name = "sodium", nullable = false)
    private Double sodium;

    @Column(name = "potassium")
    private Double potassium;

    @Column(name = "contributor", length = 64)
    private String contributor;

    @Column(name = "gmt_create", length = 30)
    private String gmtCreate;

    @Column(name = "update_user", length = 64)
    private String updateUser;

    @Column(name = "gmt_modified", length = 30)
    private String gmtModified;

    @Column(name = "is_deleted", columnDefinition = "TINYINT")
    private Boolean isDeleted = false;
}
