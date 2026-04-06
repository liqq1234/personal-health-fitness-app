package com.freefitness.training.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 预训练计划排程（对应 ff_training_schedule 表）
 */
@Data
@NoArgsConstructor
@Entity
@Table(name = "ff_training_schedule")
public class TrainingSchedule {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "schedule_id")
    private Long scheduleId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "training_type", nullable = false, length = 20)
    private String trainingType; // PLAN / GROUP / ACTIVITY

    @Column(name = "training_name", length = 100)
    private String trainingName;

    @Column(name = "target_id")
    private Long targetId;

    @Column(name = "scheduled_date", nullable = false, length = 12)
    private String scheduledDate;

    @Column(name = "start_time", nullable = false, length = 10)
    private String startTime;

    @Column(name = "end_time", nullable = false, length = 10)
    private String endTime;

    @Column(name = "status", nullable = false, length = 20)
    private String status = "PENDING"; // PENDING, COMPLETED, MISSED

    @Column(name = "remind_before_minutes")
    private Integer remindBeforeMinutes = 15;

    @Column(name = "remind_sent")
    private Integer remindSent = 0;

    @Column(name = "gmt_create", length = 30)
    private String gmtCreate;

    @Column(name = "gmt_modified", length = 30)
    private String gmtModified;
}
