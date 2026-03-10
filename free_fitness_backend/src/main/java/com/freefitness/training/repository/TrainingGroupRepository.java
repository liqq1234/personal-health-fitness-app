package com.freefitness.training.repository;

import com.freefitness.training.entity.TrainingGroup;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface TrainingGroupRepository extends JpaRepository<TrainingGroup, Long> {

    @Query("SELECT g FROM TrainingGroup g WHERE " +
           "(:category IS NULL OR g.groupCategory = :category) AND " +
           "(:level    IS NULL OR g.groupLevel    = :level)    AND " +
           "(:keyword  IS NULL OR g.groupName LIKE %:keyword%)")
    Page<TrainingGroup> search(@Param("category") String category,
                               @Param("level")    String level,
                               @Param("keyword")  String keyword,
                               Pageable pageable);
}
