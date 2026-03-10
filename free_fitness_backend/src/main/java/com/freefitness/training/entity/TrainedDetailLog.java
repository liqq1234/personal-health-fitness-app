package com.freefitness.training.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 训练完成日志（对应 ff_trained_detail_log 表）
 * 宽表设计：冗余存储计划/组名称，避免历史数据关联丢失
 */
@Data
@NoArgsConstructor
@Entity
@Table(name = "ff_trained_detail_log")
public class TrainedDetailLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "trained_detail_log_id")
    private Long trainedDetailLogId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "trained_date", length = 12)
    private String trainedDate;

    @Column(name = "plan_name", length = 128)
    private String planName;

    @Column(name = "plan_category", length = 64)
    private String planCategory;

    @Column(name = "plan_level", length = 32)
    private String planLevel;

    @Column(name = "day_number")
    private Integer dayNumber;

    @Column(name = "group_name", length = 128)
    private String groupName;

    @Column(name = "group_category", length = 64)
    private String groupCategory;

    @Column(name = "group_level", length = 32)
    private String groupLevel;

    @Column(name = "consumption")
    private Integer consumption;

    @Column(name = "trained_start_time", nullable = false, length = 30)
    private String trainedStartTime;

    @Column(name = "trained_end_time", nullable = false, length = 30)
    private String trainedEndTime;

    @Column(name = "trained_duration", nullable = false)
    private Integer trainedDuration;

    @Column(name = "totol_paused_time", nullable = false)
    private Integer totolPausedTime;

    @Column(name = "total_rest_time", nullable = false)
    private Integer totalRestTime;
}
