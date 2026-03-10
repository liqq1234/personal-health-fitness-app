package com.freefitness.user.repository;

import com.freefitness.user.entity.WeightTrend;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface WeightTrendRepository extends JpaRepository<WeightTrend, Long> {
    List<WeightTrend> findByUserIdAndGmtCreateBetweenOrderByGmtCreateAsc(
            Long userId, String startDate, String endDate);
    List<WeightTrend> findTop30ByUserIdOrderByGmtCreateDesc(Long userId);
}
