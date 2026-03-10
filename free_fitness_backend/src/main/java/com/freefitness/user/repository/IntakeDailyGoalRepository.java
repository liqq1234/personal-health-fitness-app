package com.freefitness.user.repository;

import com.freefitness.user.entity.IntakeDailyGoal;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface IntakeDailyGoalRepository extends JpaRepository<IntakeDailyGoal, Long> {
    List<IntakeDailyGoal> findByUserId(Long userId);
    Optional<IntakeDailyGoal> findByUserIdAndDayOfWeek(Long userId, String dayOfWeek);
}
