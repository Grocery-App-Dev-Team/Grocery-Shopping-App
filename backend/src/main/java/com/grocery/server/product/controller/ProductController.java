package com.grocery.server.product.controller;

import com.grocery.server.product.dto.request.CreateProductRequest;
import com.grocery.server.product.dto.request.UpdateProductRequest;
import com.grocery.server.product.dto.response.ProductResponse;
import com.grocery.server.product.service.ProductService;
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
 * Controller: ProductController
 * Mục đích: REST API cho Product management
 * 
 * Base URL: /api/products
 */
@RestController
@RequestMapping("/products")
@RequiredArgsConstructor
@Slf4j
public class ProductController {
    
    private final ProductService productService;
    
    // ========== PUBLIC ENDPOINTS ==========
    
    /**
     * GET /api/products
     * Lấy danh sách tất cả products
     * 
     * Public endpoint (không cần authentication)
     */
    @GetMapping
    public ResponseEntity<ApiResponse<List<ProductResponse>>> getAllProducts() {
        log.info("GET /api/products - Get all products");
        
        List<ProductResponse> products = productService.getAllProducts();
        
        return ResponseEntity.ok(
                ApiResponse.success("Lấy danh sách sản phẩm thành công", products)
        );
    }
    
    /**
     * GET /api/products/{id}
     * Lấy thông tin chi tiết product
     * 
     * Public endpoint
     */
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ProductResponse>> getProductById(
            @PathVariable Long id) {
        
        log.info("GET /api/products/{} - Get product detail", id);
        
        ProductResponse product = productService.getProductById(id);
        
        return ResponseEntity.ok(
                ApiResponse.success("Lấy thông tin sản phẩm thành công", product)
        );
    }
    
    /**
     * GET /api/products/store/{storeId}
     * Lấy products theo store
     * 
     * Public endpoint
     */
    @GetMapping("/store/{storeId}")
    public ResponseEntity<ApiResponse<List<ProductResponse>>> getProductsByStore(
            @PathVariable Long storeId) {
        
        log.info("GET /api/products/store/{} - Get products by store", storeId);
        
        List<ProductResponse> products = productService.getProductsByStore(storeId);
        
        return ResponseEntity.ok(
                ApiResponse.success("Lấy danh sách sản phẩm theo cửa hàng thành công", products)
        );
    }
    
    /**
     * GET /api/products/category/{categoryId}
     * Lấy products theo category
     * 
     * Public endpoint
     */
    @GetMapping("/category/{categoryId}")
    public ResponseEntity<ApiResponse<List<ProductResponse>>> getProductsByCategory(
            @PathVariable Long categoryId) {
        
        log.info("GET /api/products/category/{} - Get products by category", categoryId);
        
        List<ProductResponse> products = productService.getProductsByCategory(categoryId);
        
        return ResponseEntity.ok(
                ApiResponse.success("Lấy danh sách sản phẩm theo danh mục thành công", products)
        );
    }
    
    /**
     * GET /api/products/store/{storeId}/available
     * Lấy products đang available theo store
     * 
     * Public endpoint
     */
    @GetMapping("/store/{storeId}/available")
    public ResponseEntity<ApiResponse<List<ProductResponse>>> getAvailableProductsByStore(
            @PathVariable Long storeId) {
        
        log.info("GET /api/products/store/{}/available - Get available products by store", storeId);
        
        List<ProductResponse> products = productService.getAvailableProductsByStore(storeId);
        
        return ResponseEntity.ok(
                ApiResponse.success("Lấy danh sách sản phẩm còn hàng thành công", products)
        );
    }
    
    /**
     * GET /api/products/search
     * Tìm kiếm products theo keyword
     * 
     * Public endpoint
     * Query param: keyword
     */
    @GetMapping("/search")
    public ResponseEntity<ApiResponse<List<ProductResponse>>> searchProducts(
            @RequestParam String keyword) {
        
        log.info("GET /api/products/search?keyword={}", keyword);
        
        List<ProductResponse> products = productService.searchProducts(keyword);
        
        return ResponseEntity.ok(
                ApiResponse.success("Tìm kiếm sản phẩm thành công", products)
        );
    }
    
    // ========== STORE OWNER ENDPOINTS ==========
    
    /**
     * POST /api/products
     * Tạo product mới
     * 
     * Authorization: Bearer token (STORE role)
     */
    @PostMapping
    @PreAuthorize("hasRole('STORE')")
    public ResponseEntity<ApiResponse<ProductResponse>> createProduct(
            @Valid @RequestBody CreateProductRequest request) {
        
        log.info("POST /api/products - Create new product: {}", request.getName());
        
        ProductResponse product = productService.createProduct(request);
        
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("Tạo sản phẩm thành công", product));
    }
    
    /**
     * PUT /api/products/{id}
     * Cập nhật product
     * 
     * Authorization: Bearer token (STORE owner)
     */
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('STORE')")
    public ResponseEntity<ApiResponse<ProductResponse>> updateProduct(
            @PathVariable Long id,
            @Valid @RequestBody UpdateProductRequest request) {
        
        log.info("PUT /api/products/{} - Update product", id);
        
        ProductResponse product = productService.updateProduct(id, request);
        
        return ResponseEntity.ok(
                ApiResponse.success("Cập nhật sản phẩm thành công", product)
        );
    }
    
    /**
     * PATCH /api/products/{id}/toggle-status
     * Toggle product status (AVAILABLE <-> HIDDEN)
     * 
     * Authorization: Bearer token (STORE owner)
     */
    @PatchMapping("/{id}/toggle-status")
    @PreAuthorize("hasRole('STORE')")
    public ResponseEntity<ApiResponse<ProductResponse>> toggleProductStatus(
            @PathVariable Long id) {
        
        log.info("PATCH /api/products/{}/toggle-status", id);
        
        ProductResponse product = productService.toggleProductStatus(id);
        
        return ResponseEntity.ok(
                ApiResponse.success("Cập nhật trạng thái sản phẩm thành công", product)
        );
    }
    
    /**
     * DELETE /api/products/{id}
     * Xóa product
     * 
     * Authorization: Bearer token (STORE owner)
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('STORE')")
    public ResponseEntity<ApiResponse<Void>> deleteProduct(
            @PathVariable Long id) {
        
        log.info("DELETE /api/products/{} - Delete product", id);
        
        productService.deleteProduct(id);
        
        return ResponseEntity.ok(
                ApiResponse.success("Xóa sản phẩm thành công", null)
        );
    }
}
