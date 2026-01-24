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

<<<<<<< Updated upstream
=======
/**
 * DTO Request: RegisterRequest
 * Mục đích: Nhận thông tin đăng ký từ client
 * 
 * Form đăng ký có 3 loại:
 * 1. CUSTOMER/SHIPPER: Chỉ cần thông tin user cơ bản
 * 2. STORE: Cần thông tin user + thông tin cửa hàng (storeName, storeAddress, storePhoneNumber)
 * 
 * Ví dụ JSON - Đăng ký CUSTOMER:
 * {
 *   "phoneNumber": "0901234567",
 *   "password": "123456",
 *   "fullName": "Nguyễn Văn A",
 *   "role": "CUSTOMER",
 *   "address": "123 Đường ABC, Quận 1, TP.HCM"
 * }
 * 
 * Ví dụ JSON - Đăng ký STORE:
 * {
 *   "phoneNumber": "0902222222",
 *   "password": "123456",
 *   "fullName": "Nguyễn Văn B",
 *   "role": "STORE",
 *   "address": "456 Đường XYZ, Quận 2",
 *   "storeName": "Tạp hóa cô Ba",
 *   "storeAddress": "456 Đường XYZ, Quận 2, TP.HCM",
 *   "storePhoneNumber": "0987654321",
 *   "storeDescription": "Bán đồ tạp hóa tươi sống"
 * }
 */
>>>>>>> Stashed changes
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RegisterRequest {
    

    @NotBlank(message = "Số điện thoại không được để trống")
    @Pattern(regexp = "^0[0-9]{9}$", message = "Số điện thoại không hợp lệ (phải có 10 chữ số, bắt đầu bằng 0)")
    private String phoneNumber;
    

    @NotBlank(message = "Mật khẩu không được để trống")
    @Size(min = 6, message = "Mật khẩu phải có ít nhất 6 ký tự")
    private String password;

    @NotBlank(message = "Họ tên không được để trống")
    @Size(max = 100, message = "Họ tên không được quá 100 ký tự")
    private String fullName;
    

    @NotNull(message = "Vai trò không được để trống")
    private User.UserRole role;
    
<<<<<<< Updated upstream

=======
    /**
     * Địa chỉ cá nhân
     */
>>>>>>> Stashed changes
    @Size(max = 255, message = "Địa chỉ không được quá 255 ký tự")
    private String address;

    private String avatarUrl;
    
    // ========== THÔNG TIN CỬA HÀNG (Chỉ dành cho role = STORE) ==========
    
    /**
     * Tên cửa hàng (bắt buộc nếu role = STORE)
     */
    @Size(max = 100, message = "Tên cửa hàng không được quá 100 ký tự")
    private String storeName;
    
    /**
     * Địa chỉ cửa hàng (bắt buộc nếu role = STORE)
     */
    @Size(max = 500, message = "Địa chỉ cửa hàng không được quá 500 ký tự")
    private String storeAddress;
    
    /**
     * Số điện thoại cửa hàng (bắt buộc nếu role = STORE)
     */
    @Pattern(regexp = "^$|^0[0-9]{9}$", message = "Số điện thoại cửa hàng không hợp lệ")
    private String storePhoneNumber;
    
    /**
     * Mô tả cửa hàng (optional)
     */
    private String storeDescription;
    
    /**
     * URL ảnh cửa hàng (optional)
     */
    private String storeImageUrl;
}
