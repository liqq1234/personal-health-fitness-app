package com.freefitness.training.repository;

import com.freefitness.training.entity.Plan;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface PlanRepository extends JpaRepository<Plan, Long> {

    @Query("SELECT p FROM Plan p WHERE " +
           "(:category IS NULL OR p.planCategory = :category) AND " +
           "(:level    IS NULL OR p.planLevel    = :level)    AND " +
           "(:keyword  IS NULL OR p.planName LIKE %:keyword%)")
    Page<Plan> search(@Param("category") String category,
                      @Param("level")    String level,
                      @Param("keyword")  String keyword,
                      Pageable pageable);
}
