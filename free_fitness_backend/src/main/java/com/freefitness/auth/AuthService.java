package com.freefitness.auth;

import com.freefitness.auth.dto.LoginRequest;
import com.freefitness.auth.dto.RegisterRequest;
import com.freefitness.auth.dto.TokenResponse;
import com.freefitness.common.util.JwtUtil;
import com.freefitness.user.entity.User;
import com.freefitness.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * 认证服务：注册、登录、刷新令牌
 */
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");

    /**
     * 1.2 用户注册
     */
    @Transactional
    public TokenResponse register(RegisterRequest req) {
        if (userRepository.existsByUserCode(req.getUserCode())) {
            throw new IllegalArgumentException("账号已存在：" + req.getUserCode());
        }

        User user = new User();
        user.setUserName(req.getUserName());
        user.setUserCode(req.getUserCode());
        user.setPassword(passwordEncoder.encode(req.getPassword()));
        user.setGender(req.getGender());
        user.setDateOfBirth(req.getDateOfBirth());
        user.setHeight(req.getHeight());
        user.setHeightUnit(req.getHeightUnit() != null ? req.getHeightUnit() : "cm");
        user.setCurrentWeight(req.getCurrentWeight());
        user.setWeightUnit(req.getWeightUnit() != null ? req.getWeightUnit() : "kg");
        user.setGmtCreate(LocalDateTime.now().format(FMT));

        user = userRepository.save(user);

        String accessToken  = jwtUtil.generateAccessToken(user.getUserId(), user.getUserCode());
        String refreshToken = jwtUtil.generateRefreshToken(user.getUserId(), user.getUserCode());
        return new TokenResponse(user.getUserId(), accessToken, refreshToken, jwtUtil.getExpiration());
    }

    /**
     * 1.3 用户登录
     */
    public TokenResponse login(LoginRequest req) {
        User user = userRepository.findByUserCode(req.getUserCode())
                .orElseThrow(() -> new IllegalArgumentException("账号不存在"));

        if (!passwordEncoder.matches(req.getPassword(), user.getPassword())) {
            throw new IllegalArgumentException("密码错误");
        }

        String accessToken  = jwtUtil.generateAccessToken(user.getUserId(), user.getUserCode());
        String refreshToken = jwtUtil.generateRefreshToken(user.getUserId(), user.getUserCode());
        return new TokenResponse(user.getUserId(), accessToken, refreshToken, jwtUtil.getExpiration());
    }

    /**
     * 1.4 刷新令牌
     */
    public TokenResponse refresh(String refreshToken) {
        if (!jwtUtil.isValid(refreshToken)) {
            throw new IllegalArgumentException("Refresh Token 无效或已过期");
        }
        Long userId = jwtUtil.getUserId(refreshToken);
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("用户不存在"));

        String newAccess  = jwtUtil.generateAccessToken(user.getUserId(), user.getUserCode());
        String newRefresh = jwtUtil.generateRefreshToken(user.getUserId(), user.getUserCode());
        return new TokenResponse(user.getUserId(), newAccess, newRefresh, jwtUtil.getExpiration());
    }
}
