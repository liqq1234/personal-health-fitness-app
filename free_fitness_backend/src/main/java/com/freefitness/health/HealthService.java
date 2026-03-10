package com.freefitness.health;

import com.freefitness.health.dto.AssessmentResponse;
import com.freefitness.health.dto.SyncRequest;
import com.freefitness.health.entity.*;
import com.freefitness.health.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;

/**
 * 健康仪表板服务：步数 / 睡眠 / 简版饮食 / 运动会话 / 同步 / 评估
 */
@Service
@RequiredArgsConstructor
public class HealthService {

    private final DailyStepsRepository stepsRepo;
    private final SleepRecordRepository sleepRepo;
    private final DietLogRepository dietLogRepo;
    private final ExerciseSessionRepository sessionRepo;

    private static final DateTimeFormatter DT_FMT =
            DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");

    // ─────────────── 2.2 步数 ───────────────

    /** upsert：同一用户同一天仅保留一条，后上报覆盖前者 */
    @Transactional
    public DailySteps upsertSteps(Long userId, DailySteps req) {
        req.setUserId(userId);
        if (req.getGmtCreate() == null) req.setGmtCreate(LocalDateTime.now().format(DT_FMT));

        stepsRepo.findByUserIdAndDate(userId, req.getDate())
                 .ifPresent(existing -> req.setStepsId(existing.getStepsId()));
        return stepsRepo.save(req);
    }

    public List<DailySteps> getSteps(Long userId, String startDate, String endDate) {
        return stepsRepo.findByUserIdAndDateBetweenOrderByDateAsc(userId, startDate, endDate);
    }

    // ─────────────── 2.3 睡眠 ───────────────

    @Transactional
    public SleepRecord addSleep(Long userId, SleepRecord req) {
        req.setSleepId(null);
        req.setUserId(userId);
        if (req.getGmtCreate() == null) req.setGmtCreate(LocalDateTime.now().format(DT_FMT));
        return sleepRepo.save(req);
    }

    public List<SleepRecord> getRecentSleeps(Long userId, int limit) {
        return sleepRepo.findByUserIdOrderByStartTimeDesc(userId, PageRequest.of(0, limit));
    }

    // ─────────────── 2.4 简版饮食 ───────────────

    @Transactional
    public DietLog addDietLog(Long userId, DietLog req) {
        req.setDietId(null);
        req.setUserId(userId);
        if (req.getGmtCreate() == null) req.setGmtCreate(LocalDateTime.now().format(DT_FMT));
        return dietLogRepo.save(req);
    }

    public List<DietLog> getDietLogs(Long userId, String date) {
        return dietLogRepo.findByUserIdAndDateOrderByGmtCreateAsc(userId, date);
    }

    // ─────────────── 2.5 运动会话 ───────────────

    @Transactional
    public ExerciseSession addSession(Long userId, ExerciseSession req) {
        req.setSessionId(null);
        req.setUserId(userId);
        if (req.getGmtCreate() == null) req.setGmtCreate(LocalDateTime.now().format(DT_FMT));
        return sessionRepo.save(req);
    }

    public List<ExerciseSession> getSessions(Long userId, int limit) {
        return sessionRepo.findByUserIdOrderByStartTimeDesc(userId, PageRequest.of(0, limit));
    }

    // ─────────────── 2.6 批量同步 ───────────────

    @Transactional
    public Map<String, Object> syncData(Long userId, SyncRequest req) {
        int stepsCount = 0, sleepCount = 0, dietCount = 0;

        if (req.getSteps() != null) {
            for (DailySteps s : req.getSteps()) {
                upsertSteps(userId, s);
                stepsCount++;
            }
        }
        if (req.getSleep() != null) {
            for (SleepRecord s : req.getSleep()) {
                addSleep(userId, s);
                sleepCount++;
            }
        }
        if (req.getDiet() != null) {
            for (DietLog d : req.getDiet()) {
                addDietLog(userId, d);
                dietCount++;
            }
        }

        return Map.of(
            "synced", true,
            "lastSyncTime", LocalDateTime.now().format(DT_FMT),
            "stepsCount", stepsCount,
            "sleepCount", sleepCount,
            "dietCount", dietCount
        );
    }

    // ─────────────── 2.7 健康评估 ───────────────

    /**
     * 基于近7天数据计算健康评分（纯 Java 逻辑，无外部依赖）
     * 评分维度：步数 40分 + 睡眠 40分 + 饮食热量合理性 20分
     */
    public AssessmentResponse assess(Long userId, String date) {
        String endDate   = date != null ? date : LocalDate.now().toString();
        String startDate = LocalDate.parse(endDate).minusDays(6).toString();

        // 查近7天数据
        List<DailySteps> stepsList = stepsRepo.findByUserIdAndDateBetweenOrderByDateAsc(userId, startDate, endDate);
        List<SleepRecord> sleepList = sleepRepo.findByUserIdOrderByStartTimeDesc(userId, PageRequest.of(0, 7));
        List<DietLog> dietList = dietLogRepo.findByUserIdAndDateBetweenOrderByDateAsc(userId, startDate, endDate);

        // 计算均值
        int avgSteps = stepsList.isEmpty() ? 0
                : (int) stepsList.stream().mapToInt(DailySteps::getSteps).average().orElse(0);
        double avgSleep = sleepList.isEmpty() ? 0
                : sleepList.stream().mapToDouble(SleepRecord::getDurationHours).average().orElse(0);
        double avgCalories = dietList.isEmpty() ? 0
                : dietList.stream().mapToDouble(DietLog::getCalories).average().orElse(0);

        // 步数评分（满分 40）：目标 8000 步/天
        int stepsScore;
        String stepsRating;
        if      (avgSteps >= 10000) { stepsScore = 40; stepsRating = "优秀"; }
        else if (avgSteps >= 8000)  { stepsScore = 35; stepsRating = "良好"; }
        else if (avgSteps >= 5000)  { stepsScore = 25; stepsRating = "中等"; }
        else                        { stepsScore = 10; stepsRating = "不足"; }

        // 睡眠评分（满分 40）：目标 7-9 小时
        int sleepScore;
        String sleepRating;
        if      (avgSleep >= 7 && avgSleep <= 9) { sleepScore = 40; sleepRating = "优秀"; }
        else if (avgSleep >= 6 && avgSleep < 7)  { sleepScore = 30; sleepRating = "良好"; }
        else if (avgSleep >= 5 && avgSleep < 6)  { sleepScore = 20; sleepRating = "中等"; }
        else                                     { sleepScore = 10; sleepRating = "不足"; }

        // 饮食评分（满分 20）：目标热量 1800-2200 kcal
        int dietScore;
        String dietRating;
        if      (avgCalories >= 1800 && avgCalories <= 2200) { dietScore = 20; dietRating = "优秀"; }
        else if (avgCalories >= 1500 && avgCalories <= 2500) { dietScore = 15; dietRating = "良好"; }
        else if (avgCalories > 0)                            { dietScore = 10; dietRating = "中等"; }
        else                                                 { dietScore = 5;  dietRating = "数据不足"; }

        int totalScore = stepsScore + sleepScore + dietScore;

        // 生成建议文本
        String suggestion = buildSuggestion(avgSteps, avgSleep, avgCalories, stepsRating, sleepRating, dietRating);

        return new AssessmentResponse(
                totalScore, suggestion,
                stepsRating, sleepRating, dietRating,
                avgSteps,
                Math.round(avgSleep * 10.0) / 10.0,
                Math.round(avgCalories * 10.0) / 10.0
        );
    }

    private String buildSuggestion(int avgSteps, double avgSleep, double avgCalories,
                                   String stepsRating, String sleepRating, String dietRating) {
        StringBuilder sb = new StringBuilder();
        if ("不足".equals(stepsRating)) {
            sb.append("您近7天日均步数仅 ").append(avgSteps).append("步，建议每天增加20-30分钟的步行活动。");
        }
        if ("不足".equals(sleepRating) || "中等".equals(sleepRating)) {
            sb.append("睡眠均值 ").append(String.format("%.1f", avgSleep))
              .append("小时，保持 7-9 小时的规律睡眠有助于提升整体健康水平。");
        }
        if ("数据不足".equals(dietRating)) {
            sb.append("近期饮食记录较少，建议坚持记录每日摄入以获得更准确的评估。");
        }
        if (sb.isEmpty()) {
            sb.append("您的健康数据表现良好，请继续保持当前的运动和饮食习惯！");
        }
        return sb.toString().trim();
    }

    @Transactional
    public DailySteps simulateWalk(Long userId) {
        String today = LocalDate.now().toString();
        DailySteps steps = stepsRepo.findByUserIdAndDate(userId, today)
                                   .orElseGet(() -> {
                                       DailySteps s = new DailySteps();
                                       s.setUserId(userId);
                                       s.setDate(today);
                                       s.setSteps(0);
                                       s.setCalories(0.0);
                                       s.setGmtCreate(LocalDateTime.now().format(DT_FMT));
                                       return s;
                                   });

        // 模拟增加 50 - 300 步
        int increment = (int) (Math.random() * 250 + 50);
        steps.setSteps(steps.getSteps() + increment);
        steps.setCalories(steps.getSteps() * 0.04);
        steps.setGmtCreate(LocalDateTime.now().format(DT_FMT));
        
        return stepsRepo.save(steps);
    }
}
