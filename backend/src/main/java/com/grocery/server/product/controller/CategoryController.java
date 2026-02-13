package com.grocery.server.product.controller;

import com.grocery.server.product.dto.request.CreateCategoryRequest;
import com.grocery.server.product.dto.request.UpdateCategoryRequest;
import com.grocery.server.product.dto.response.CategoryResponse;
import com.grocery.server.product.service.CategoryService;
import com.grocery.server.shared.dto.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Controller: CategoryController
 * Mục đích: REST API cho Category management
 * 
 * Base URL: /api/categories
 */
@RestController
@RequestMapping("/categories")
@RequiredArgsConstructor
@Slf4j
public class CategoryController {
    
    private final CategoryService categoryService;
    
    // ========== PUBLIC ENDPOINTS ==========
    
    /**
     * GET /api/categories
     * Lấy danh sách tất cả categories
     * 
     * Public endpoint (không cần authentication)
     */
    @GetMapping
    public ResponseEntity<ApiResponse<List<CategoryResponse>>> getAllCategories() {
        log.info("GET /api/categories - Get all categories");
        
        List<CategoryResponse> categories = categoryService.getAllCategories();
        
        return ResponseEntity.ok(
                ApiResponse.success("Lấy danh sách danh mục thành công", categories)
        );
    }
    
    /**
     * GET /api/categories/{id}
     * Lấy thông tin chi tiết category
     * 
     * Public endpoint
     */
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<CategoryResponse>> getCategoryById(
            @PathVariable Long id) {
        
        log.info("GET /api/categories/{} - Get category detail", id);
        
        CategoryResponse category = categoryService.getCategoryById(id);
        
        return ResponseEntity.ok(
                ApiResponse.success("Lấy thông tin danh mục thành công", category)
        );
    }
    
    // ========== ADMIN ENDPOINTS ==========
    
    /**
     * POST /api/categories
     * Tạo category mới
     * 
     * Authorization: Bearer token (ADMIN role)
     */
    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<CategoryResponse>> createCategory(
            @Valid @RequestBody CreateCategoryRequest request) {
        
        log.info("POST /api/categories - Create new category: {}", request.getName());
        
        CategoryResponse category = categoryService.createCategory(request);
        
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("Tạo danh mục thành công", category));
    }
    
    /**
     * PUT /api/categories/{id}
     * Cập nhật category
     * 
     * Authorization: Bearer token (ADMIN role)
     */
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<CategoryResponse>> updateCategory(
            @PathVariable Long id,
            @Valid @RequestBody UpdateCategoryRequest request) {
        
        log.info("PUT /api/categories/{} - Update category", id);
        
        CategoryResponse category = categoryService.updateCategory(id, request);
        
        return ResponseEntity.ok(
                ApiResponse.success("Cập nhật danh mục thành công", category)
        );
    }
    
    /**
     * DELETE /api/categories/{id}
     * Xóa category
     * 
     * Authorization: Bearer token (ADMIN role)
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteCategory(
            @PathVariable Long id) {
        
        log.info("DELETE /api/categories/{} - Delete category", id);
        
        categoryService.deleteCategory(id);
        
        return ResponseEntity.ok(
                ApiResponse.success("Xóa danh mục thành công", null)
        );
    }
}
