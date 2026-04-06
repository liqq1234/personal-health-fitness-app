package com.freefitness.dietary.dto;

import com.freefitness.dietary.entity.DailyFoodItem;
import com.freefitness.dietary.entity.Food;
import com.freefitness.dietary.entity.ServingInfo;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class DailyItemDetail {
    private DailyFoodItem dailyFoodItem;
    private Food food;
    private ServingInfo serving;
}
