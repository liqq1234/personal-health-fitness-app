package com.freefitness.common.util;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

/**
 * JWT 工具类：生成 / 解析 / 验证 Token
 */
@Component
public class JwtUtil {

    @Value("${jwt.secret}")
    private String secret;

    @Value("${jwt.expiration}")
    private long expiration;       // 秒

    @Value("${jwt.refresh-expiration}")
    private long refreshExpiration; // 秒

    private SecretKey getKey() {
        return Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }

    /** 生成 Access Token */
    public String generateAccessToken(Long userId, String userCode) {
        return buildToken(userId, userCode, expiration * 1000L);
    }

    /** 生成 Refresh Token */
    public String generateRefreshToken(Long userId, String userCode) {
        return buildToken(userId, userCode, refreshExpiration * 1000L);
    }

    private String buildToken(Long userId, String userCode, long validMs) {
        Date now = new Date();
        return Jwts.builder()
                .subject(String.valueOf(userId))
                .claim("userCode", userCode)
                .issuedAt(now)
                .expiration(new Date(now.getTime() + validMs))
                .signWith(getKey())
                .compact();
    }

    /** 解析 Claims，失败则抛出异常 */
    public Claims parseToken(String token) {
        return Jwts.parser()
                .verifyWith(getKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    /** 从 Token 中提取 userId */
    public Long getUserId(String token) {
        return Long.parseLong(parseToken(token).getSubject());
    }

    /** 验证 Token 是否有效（不过期、签名正确） */
    public boolean isValid(String token) {
        try {
            Claims claims = parseToken(token);
            return claims.getExpiration().after(new Date());
        } catch (Exception e) {
            return false;
        }
    }

    public long getExpiration() {
        return expiration;
    }
}
