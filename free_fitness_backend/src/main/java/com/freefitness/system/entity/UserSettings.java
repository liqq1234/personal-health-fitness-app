package com.freefitness.system.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 用户偏好设置（对应 ff_user_settings 表）
 */
@Data
@NoArgsConstructor
@Entity
@Table(name = "ff_user_settings")
public class UserSettings {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "setting_id")
    private Long settingId;

    @Column(name = "user_id", nullable = false, unique = true)
    private Long userId;

    @Column(name = "theme", length = 32)
    private String theme;

    @Column(name = "language", length = 16)
    private String language;

    @Column(name = "gmt_modified", length = 30)
    private String gmtModified;
}
