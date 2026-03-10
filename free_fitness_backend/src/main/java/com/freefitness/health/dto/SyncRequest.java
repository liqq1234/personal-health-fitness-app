package com.freefitness.health.dto;

import com.freefitness.health.entity.DailySteps;
import com.freefitness.health.entity.DietLog;
import com.freefitness.health.entity.SleepRecord;
import lombok.Data;

import java.util.List;

/**
 * 批量同步请求体（对接前端 SyncService.syncData()）
 */
@Data
public class SyncRequest {
    private Long userId;
    private List<DailySteps> steps;
    private List<SleepRecord> sleep;
    private List<DietLog> diet;
    private String timestamp;
}
