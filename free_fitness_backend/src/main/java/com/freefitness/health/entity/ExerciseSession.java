package com.freefitness.health.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 运动会话（对应 ff_exercise_sessions 表）
 * pathPoints 存储 GPS 轨迹点 JSON 字符串
 */
@Data
@NoArgsConstructor
@Entity
@Table(name = "ff_exercise_sessions")
public class ExerciseSession {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "session_id")
    private Long sessionId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "start_time", nullable = false, length = 30)
    private String startTime;

    @Column(name = "end_time", length = 30)
    private String endTime;

    @Column(name = "distance")
    private Double distance;

    @Column(name = "steps")
    private Integer steps;

    @Column(name = "path_points", columnDefinition = "MEDIUMTEXT")
    private String pathPoints;

    @Column(name = "calories")
    private Double calories;

    @Column(name = "duration_seconds")
    private Long durationSeconds;

    @Column(name = "gmt_create", nullable = false, length = 30)
    private String gmtCreate;
}
