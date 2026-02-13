package com.grocery.server.product.dto.request;

import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO Request: UpdateProductRequest
 * Mục đích: Request body để cập nhật product
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpdateProductRequest {
    
    private Long categoryId;
    
    @Size(min = 2, max = 255, message = "Tên sản phẩm phải từ 2-255 ký tự")
    private String name;
    
    @Size(max = 1000, message = "Mô tả không được vượt quá 1000 ký tự")
    private String description;
    
    private String imageUrl;
}
