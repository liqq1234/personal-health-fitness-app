package com.freefitness.auth;

import com.freefitness.common.util.JwtUtil;
import com.freefitness.auth.dto.LoginRequest;
import com.freefitness.auth.dto.RegisterRequest;
import com.freefitness.user.entity.User;
import com.freefitness.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class AuthServiceTest {

    @Mock
    private UserRepository userRepository;
    @Mock
    private PasswordEncoder passwordEncoder;
    @Mock
    private JwtUtil jwtUtil;

    @InjectMocks
    private AuthService authService;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void testRegisterSuccess() {
        User user = new User();
        user.setEmail("test@ex.com");
        user.setPassword("rawPass");

        when(userRepository.findByEmail(anyString())).thenReturn(Optional.empty());
        when(passwordEncoder.encode(anyString())).thenReturn("hashedPass");
        when(userRepository.save(any(User.class))).thenAnswer(i -> {
            User saved = i.getArgument(0);
            saved.setUserId(1L);
            return saved;
        });
        when(jwtUtil.generateAccessToken(anyLong(), anyString())).thenReturn("fakeAccess");
        when(jwtUtil.generateRefreshToken(anyLong(), anyString())).thenReturn("fakeRefresh");

        RegisterRequest req = new RegisterRequest();
        req.setUserCode("test_user");
        req.setPassword("rawPass");
        
        var result = authService.register(req);
        assertNotNull(result);
        assertEquals(1L, result.getUserId());
        assertEquals("fakeAccess", result.getToken());
    }

    @Test
    void testLoginSuccess() {
        User existing = new User();
        existing.setUserId(1L);
        existing.setUserCode("test_user");
        existing.setPassword("hashedPass");

        when(userRepository.findByUserCode("test_user")).thenReturn(Optional.of(existing));
        when(passwordEncoder.matches("rawPass", "hashedPass")).thenReturn(true);
        when(jwtUtil.generateAccessToken(1L, "test_user")).thenReturn("fakeAccess");

        LoginRequest req = new LoginRequest();
        req.setUserCode("test_user");
        req.setPassword("rawPass");

        var result = authService.login(req);
        assertEquals("fakeAccess", result.getToken());
    }
}
