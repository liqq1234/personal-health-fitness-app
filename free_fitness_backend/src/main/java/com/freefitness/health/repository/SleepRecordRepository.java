package com.freefitness.health.repository;

import com.freefitness.health.entity.SleepRecord;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface SleepRecordRepository extends JpaRepository<SleepRecord, Long> {
    List<SleepRecord> findByUserIdOrderByStartTimeDesc(Long userId, Pageable pageable);
    List<SleepRecord> findByUserIdOrderByStartTimeDesc(Long userId);
}
