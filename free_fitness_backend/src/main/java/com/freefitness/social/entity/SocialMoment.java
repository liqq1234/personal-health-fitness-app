package com.freefitness.social.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@Entity
@Table(name = "ff_social_moment")
public class SocialMoment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "moment_id")
    private Long momentId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "content", columnDefinition = "TEXT")
    private String content;

    @Column(name = "images", columnDefinition = "TEXT")
    private String images; // Store as JSON array string or CSV

    @Column(name = "gmt_create", length = 30)
    private String gmtCreate;
}
