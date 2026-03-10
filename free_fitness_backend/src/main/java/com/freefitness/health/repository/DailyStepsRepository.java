package com.freefitness.health.repository;

import com.freefitness.health.entity.DailySteps;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface DailyStepsRepository extends JpaRepository<DailySteps, Long> {
    Optional<DailySteps> findByUserIdAndDate(Long userId, String date);
    List<DailySteps> findByUserIdAndDateBetweenOrderByDateAsc(Long userId, String startDate, String endDate);
}
