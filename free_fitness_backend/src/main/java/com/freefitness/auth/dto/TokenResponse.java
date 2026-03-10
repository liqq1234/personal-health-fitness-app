package com.freefitness.auth.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class TokenResponse {
    private Long userId;
    private String token;
    private String refreshToken;
    private long expiresIn;    // 秒
}
