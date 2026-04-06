package com.freefitness.auth;

import com.freefitness.auth.dto.LoginRequest;
import com.freefitness.auth.dto.RegisterRequest;
import com.freefitness.auth.dto.TokenResponse;
import com.freefitness.common.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

/**
 * 认证接口：注册 / 登录 / 刷新 Token
 */
@Slf4j
@Tag(name = "认证中心", description = "用户注册、登录授权、Token 刷新")
@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    /** 1.2 POST /api/v1/auth/register */
    @Operation(summary = "用户注册")
    @PostMapping("/register")
    public Result<TokenResponse> register(@Valid @RequestBody RegisterRequest req) {
        log.info("User registration attempt: username={}, code={}", req.getUserName(), req.getUserCode());
        return Result.success(authService.register(req));
    }

    /** 1.3 POST /api/v1/auth/login */
    @Operation(summary = "用户登录")
    @PostMapping("/login")
    public Result<TokenResponse> login(@Valid @RequestBody LoginRequest req) {
        log.info("User login attempt: userCode={}", req.getUserCode());
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
