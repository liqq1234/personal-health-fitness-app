package com.freefitness.dietary.repository;

import com.freefitness.dietary.entity.Food;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface FoodRepository extends JpaRepository<Food, Long> {

    @Query("SELECT f FROM Food f WHERE f.isDeleted = false AND " +
           "(:category IS NULL OR f.category = :category) AND " +
           "(:keyword  IS NULL OR f.product LIKE %:keyword% OR f.brand LIKE %:keyword%)")
    Page<Food> search(@Param("category") String category,
                      @Param("keyword")  String keyword,
                      Pageable pageable);
}
