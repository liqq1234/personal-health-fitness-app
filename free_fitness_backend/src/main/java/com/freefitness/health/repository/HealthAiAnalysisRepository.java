package com.freefitness.health.repository;

import com.freefitness.health.entity.HealthAiAnalysis;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface HealthAiAnalysisRepository extends JpaRepository<HealthAiAnalysis, Long> {
    Optional<HealthAiAnalysis> findFirstByUserIdAndTypeOrderByDateDesc(Long userId, String type);
}
