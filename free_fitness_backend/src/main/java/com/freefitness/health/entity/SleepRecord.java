package com.freefitness.health.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@Entity
@Table(name = "ff_sleep_records")
public class SleepRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long sleepId;

    @Column(nullable = false)
    private Long userId;

    @Column(nullable = false)
    private String startTime; // ISO format

    @Column(nullable = false)
    private String endTime; // ISO format

    private Double durationHours;

    private Integer quality; // 1-100

    @Column(columnDefinition = "TEXT")
    private String note;

    private String gmtCreate;
}
