package com.grocery.server.product.dto.response;

import com.grocery.server.product.entity.Category;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO Response: CategoryResponse
 * Mục đích: Response chứa thông tin category
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CategoryResponse {
    
    private Long id;
    private String name;
    private String iconUrl;
    
    /**
     * Chuyển từ Category entity sang CategoryResponse DTO
     */
    public static CategoryResponse fromEntity(Category category) {
        return CategoryResponse.builder()
                .id(category.getId())
                .name(category.getName())
                .iconUrl(category.getIconUrl())
                .build();
    }
}
