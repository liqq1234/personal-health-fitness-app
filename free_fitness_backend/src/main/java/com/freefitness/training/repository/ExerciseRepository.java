package com.freefitness.training.repository;

import com.freefitness.training.entity.Exercise;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ExerciseRepository extends JpaRepository<Exercise, Long> {

    @Query("SELECT e FROM Exercise e WHERE " +
           "(:category IS NULL OR e.category = :category) AND " +
           "(:level    IS NULL OR e.level    = :level)    AND " +
           "(:keyword  IS NULL OR e.exerciseName LIKE %:keyword%)")
    Page<Exercise> search(@Param("category") String category,
                          @Param("level")    String level,
                          @Param("keyword")  String keyword,
                          Pageable pageable);
}
