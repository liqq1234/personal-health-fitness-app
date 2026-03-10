package com.freefitness.auth;

import com.freefitness.auth.dto.LoginRequest;
import com.freefitness.auth.dto.RegisterRequest;
import com.freefitness.auth.dto.TokenResponse;
import com.freefitness.common.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

/**
 * 认证接口：注册 / 登录 / 刷新令牌
 */
@Tag(name = "认证", description = "用户注册、登录、JWT令牌刷新")
@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    /** 1.2 POST /api/v1/auth/register */
    @Operation(summary = "用户注册")
    @PostMapping("/register")
    public Result<TokenResponse> register(@Valid @RequestBody RegisterRequest req) {
        return Result.success(authService.register(req));
    }

    /** 1.3 POST /api/v1/auth/login */
    @Operation(summary = "用户登录")
    @PostMapping("/login")
    public Result<TokenResponse> login(@Valid @RequestBody LoginRequest req) {
        return Result.success(authService.login(req));
    }

    /** 1.4 POST /api/v1/auth/refresh */
    @Operation(summary = "刷新访问令牌")
    @PostMapping("/refresh")
    public Result<TokenResponse> refresh(@RequestHeader("Authorization") String authHeader) {
        String refreshToken = authHeader.startsWith("Bearer ")
                ? authHeader.substring(7) : authHeader;
        return Result.success(authService.refresh(refreshToken));
    }
}
