package com.freefitness.health.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 睡眠记录（对应 ff_sleep_records 表）
 */
@Data
@NoArgsConstructor
@Entity
@Table(name = "ff_sleep_records")
public class SleepRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "sleep_id")
    private Long sleepId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "start_time", nullable = false, length = 30)
    private String startTime;

    @Column(name = "end_time", nullable = false, length = 30)
    private String endTime;

    @Column(name = "duration_hours", nullable = false)
    private Double durationHours;

    @Column(name = "note", columnDefinition = "TEXT")
    private String note;

    @Column(name = "gmt_create", nullable = false, length = 30)
    private String gmtCreate;
}
