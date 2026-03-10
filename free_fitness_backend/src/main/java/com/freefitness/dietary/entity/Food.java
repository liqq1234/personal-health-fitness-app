package com.freefitness.dietary.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 食物库（对应 ff_food 表）
 * isDeleted=true 为软删除，不物理移除数据
 * contributor 为 null 或特定标记时视为系统食物（只读）
 */
@Data
@NoArgsConstructor
@Entity
@Table(name = "ff_food")
public class Food {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "food_id")
    private Long foodId;

    @Column(name = "brand", nullable = false, length = 128)
    private String brand;

    @Column(name = "product", nullable = false, length = 128)
    private String product;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "photos", columnDefinition = "TEXT")
    private String photos;

    @Column(name = "tags", columnDefinition = "TEXT")
    private String tags;

    @Column(name = "category", length = 64)
    private String category;

    /** null 或 "system" 表示系统食物，禁止删改 */
    @Column(name = "contributor", length = 64)
    private String contributor;

    @Column(name = "gmt_create", length = 30)
    private String gmtCreate;

    @Column(name = "is_deleted", columnDefinition = "TINYINT")
    private Boolean isDeleted = false;
}
