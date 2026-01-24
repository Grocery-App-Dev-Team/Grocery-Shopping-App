package com.grocery.server.auth.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO Response: AuthResponse
 * Mục đích: Trả về thông tin đăng nhập/đăng ký thành công
 * 
 * Ví dụ JSON:
 * {
 *   "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
 *   "type": "Bearer",
 *   "userId": 1,
 *   "phoneNumber": "0901234567",
 *   "fullName": "Nguyễn Văn A",
 *   "role": "CUSTOMER"
 * }
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AuthResponse {
    
    /**
     * JWT Access Token
     */
    private String token;
    
    /**
     * Loại token (luôn là "Bearer")
     */
    @Builder.Default
    private String type = "Bearer";
    
    /**
     * ID của user
     */
    private Long userId;
    
    /**
     * Số điện thoại
     */
    private String phoneNumber;
    
    /**
     * Họ tên
     */
    private String fullName;
    
    /**
     * Vai trò
     */
    private String role;
    
    /**
     * Avatar URL
     */
    private String avatarUrl;
}
