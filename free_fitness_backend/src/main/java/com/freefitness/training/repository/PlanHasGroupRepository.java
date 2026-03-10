package com.freefitness.training.repository;

import com.freefitness.training.entity.PlanHasGroup;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PlanHasGroupRepository extends JpaRepository<PlanHasGroup, Long> {
    List<PlanHasGroup> findByPlanIdOrderByDayNumberAsc(Long planId);
    void deleteByPlanId(Long planId);
    boolean existsByGroupId(Long groupId);
}
