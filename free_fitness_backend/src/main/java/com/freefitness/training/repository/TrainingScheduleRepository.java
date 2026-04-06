package com.freefitness.training.repository;

import com.freefitness.training.entity.TrainingSchedule;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TrainingScheduleRepository extends JpaRepository<TrainingSchedule, Long> {
    List<TrainingSchedule> findByUserIdOrderByScheduledDateDescStartTimeDesc(Long userId);
    List<TrainingSchedule> findByUserIdAndScheduledDate(Long userId, String scheduledDate);
}
