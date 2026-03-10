package com.freefitness.user.entity;

import com.freefitness.common.util.CryptoConverter;
import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 体重趋势记录（对应 ff_weight_trend 表）
 * weight 和 bmi 字段在入库时自动 AES-256 加密，出库时自动解密
 */
@Data
@NoArgsConstructor
@Entity
@Table(name = "ff_weight_trend")
public class WeightTrend {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "weight_trend_id")
    private Long weightTrendId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    /** 自动加解密 */
    @Convert(converter = CryptoConverter.class)
    @Column(name = "weight", nullable = false, length = 512)
    private Double weight;

    @Column(name = "weight_unit", nullable = false, length = 10)
    private String weightUnit;

    @Column(name = "height", nullable = false)
    private Double height;

    @Column(name = "height_unit", nullable = false, length = 10)
    private String heightUnit;

    /** 自动加解密 */
    @Convert(converter = CryptoConverter.class)
    @Column(name = "bmi", nullable = false, length = 512)
    private Double bmi;

    @Column(name = "gmt_create", nullable = false, length = 30)
    private String gmtCreate;
}
