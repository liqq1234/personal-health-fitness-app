package com.freefitness.user.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 用户基础信息（对应 ff_user 表 / ddl_user.dart）
 */
@Data
@NoArgsConstructor
@Entity
@Table(name = "ff_user")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "user_id")
    private Long userId;

    @Column(name = "user_name", nullable = false, length = 64)
    private String userName;

    @Column(name = "user_code", length = 64)
    private String userCode;

    @Column(name = "gender", length = 10)
    private String gender;

    @Column(name = "avatar", length = 512)
    private String avatar;

    @Column(name = "password", length = 255)
    private String password;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "date_of_birth", length = 20)
    private String dateOfBirth;

    @Column(name = "height")
    private Double height;

    @Column(name = "height_unit", length = 10)
    private String heightUnit;

    @Column(name = "current_weight")
    private Double currentWeight;

    @Column(name = "target_weight")
    private Double targetWeight;

    @Column(name = "weight_unit", length = 10)
    private String weightUnit;

    @Column(name = "rda_goal")
    private Integer rdaGoal;

    @Column(name = "protein_goal")
    private Double proteinGoal;

    @Column(name = "fat_goal")
    private Double fatGoal;

    @Column(name = "cho_goal")
    private Double choGoal;

    @Column(name = "water_goal")
    private Double waterGoal; // in ml

    @Column(name = "action_rest_time")
    private Integer actionRestTime;

    @Column(name = "gmt_create", length = 30)
    private String gmtCreate;

    @Column(name = "gmt_modified", length = 30)
    private String gmtModified;
}
