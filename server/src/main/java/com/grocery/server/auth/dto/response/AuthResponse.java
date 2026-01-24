package com.grocery.server.auth.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;


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
     * Loại token 
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
