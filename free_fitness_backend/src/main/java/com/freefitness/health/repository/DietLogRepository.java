package com.freefitness.health.repository;

import com.freefitness.health.entity.DietLog;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface DietLogRepository extends JpaRepository<DietLog, Long> {
    List<DietLog> findByUserIdAndDateOrderByGmtCreateAsc(Long userId, String date);
    List<DietLog> findByUserIdAndDateBetweenOrderByDateAsc(Long userId, String startDate, String endDate);
}
