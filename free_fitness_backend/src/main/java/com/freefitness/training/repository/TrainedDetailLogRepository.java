package com.freefitness.training.repository;

import com.freefitness.training.entity.TrainedDetailLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface TrainedDetailLogRepository extends JpaRepository<TrainedDetailLog, Long> {

    Page<TrainedDetailLog> findByUserIdOrderByTrainedStartTimeDesc(Long userId, Pageable pageable);

    @Query("SELECT t FROM TrainedDetailLog t WHERE t.userId = :userId " +
           "AND t.trainedDate BETWEEN :startDate AND :endDate " +
           "ORDER BY t.trainedDate ASC")
    List<TrainedDetailLog> findByUserIdAndDateRange(@Param("userId") Long userId,
                                                    @Param("startDate") String startDate,
                                                    @Param("endDate") String endDate);
}
