package com.freefitness.user.dto;

import lombok.Data;

@Data
public class UpdateUserRequest {
    private String userName;
    private String userCode;
    private String gender;
    private String avatar;
    private String dateOfBirth;
    private Double height;
    private String heightUnit;
    private Double currentWeight;
    private Double targetWeight;
    private String weightUnit;
    private String description;
    private Integer rdaGoal;
    private Double proteinGoal;
    private Double fatGoal;
    private Double choGoal;
    private Integer actionRestTime;
}
