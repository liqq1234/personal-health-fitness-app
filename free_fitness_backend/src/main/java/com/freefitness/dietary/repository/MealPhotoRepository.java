package com.freefitness.dietary.repository;

import com.freefitness.dietary.entity.MealPhoto;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MealPhotoRepository extends JpaRepository<MealPhoto, Long> {
    List<MealPhoto> findByUserIdAndDateOrderByGmtCreateAsc(Long userId, String date);
    List<MealPhoto> findByUserIdAndDateAndMealCategory(Long userId, String date, String mealCategory);
}
