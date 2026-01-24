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
    

    private String token;

    @Builder.Default
    private String type = "Bearer";

    private Long userId;

    private String phoneNumber;

    private String fullName;

    private String role;

    private String avatarUrl;
}
