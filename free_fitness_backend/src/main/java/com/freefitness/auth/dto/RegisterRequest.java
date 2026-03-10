package com.freefitness.auth.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class RegisterRequest {
    @NotBlank
    private String userName;
    @NotBlank
    private String userCode;
    @NotBlank
    private String password;
    private String gender;
    private String dateOfBirth;
    private Double height;
    private String heightUnit;
    private Double currentWeight;
    private String weightUnit;
}
