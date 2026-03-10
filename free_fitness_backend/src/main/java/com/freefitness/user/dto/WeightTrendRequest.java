package com.freefitness.user.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class WeightTrendRequest {
    @NotNull
    private Double weight;
    @NotBlank
    private String weightUnit;
    @NotNull
    private Double height;
    @NotBlank
    private String heightUnit;
    @NotNull
    private Double bmi;
    private String gmtCreate;   // yyyy-MM-dd'T'HH:mm:ss，不传则用服务器时间
}
