package com.grocery.server.store.dto.request;

<<<<<<< Updated upstream
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
=======
>>>>>>> Stashed changes
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
<<<<<<< Updated upstream
 * DTO: UpdateStoreRequest
 * Mục đích: Request body để cập nhật thông tin cửa hàng
=======
 * DTO Request: UpdateStoreRequest
 * Mục đích: Nhận dữ liệu cập nhật thông tin cửa hàng
>>>>>>> Stashed changes
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpdateStoreRequest {
<<<<<<< Updated upstream

    @NotBlank(message = "Tên cửa hàng không được để trống")
    @Size(min = 3, max = 100, message = "Tên cửa hàng phải từ 3-100 ký tự")
    private String storeName;

    @NotBlank(message = "Địa chỉ không được để trống")
    @Size(max = 500, message = "Địa chỉ không được vượt quá 500 ký tự")
    private String address;

    @Pattern(regexp = "^0[0-9]{9}$", message = "Số điện thoại phải có 10 số và bắt đầu bằng 0")
    private String phoneNumber;

    @Size(max = 1000, message = "Mô tả không được vượt quá 1000 ký tự")
    private String description;

    private String imageUrl;
=======
    
    /**
     * Tên cửa hàng
     */
    @Size(max = 100, message = "Tên cửa hàng không được quá 100 ký tự")
    private String storeName;
    
    /**
     * Địa chỉ cửa hàng
     */
    @Size(max = 500, message = "Địa chỉ không được quá 500 ký tự")
    private String address;
>>>>>>> Stashed changes
}
