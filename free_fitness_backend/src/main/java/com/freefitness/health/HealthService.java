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
    private final AiExerciseService aiExerciseService;
    private final AiSleepService aiSleepService;
    private final com.freefitness.user.repository.UserRepository userRepo;
    private final HealthAiAnalysisRepository aiAnalysisRepo;

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

    // ─────────────── 2.8 运动分析 ───────────────
    @Transactional
    public com.freefitness.health.dto.ExerciseAnalysis getExerciseAnalysis(Long userId, boolean force) {
        String today = LocalDate.now().toString();

        // 1. 如果不是强制更新，先看库里有没有今天的或者是最近的一条
        if (!force) {
            var latestOpt = aiAnalysisRepo.findFirstByUserIdAndTypeOrderByDateDesc(userId, "EXERCISE");
            if (latestOpt.isPresent()) {
                HealthAiAnalysis cached = latestOpt.get();
                // 如果是今天的，直接返回
                // 这里为了简单，即使是昨天的也返回吧，只要用户不强制刷新，就用旧的。
                // 如果需要严格一点，可以判断 cached.getDate().equals(today)
                
                // 重新构建周趋势图表数据（图表总是实时的）
                List<com.freefitness.health.dto.ExerciseAnalysis.DailyStat> weeklyData = buildWeeklyData(userId);
                return new com.freefitness.health.dto.ExerciseAnalysis(weeklyData, cached.getFeedback(), cached.getScore());
            }
        }

        // 2. 如果强制更新，或者库里没有，则执行 AI 分析
        LocalDate now = LocalDate.now();
        String endDate = now.toString() + "T23:59:59";
        String startDateWeekly = now.minusDays(6).toString() + "T00:00:00";
        String startDateBiWeekly = now.minusDays(13).toString() + "T00:00:00";

        // 1. 周维度图表数据 (最近7天)
        List<ExerciseSession> weeklySessions = sessionRepo.findByUserIdAndStartTimeBetweenOrderByStartTimeAsc(userId, startDateWeekly, endDate);
        Map<String, com.freefitness.health.dto.ExerciseAnalysis.DailyStat> statMap = new java.util.TreeMap<>();
        for (int i = 0; i < 7; i++) {
            String date = now.minusDays(i).toString();
            statMap.put(date, new com.freefitness.health.dto.ExerciseAnalysis.DailyStat(date, 0.0, 0.0));
        }

        for (ExerciseSession s : weeklySessions) {
            String date = s.getStartTime().substring(0, 10);
            if (statMap.containsKey(date)) {
                com.freefitness.health.dto.ExerciseAnalysis.DailyStat ds = statMap.get(date);
                ds.setDistance(ds.getDistance() + (s.getDistance() / 1000.0));
                ds.setCalories(ds.getCalories() + (s.getCalories() != null ? s.getCalories() : 0.0));
            }
        }
        List<com.freefitness.health.dto.ExerciseAnalysis.DailyStat> weeklyData = new java.util.ArrayList<>(statMap.values());

        // 2. AI 反馈分析 (最近14天)
        List<ExerciseSession> biWeeklySessions = sessionRepo.findByUserIdAndStartTimeBetweenOrderByStartTimeAsc(userId, startDateBiWeekly, endDate);
        long activeDays = biWeeklySessions.stream().map(s -> s.getStartTime().substring(0, 10)).distinct().count();
        double totalDist = biWeeklySessions.stream().mapToDouble(s -> s.getDistance() / 1000.0).sum();
        double avgDist = activeDays > 0 ? totalDist / activeDays : 0;

        String summary = String.format("用户在过去14天内：有运动记录的天数为 %d 天，总运动距离 %.2f km，平均每次运动距离 %.2f km。",
                activeDays, totalDist, avgDist);

        // 简单的评分逻辑
        int score = (int) (activeDays * 7 + (totalDist > 20 ? 30 : totalDist * 1.5));
        if (score > 100) score = 100;

        // 生成个性化建议需要的用户信息
        Map<String, Object> userProfile = new java.util.HashMap<>();
        userRepo.findById(userId).ifPresent(u -> {
            userProfile.put("gender", u.getGender());
            userProfile.put("height", u.getHeight() != null ? u.getHeight() : 0.0);
            userProfile.put("weight", u.getCurrentWeight() != null ? u.getCurrentWeight() : 0.0);
            
            // 计算 BMI
            if (u.getHeight() != null && u.getHeight() > 0 && u.getCurrentWeight() != null) {
                double heightM = u.getHeight() / 100.0;
                userProfile.put("bmi", u.getCurrentWeight() / (heightM * heightM));
            } else {
                userProfile.put("bmi", 0.0);
            }

            // 计算年龄 (简单处理)
            if (u.getDateOfBirth() != null && u.getDateOfBirth().length() >= 4) {
                try {
                    int birthYear = Integer.parseInt(u.getDateOfBirth().substring(0, 4));
                    userProfile.put("age", LocalDate.now().getYear() - birthYear);
                } catch (Exception ignored) {}
            }
        });

        String feedback = aiExerciseService.generateExerciseFeedback(summary, userProfile);

        // 3. 保存到数据库以便下次直接读
        HealthAiAnalysis newAnalysis = new HealthAiAnalysis();
        newAnalysis.setUserId(userId);
        newAnalysis.setFeedback(feedback);
        newAnalysis.setScore(score);
        newAnalysis.setDate(today);
        newAnalysis.setType("EXERCISE");
        newAnalysis.setGmtCreate(LocalDateTime.now().format(DT_FMT));
        aiAnalysisRepo.save(newAnalysis);

        return new com.freefitness.health.dto.ExerciseAnalysis(weeklyData, feedback, score);
    }

    @Transactional
    public com.freefitness.health.dto.SleepAnalysis getSleepAnalysis(Long userId, boolean force) {
        String today = LocalDate.now().toString();

        if (!force) {
            var latestOpt = aiAnalysisRepo.findFirstByUserIdAndTypeOrderByDateDesc(userId, "SLEEP");
            if (latestOpt.isPresent()) {
                HealthAiAnalysis cached = latestOpt.get();
                List<com.freefitness.health.dto.SleepAnalysis.DailyStat> weeklyData = buildWeeklySleepData(userId);
                return new com.freefitness.health.dto.SleepAnalysis(weeklyData, cached.getFeedback(), cached.getScore());
            }
        }

        LocalDate now = LocalDate.now();
        String endDate = now.toString() + "T23:59:59";
        String startDateWeekly = now.minusDays(6).toString() + "T00:00:00";
        String startDateBiWeekly = now.minusDays(13).toString() + "T00:00:00";

        // 1. 图表数据
        List<com.freefitness.health.dto.SleepAnalysis.DailyStat> weeklyData = buildWeeklySleepData(userId);

        // 2. AI 分析摘要 (最近14天)
        List<SleepRecord> biWeeklySleeps = sleepRepo.findByUserIdOrderByStartTimeDesc(userId, PageRequest.of(0, 14));
        double totalDuration = biWeeklySleeps.stream().mapToDouble(SleepRecord::getDurationHours).sum();
        double avgDuration = biWeeklySleeps.isEmpty() ? 0 : totalDuration / biWeeklySleeps.size();
        double avgQuality = biWeeklySleeps.isEmpty() ? 0 : biWeeklySleeps.stream()
                .mapToInt(r -> r.getQuality() != null ? r.getQuality() : 0)
                .average().orElse(0);

        // 计算规律性 (简单逻辑：检查入睡时间的标准差，或者只是对比统计)
        long inconsistentCount = 0;
        // 这里可以实现更复杂的规律性算法
        
        String summary = String.format("用户在过去两周内：共有 %d 条睡眠记录，平均每晚时长 %.1f 小时，平均质量评分 %.1f/100。",
                biWeeklySleeps.size(), avgDuration, avgQuality);

        // 评分逻辑
        int score = (int) (avgDuration >= 7 && avgDuration <= 9 ? 80 : 60);
        score += (avgQuality / 5);
        if (score > 100) score = 100;

        // 获取用户信息
        Map<String, Object> userProfile = new java.util.HashMap<>();
        userRepo.findById(userId).ifPresent(u -> {
            userProfile.put("gender", u.getGender());
            if (u.getDateOfBirth() != null && u.getDateOfBirth().length() >= 4) {
                try {
                    int birthYear = Integer.parseInt(u.getDateOfBirth().substring(0, 4));
                    userProfile.put("age", LocalDate.now().getYear() - birthYear);
                } catch (Exception ignored) {}
            }
        });

        String feedback = aiSleepService.generateSleepFeedback(summary, userProfile);

        // 3. 保存
        HealthAiAnalysis newAnalysis = new HealthAiAnalysis();
        newAnalysis.setUserId(userId);
        newAnalysis.setFeedback(feedback);
        newAnalysis.setScore(score);
        newAnalysis.setDate(today);
        newAnalysis.setType("SLEEP");
        newAnalysis.setGmtCreate(LocalDateTime.now().format(DT_FMT));
        aiAnalysisRepo.save(newAnalysis);

        return new com.freefitness.health.dto.SleepAnalysis(weeklyData, feedback, score);
    }

    private List<com.freefitness.health.dto.SleepAnalysis.DailyStat> buildWeeklySleepData(Long userId) {
        LocalDate now = LocalDate.now();
        List<SleepRecord> records = sleepRepo.findByUserIdOrderByStartTimeDesc(userId, PageRequest.of(0, 7));
        Map<String, com.freefitness.health.dto.SleepAnalysis.DailyStat> statMap = new java.util.TreeMap<>();
        for (int i = 0; i < 7; i++) {
            String date = now.minusDays(i).toString();
            statMap.put(date, new com.freefitness.health.dto.SleepAnalysis.DailyStat(date, 0.0, 0));
        }
        for (SleepRecord r : records) {
            String date = r.getStartTime().substring(0, 10);
            if (statMap.containsKey(date)) {
                com.freefitness.health.dto.SleepAnalysis.DailyStat ds = statMap.get(date);
                ds.setDuration(r.getDurationHours());
                ds.setQuality(r.getQuality() != null ? r.getQuality() : 0);
            }
        }
        return new java.util.ArrayList<>(statMap.values());
    }

    private List<com.freefitness.health.dto.ExerciseAnalysis.DailyStat> buildWeeklyData(Long userId) {
        LocalDate now = LocalDate.now();
        String endDate = now.toString() + "T23:59:59";
        String startDateWeekly = now.minusDays(6).toString() + "T00:00:00";
        List<ExerciseSession> weeklySessions = sessionRepo.findByUserIdAndStartTimeBetweenOrderByStartTimeAsc(userId, startDateWeekly, endDate);
        Map<String, com.freefitness.health.dto.ExerciseAnalysis.DailyStat> statMap = new java.util.TreeMap<>();
        for (int i = 0; i < 7; i++) {
            String date = now.minusDays(i).toString();
            statMap.put(date, new com.freefitness.health.dto.ExerciseAnalysis.DailyStat(date, 0.0, 0.0));
        }
        for (ExerciseSession s : weeklySessions) {
            String date = s.getStartTime().substring(0, 10);
            if (statMap.containsKey(date)) {
                com.freefitness.health.dto.ExerciseAnalysis.DailyStat ds = statMap.get(date);
                ds.setDistance(ds.getDistance() + (s.getDistance() / 1000.0));
                ds.setCalories(ds.getCalories() + (s.getCalories() != null ? s.getCalories() : 0.0));
            }
        }
        return new java.util.ArrayList<>(statMap.values());
    }
}
