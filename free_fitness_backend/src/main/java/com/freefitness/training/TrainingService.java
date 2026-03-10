package com.freefitness.training;

import com.freefitness.training.dto.*;
import com.freefitness.training.entity.*;
import com.freefitness.training.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

/**
 * 训练模块服务：动作库 / 动作组 / 训练计划 / 训练日志 / 报告
 */
@Service
@RequiredArgsConstructor
public class TrainingService {

    private final ExerciseRepository exerciseRepo;
    private final ActionRepository actionRepo;
    private final TrainingGroupRepository groupRepo;
    private final PlanRepository planRepo;
    private final PlanHasGroupRepository planHasGroupRepo;
    private final TrainedDetailLogRepository logRepo;

    private static final DateTimeFormatter DT = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");
    private static final DateTimeFormatter D  = DateTimeFormatter.ofPattern("yyyy-MM-dd");

    // ──────── 3.2 动作库 ────────

    public Page<Exercise> searchExercises(String category, String level, String keyword,
                                          int page, int size) {
        return exerciseRepo.search(category, level, keyword, PageRequest.of(page, size));
    }

    public Exercise getExercise(Long id) {
        return exerciseRepo.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("动作不存在：" + id));
    }

    @Transactional
    public Exercise createExercise(Exercise req) {
        req.setExerciseId(null);
        req.setIsCustom(true);
        req.setGmtCreate(LocalDateTime.now().format(DT));
        return exerciseRepo.save(req);
    }

    @Transactional
    public Exercise updateExercise(Long id, Exercise req) {
        Exercise existing = getExercise(id);
        if (!Boolean.TRUE.equals(existing.getIsCustom())) {
            throw new IllegalArgumentException("系统内置动作不可修改");
        }
        req.setExerciseId(id);
        req.setIsCustom(true);
        req.setGmtModified(LocalDateTime.now().format(DT));
        return exerciseRepo.save(req);
    }

    @Transactional
    public void deleteExercise(Long id) {
        Exercise existing = getExercise(id);
        if (!Boolean.TRUE.equals(existing.getIsCustom())) {
            throw new IllegalArgumentException("系统内置动作不可删除");
        }
        exerciseRepo.deleteById(id);
    }

    // ──────── 3.3 动作组内动作批量替换 ────────

    public List<ActionDetail> getGroupActions(Long groupId) {
        return enrichActions(actionRepo.findByGroupId(groupId));
    }

    @Transactional
    public List<ActionDetail> replaceGroupActions(Long groupId, List<Action> newActions) {
        actionRepo.deleteByGroupId(groupId);
        newActions.forEach(a -> {
            a.setActionId(null);
            a.setGroupId(groupId);
            actionRepo.save(a);
        });
        return enrichActions(actionRepo.findByGroupId(groupId));
    }

    private List<ActionDetail> enrichActions(List<Action> actions) {
        return actions.stream().map(a -> {
            Exercise ex = exerciseRepo.findById(a.getExerciseId()).orElse(null);
            return ActionDetail.from(a, ex);
        }).collect(Collectors.toList());
    }

    // ──────── 3.4 动作组 CRUD ────────

    public Page<TrainingGroup> searchGroups(String category, String level, String keyword,
                                            int page, int size) {
        return groupRepo.search(category, level, keyword, PageRequest.of(page, size));
    }

    public GroupDetail getGroupDetail(Long groupId) {
        TrainingGroup group = groupRepo.findById(groupId)
                .orElseThrow(() -> new IllegalArgumentException("动作组不存在：" + groupId));
        return GroupDetail.from(group, getGroupActions(groupId));
    }

    @Transactional
    public GroupDetail createGroup(TrainingGroup req, List<Action> actions) {
        req.setGroupId(null);
        req.setGmtCreate(LocalDateTime.now().format(DT));
        TrainingGroup saved = groupRepo.save(req);
        if (actions != null && !actions.isEmpty()) {
            replaceGroupActions(saved.getGroupId(), actions);
        }
        return getGroupDetail(saved.getGroupId());
    }

    @Transactional
    public TrainingGroup updateGroup(Long id, TrainingGroup req) {
        groupRepo.findById(id).orElseThrow(() -> new IllegalArgumentException("动作组不存在：" + id));
        req.setGroupId(id);
        req.setGmtModified(LocalDateTime.now().format(DT));
        return groupRepo.save(req);
    }

    @Transactional
    public void deleteGroup(Long id) {
        if (planHasGroupRepo.existsByGroupId(id)) {
            throw new IllegalArgumentException("该动作组已被训练计划引用，无法删除");
        }
        actionRepo.deleteByGroupId(id);
        groupRepo.deleteById(id);
    }

    // ──────── 3.5 训练计划 CRUD ────────

    public Page<Plan> searchPlans(String category, String level, String keyword,
                                  int page, int size) {
        return planRepo.search(category, level, keyword, PageRequest.of(page, size));
    }

    public PlanDetail getPlanDetail(Long planId) {
        Plan plan = planRepo.findById(planId)
                .orElseThrow(() -> new IllegalArgumentException("训练计划不存在：" + planId));

        List<PlanHasGroup> relations = planHasGroupRepo.findByPlanIdOrderByDayNumberAsc(planId);
        List<PlanDetail.DayGroup> days = relations.stream().map(r -> {
            PlanDetail.DayGroup dg = new PlanDetail.DayGroup();
            dg.setDayNumber(r.getDayNumber());
            dg.setGroup(getGroupDetail(r.getGroupId()));
            return dg;
        }).collect(Collectors.toList());

        return PlanDetail.from(plan, days);
    }

    @Transactional
    public PlanDetail createPlan(PlanRequest req) {
        Plan plan = new Plan();
        plan.setPlanCode(req.getPlanCode() != null ? req.getPlanCode()
                : "CUSTOM_" + System.currentTimeMillis());
        plan.setPlanName(req.getPlanName());
        plan.setPlanCategory(req.getPlanCategory());
        plan.setPlanLevel(req.getPlanLevel());
        plan.setPlanPeriod(req.getPlanPeriod());
        plan.setDescription(req.getDescription());
        plan.setGmtCreate(LocalDateTime.now().format(DT));
        plan = planRepo.save(plan);

        if (req.getDays() != null) {
            for (PlanRequest.DayGroupMapping dm : req.getDays()) {
                PlanHasGroup phg = new PlanHasGroup();
                phg.setPlanId(plan.getPlanId());
                phg.setGroupId(dm.getGroupId());
                phg.setDayNumber(dm.getDayNumber());
                planHasGroupRepo.save(phg);
            }
        }
        return getPlanDetail(plan.getPlanId());
    }

    @Transactional
    public PlanDetail updatePlan(Long planId, PlanRequest req) {
        Plan plan = planRepo.findById(planId)
                .orElseThrow(() -> new IllegalArgumentException("训练计划不存在：" + planId));
        if (req.getPlanName()     != null) plan.setPlanName(req.getPlanName());
        if (req.getPlanCategory() != null) plan.setPlanCategory(req.getPlanCategory());
        if (req.getPlanLevel()    != null) plan.setPlanLevel(req.getPlanLevel());
        if (req.getPlanPeriod()   != null) plan.setPlanPeriod(req.getPlanPeriod());
        if (req.getDescription()  != null) plan.setDescription(req.getDescription());
        plan.setGmtModified(LocalDateTime.now().format(DT));
        planRepo.save(plan);

        if (req.getDays() != null) {
            planHasGroupRepo.deleteByPlanId(planId);
            for (PlanRequest.DayGroupMapping dm : req.getDays()) {
                PlanHasGroup phg = new PlanHasGroup();
                phg.setPlanId(planId);
                phg.setGroupId(dm.getGroupId());
                phg.setDayNumber(dm.getDayNumber());
                planHasGroupRepo.save(phg);
            }
        }
        return getPlanDetail(planId);
    }

    @Transactional
    public void deletePlan(Long planId) {
        planHasGroupRepo.deleteByPlanId(planId);
        planRepo.deleteById(planId);
    }

    // ──────── 3.6 训练日志 ────────

    @Transactional
    public TrainedDetailLog addLog(Long userId, TrainedDetailLog req) {
        req.setTrainedDetailLogId(null);
        req.setUserId(userId);
        if (req.getTrainedDate() == null) {
            req.setTrainedDate(LocalDate.now().format(D));
        }
        return logRepo.save(req);
    }

    public Page<TrainedDetailLog> getLogs(Long userId, int page, int size) {
        return logRepo.findByUserIdOrderByTrainedStartTimeDesc(userId, PageRequest.of(page, size));
    }

    // ──────── 3.7 训练统计报告 ────────

    public TrainingReport getReport(Long userId, String period) {
        String endDate   = LocalDate.now().format(D);
        String startDate = switch (period.toLowerCase()) {
            case "week"  -> LocalDate.now().minusDays(6).format(D);
            case "month" -> LocalDate.now().minusDays(29).format(D);
            case "year"  -> LocalDate.now().minusDays(364).format(D);
            default      -> LocalDate.now().minusDays(6).format(D);
        };

        List<TrainedDetailLog> logs = logRepo.findByUserIdAndDateRange(userId, startDate, endDate);

        int totalSessions = logs.size();
        long totalDuration = logs.stream().mapToLong(TrainedDetailLog::getTrainedDuration).sum();
        int totalCalories  = logs.stream().mapToInt(l -> l.getConsumption() != null ? l.getConsumption() : 0).sum();
        double avgDuration = totalSessions == 0 ? 0
                : Math.round(totalDuration / 60.0 / totalSessions * 10.0) / 10.0;

        // 最频繁分类
        String mostFrequent = logs.stream()
                .filter(l -> l.getPlanCategory() != null)
                .collect(Collectors.groupingBy(TrainedDetailLog::getPlanCategory, Collectors.counting()))
                .entrySet().stream()
                .max(Map.Entry.comparingByValue())
                .map(Map.Entry::getKey)
                .orElse("暂无数据");

        return new TrainingReport(totalSessions, totalDuration, totalCalories, avgDuration, mostFrequent, period);
    }
}
