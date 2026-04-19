package com.freefitness.social.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class FriendHealthSummary {
    private Long totalSteps;
    private Double totalDistance; // in km
    private Double totalCalories;
    private Integer activeDays;
}
