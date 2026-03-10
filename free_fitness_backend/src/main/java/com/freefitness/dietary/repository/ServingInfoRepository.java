package com.freefitness.dietary.repository;

import com.freefitness.dietary.entity.ServingInfo;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ServingInfoRepository extends JpaRepository<ServingInfo, Long> {
    List<ServingInfo> findByFoodIdAndIsDeletedFalse(Long foodId);
}
