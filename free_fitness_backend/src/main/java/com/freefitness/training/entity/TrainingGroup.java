package com.freefitness.training.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 动作组（对应 ff_group 表）
 * 注意：避免与 java.lang 中的类名冲突，实体类名保持 TrainingGroup
 */
@Data
@NoArgsConstructor
@Entity
@Table(name = "ff_group")
public class TrainingGroup {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "group_id")
    private Long groupId;

    @Column(name = "group_name", nullable = false, unique = true, length = 128)
    private String groupName;

    @Column(name = "group_category", nullable = false, length = 64)
    private String groupCategory;

    @Column(name = "group_level", nullable = false, length = 32)
    private String groupLevel;

    @Column(name = "consumption")
    private Integer consumption;

    @Column(name = "time_spent")
    private Integer timeSpent;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "contributor", length = 64)
    private String contributor;

    @Column(name = "gmt_create", length = 30)
    private String gmtCreate;

    @Column(name = "gmt_modified", length = 30)
    private String gmtModified;
}
