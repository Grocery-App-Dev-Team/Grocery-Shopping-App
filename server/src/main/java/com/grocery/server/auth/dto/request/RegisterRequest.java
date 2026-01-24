package com.grocery.server.auth.dto.request;

import com.grocery.server.user.entity.User;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO Request: RegisterRequest
 * Mục đích: Nhận thông tin đăng ký từ client
 * 
 * Ví dụ JSON:
 * {
 *   "phoneNumber": "0901234567",
 *   "password": "123456",
 *   "fullName": "Nguyễn Văn A",
 *   "role": "CUSTOMER",
 *   "address": "123 Đường ABC, Quận 1, TP.HCM"
 * }
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RegisterRequest {
    
    /**
     * Số điện thoại (username)
     */
    @NotBlank(message = "Số điện thoại không được để trống")
    @Pattern(regexp = "^0[0-9]{9}$", message = "Số điện thoại không hợp lệ (phải có 10 chữ số, bắt đầu bằng 0)")
    private String phoneNumber;
    
    /**
     * Mật khẩu
     */
    @NotBlank(message = "Mật khẩu không được để trống")
    @Size(min = 6, message = "Mật khẩu phải có ít nhất 6 ký tự")
    private String password;
    
    /**
     * Họ tên đầy đủ
     */
    @NotBlank(message = "Họ tên không được để trống")
    @Size(max = 100, message = "Họ tên không được quá 100 ký tự")
    private String fullName;
    
    /**
     * Vai trò: CUSTOMER, SHIPPER, STORE, ADMIN
     */
    @NotNull(message = "Vai trò không được để trống")
    private User.UserRole role;
    
    /**
     * Địa chỉ
     */
    @Size(max = 255, message = "Địa chỉ không được quá 255 ký tự")
    private String address;
    
    /**
     * URL ảnh đại diện (optional)
     */
    private String avatarUrl;
}
