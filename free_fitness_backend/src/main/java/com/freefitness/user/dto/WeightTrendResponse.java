package com.freefitness.user.dto;

import lombok.Data;

@Data
public class WeightTrendResponse {
    private Long weightTrendId;
    private Long userId;
    private Double weight;      // 解密后的明文
    private String weightUnit;
    private Double height;
    private String heightUnit;
    private Double bmi;         // 解密后的明文
    private String gmtCreate;
}
