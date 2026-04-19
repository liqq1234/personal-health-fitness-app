package com.freefitness.health.entity;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "t_health_ai_analysis")
public class HealthAiAnalysis {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long userId;

    @Column(columnDefinition = "TEXT")
    private String feedback;

    private int score;

    @Column(nullable = false)
    private String date; // yyyy-MM-dd

    private String type; // EXERCISE, SLEEP

    private String gmtCreate;
}
