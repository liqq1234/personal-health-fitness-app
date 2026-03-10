package com.freefitness.training.dto;

import com.freefitness.training.entity.TrainingGroup;
import lombok.Data;

import java.util.List;

/**
 * 动作组详情：TrainingGroup + 嵌套 ActionDetail 列表
 */
@Data
public class GroupDetail {
    private Long groupId;
    private String groupName;
    private String groupCategory;
    private String groupLevel;
    private Integer consumption;
    private Integer timeSpent;
    private String description;
    private List<ActionDetail> actions;

    public static GroupDetail from(TrainingGroup g, List<ActionDetail> actions) {
        GroupDetail d = new GroupDetail();
        d.setGroupId(g.getGroupId());
        d.setGroupName(g.getGroupName());
        d.setGroupCategory(g.getGroupCategory());
        d.setGroupLevel(g.getGroupLevel());
        d.setConsumption(g.getConsumption());
        d.setTimeSpent(g.getTimeSpent());
        d.setDescription(g.getDescription());
        d.setActions(actions);
        return d;
    }
}
