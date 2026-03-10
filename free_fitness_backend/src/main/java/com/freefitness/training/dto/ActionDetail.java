package com.freefitness.training.dto;

import com.freefitness.training.entity.Action;
import com.freefitness.training.entity.Exercise;
import lombok.Data;

/**
 * 动作详情：Action + 关联的 Exercise 基础信息
 */
@Data
public class ActionDetail {
    private Long actionId;
    private Long groupId;
    private Integer frequency;
    private Integer duration;
    private Double equipmentWeight;
    // 内嵌 Exercise 关键字段
    private Long exerciseId;
    private String exerciseName;
    private String category;
    private String countingMode;
    private String level;
    private String images;

    public static ActionDetail from(Action action, Exercise exercise) {
        ActionDetail d = new ActionDetail();
        d.setActionId(action.getActionId());
        d.setGroupId(action.getGroupId());
        d.setFrequency(action.getFrequency());
        d.setDuration(action.getDuration());
        d.setEquipmentWeight(action.getEquipmentWeight());
        if (exercise != null) {
            d.setExerciseId(exercise.getExerciseId());
            d.setExerciseName(exercise.getExerciseName());
            d.setCategory(exercise.getCategory());
            d.setCountingMode(exercise.getCountingMode());
            d.setLevel(exercise.getLevel());
            d.setImages(exercise.getImages());
        }
        return d;
    }
}
