package com.grocery.server.auth.controller;

import com.grocery.server.auth.dto.request.LoginRequest;
import com.grocery.server.auth.dto.request.RegisterRequest;
import com.grocery.server.auth.dto.response.AuthResponse;
import com.grocery.server.auth.service.AuthService;
import com.grocery.server.shared.dto.ApiResponse;
import com.grocery.server.user.entity.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Controller: AuthController
 * Mục đích: REST API cho đăng nhập/đăng ký
 *
 * Base URL: /api/auth (context path /api + mapping /auth)
 */
@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
@Slf4j
public class AuthController {

    private final AuthService authService;

    /**
     * POST /api/auth/register
     * Đăng ký tài khoản mới
     *
     * Request Body:
     * {
     *   "phoneNumber": "0901234567",
     *   "password": "123456",
     *   "fullName": "Nguyễn Văn A",
     *   "role": "CUSTOMER",
     *   "address": "123 Đường ABC"
     * }
     *
     * Response:
     * {
     *   "success": true,
     *   "message": "Đăng ký thành công",
     *   "data": {
     *     "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
     *     "type": "Bearer",
     *     "userId": 1,
     *     "phoneNumber": "0901234567",
     *     "fullName": "Nguyễn Văn A",
     *     "role": "CUSTOMER"
     *   }
     * }
     */
    @PostMapping("/register")
    public ResponseEntity<ApiResponse<AuthResponse>> register(
            @Valid @RequestBody RegisterRequest request) {

        try {
            AuthResponse authResponse = authService.register(request);

            return ResponseEntity
                    .status(HttpStatus.CREATED)
                    .body(ApiResponse.success("Đăng ký thành công", authResponse));

        } catch (IllegalArgumentException e) {
            log.error("Registration failed: {}", e.getMessage());
            return ResponseEntity
                    .status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.error(e.getMessage()));
        } catch (Exception e) {
            log.error("Registration error", e);
            return ResponseEntity
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Đăng ký thất bại: " + e.getMessage()));
        }
    }

    /**
     * POST /api/auth/login
     * Đăng nhập
     *
     * Request Body:
     * {
     *   "phoneNumber": "0901234567",
     *   "password": "123456"
     * }
     *
     * Response:
     * {
     *   "success": true,
     *   "message": "Đăng nhập thành công",
     *   "data": {
     *     "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
     *     "type": "Bearer",
     *     "userId": 1,
     *     "phoneNumber": "0901234567",
     *     "fullName": "Nguyễn Văn A",
     *     "role": "CUSTOMER"
     *   }
     * }
     */
    @PostMapping("/login")
    public ResponseEntity<ApiResponse<AuthResponse>> login(
            @Valid @RequestBody LoginRequest request) {

        try {
            AuthResponse authResponse = authService.login(request);

            return ResponseEntity.ok(
                    ApiResponse.success("Đăng nhập thành công", authResponse));

        } catch (org.springframework.security.core.AuthenticationException e) {
            log.error("Login failed: {}", e.getMessage());
            return ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.error("Số điện thoại hoặc mật khẩu không đúng"));
        } catch (Exception e) {
            log.error("Login error", e);
            return ResponseEntity
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Đăng nhập thất bại: " + e.getMessage()));
        }
    }

    /**
     * GET /api/auth/me
     * Lấy thông tin user hiện tại
     *
     * Header:
     * Authorization: Bearer <token>
     *
     * Response:
     * {
     *   "success": true,
     *   "message": "Thành công",
     *   "data": {
     *     "id": 1,
     *     "phoneNumber": "0901234567",
     *     "fullName": "Nguyễn Văn A",
     *     "role": "CUSTOMER",
     *     "status": "ACTIVE"
     *   }
     * }
     */
    @GetMapping("/me")
    public ResponseEntity<ApiResponse<User>> getCurrentUser() {
        try {
            User user = authService.getCurrentUser();
            return ResponseEntity.ok(ApiResponse.success(user));
        } catch (Exception e) {
            log.error("Get current user error", e);
            return ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.error("Unauthorized"));
        }
    }
}
