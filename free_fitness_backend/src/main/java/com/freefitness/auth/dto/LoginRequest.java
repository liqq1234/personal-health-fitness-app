package com.freefitness.auth.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class LoginRequest {
    @NotBlank
    private String userCode;
    @NotBlank
    private String password;
}
