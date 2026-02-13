package com.grocery.server.product.dto.request;

import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO Request: UpdateCategoryRequest
 * Mục đích: Request body để cập nhật category
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpdateCategoryRequest {
    
    @Size(min = 2, max = 100, message = "Tên danh mục phải từ 2-100 ký tự")
    private String name;
    
    private String iconUrl;
}
