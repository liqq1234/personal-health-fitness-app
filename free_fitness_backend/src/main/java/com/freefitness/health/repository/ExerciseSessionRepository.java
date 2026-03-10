package com.freefitness.health.repository;

import com.freefitness.health.entity.ExerciseSession;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ExerciseSessionRepository extends JpaRepository<ExerciseSession, Long> {
    List<ExerciseSession> findByUserIdOrderByStartTimeDesc(Long userId, Pageable pageable);
}
