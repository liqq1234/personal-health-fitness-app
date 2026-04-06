package com.freefitness.dietary.repository;

import com.freefitness.dietary.entity.DailyFoodItem;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface DailyFoodItemRepository extends JpaRepository<DailyFoodItem, Long> {
    List<DailyFoodItem> findByUserIdAndDateOrderByGmtCreateAsc(Long userId, String date);
    List<DailyFoodItem> findByUserIdAndDateAndMealCategoryOrderByGmtCreateAsc(
            Long userId, String date, String mealCategory);

    List<DailyFoodItem> findByUserIdAndDateBetweenOrderByGmtCreateAsc(
            Long userId, String startDate, String endDate);
}
