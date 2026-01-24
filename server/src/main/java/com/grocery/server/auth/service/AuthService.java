package com.grocery.server.auth.service;

import com.grocery.server.auth.dto.request.LoginRequest;
import com.grocery.server.auth.dto.request.RegisterRequest;
import com.grocery.server.auth.dto.response.AuthResponse;
import com.grocery.server.auth.security.JwtTokenProvider;
import com.grocery.server.user.entity.User;
import com.grocery.server.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Service: AuthService
 * Mục đích: Xử lý logic đăng nhập/đăng ký
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AuthService {
    
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider tokenProvider;
    private final AuthenticationManager authenticationManager;
    
    /**
     * Đăng ký tài khoản mới
     */
    @Transactional
    public AuthResponse register(RegisterRequest request) {
        // Kiểm tra số điện thoại đã tồn tại chưa
        if (userRepository.existsByPhoneNumber(request.getPhoneNumber())) {
            throw new IllegalArgumentException(
                "Số điện thoại " + request.getPhoneNumber() + " đã được sử dụng");
        }
        
        // Tạo user mới
        User user = User.builder()
                .phoneNumber(request.getPhoneNumber())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .fullName(request.getFullName())
                .role(request.getRole())
                .status(User.UserStatus.ACTIVE)
                .address(request.getAddress())
                .avatarUrl(request.getAvatarUrl())
                .build();
        
        // Lưu vào database
        user = userRepository.save(user);
        
        log.info("User registered successfully: {}", user.getPhoneNumber());
        
        // Tạo JWT token
        String token = tokenProvider.generateToken(user.getPhoneNumber());
        
        // Trả về response
        return AuthResponse.builder()
                .token(token)
                .userId(user.getId())
                .phoneNumber(user.getPhoneNumber())
                .fullName(user.getFullName())
                .role(user.getRole().name())
                .avatarUrl(user.getAvatarUrl())
                .build();
    }
    
    /**
     * Đăng nhập
     */
    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        // Authenticate user
        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        request.getPhoneNumber(),
                        request.getPassword()
                )
        );
        
        SecurityContextHolder.getContext().setAuthentication(authentication);
        
        // Tạo JWT token
        String token = tokenProvider.generateToken(request.getPhoneNumber());
        
        // Lấy thông tin user
        User user = userRepository.findByPhoneNumber(request.getPhoneNumber())
                .orElseThrow(() -> new IllegalArgumentException("User không tồn tại"));
        
        log.info("User logged in successfully: {}", user.getPhoneNumber());
        
        // Trả về response
        return AuthResponse.builder()
                .token(token)
                .userId(user.getId())
                .phoneNumber(user.getPhoneNumber())
                .fullName(user.getFullName())
                .role(user.getRole().name())
                .avatarUrl(user.getAvatarUrl())
                .build();
    }
    
    /**
     * Lấy thông tin user hiện tại (từ JWT token)
     */
    @Transactional(readOnly = true)
    public User getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String phoneNumber = authentication.getName();
        
        return userRepository.findByPhoneNumber(phoneNumber)
                .orElseThrow(() -> new IllegalArgumentException("User không tồn tại"));
    }
}
