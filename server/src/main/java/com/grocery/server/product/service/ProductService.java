package com.grocery.server.product.service;

import com.grocery.server.product.dto.request.CreateProductRequest;
import com.grocery.server.product.dto.request.UpdateProductRequest;
import com.grocery.server.product.dto.response.ProductResponse;
import com.grocery.server.product.entity.Category;
import com.grocery.server.product.entity.Product;
import com.grocery.server.product.entity.ProductUnit;
import com.grocery.server.product.repository.CategoryRepository;
import com.grocery.server.product.repository.ProductRepository;
import com.grocery.server.shared.exception.BadRequestException;
import com.grocery.server.shared.exception.ResourceNotFoundException;
import com.grocery.server.shared.exception.UnauthorizedException;
import com.grocery.server.store.entity.Store;
import com.grocery.server.store.repository.StoreRepository;
import com.grocery.server.user.entity.User;
import com.grocery.server.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Service: ProductService
 * Mục đích: Xử lý business logic cho Product management
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ProductService {
    
    private final ProductRepository productRepository;
    private final CategoryRepository categoryRepository;
    private final StoreRepository storeRepository;
    private final UserRepository userRepository;
    
    /**
     * Lấy tất cả products (Public)
     */
    public List<ProductResponse> getAllProducts() {
        List<Product> products = productRepository.findAll();
        log.info("Get all products, total: {}", products.size());
        
        return products.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }
    
    /**
     * Lấy products theo store ID (Public)
     */
    public List<ProductResponse> getProductsByStore(Long storeId) {
        List<Product> products = productRepository.findByStoreId(storeId);
        log.info("Get products by store: {}, total: {}", storeId, products.size());
        
        return products.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }
    
    /**
     * Lấy products theo category ID (Public)
     */
    public List<ProductResponse> getProductsByCategory(Long categoryId) {
        // Kiểm tra category có tồn tại không
        categoryRepository.findById(categoryId)
                .orElseThrow(() -> new ResourceNotFoundException("Category", "id", categoryId));
        
        List<Product> products = productRepository.findByCategoryId(categoryId);
        log.info("Get products by category: {}, total: {}", categoryId, products.size());
        
        return products.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }
    
    /**
     * Lấy products đang available theo store (Public)
     */
    public List<ProductResponse> getAvailableProductsByStore(Long storeId) {
        List<Product> products = productRepository.findAvailableProductsByStore(storeId);
        log.info("Get available products by store: {}, total: {}", storeId, products.size());
        
        return products.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }
    
    /**
     * Tìm kiếm products theo keyword (Public)
     */
    public List<ProductResponse> searchProducts(String keyword) {
        List<Product> products = productRepository.searchByKeyword(keyword);
        log.info("Search products with keyword: '{}', found: {}", keyword, products.size());
        
        return products.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }
    
    /**
     * Lấy product theo ID (Public)
     */
    public ProductResponse getProductById(Long productId) {
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new ResourceNotFoundException("Product", "id", productId));
        
        log.info("Get product by ID: {}", productId);
        return convertToResponse(product);
    }
    
    /**
     * Tạo product mới (Store owner only)
     */
    @Transactional
    public ProductResponse createProduct(CreateProductRequest request) {
        User currentUser = getCurrentUser();
        
        // Lấy store của user hiện tại
        Store store = storeRepository.findByOwnerId(currentUser.getId())
                .orElseThrow(() -> new BadRequestException("Bạn chưa có cửa hàng"));
        
        // Kiểm tra category nếu có
        Category category = null;
        if (request.getCategoryId() != null) {
            category = categoryRepository.findById(request.getCategoryId())
                    .orElseThrow(() -> new ResourceNotFoundException("Category", "id", request.getCategoryId()));
        }
        
        // Tạo product
        Product product = Product.builder()
                .store(store)
                .category(category)
                .name(request.getName())
                .description(request.getDescription())
                .imageUrl(request.getImageUrl())
                .status(Product.ProductStatus.AVAILABLE)
                .build();
        
        // Tạo product units
        List<ProductUnit> units = request.getUnits().stream()
                .map(unitReq -> ProductUnit.builder()
                        .product(product)
                        .unitName(unitReq.getUnitName())
                        .price(BigDecimal.valueOf(unitReq.getPrice()))
                        .stockQuantity(unitReq.getStockQuantity() != null ? unitReq.getStockQuantity() : 0)
                        .build())
                .collect(Collectors.toList());
        
        product.setUnits(units);
        
        Product savedProduct = productRepository.save(product);
        log.info("Created new product: {} for store: {}", savedProduct.getName(), store.getStoreName());
        
        return convertToResponse(savedProduct);
    }
    
    /**
     * Cập nhật product (Store owner only)
     */
    @Transactional
    public ProductResponse updateProduct(Long productId, UpdateProductRequest request) {
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new ResourceNotFoundException("Product", "id", productId));
        
        User currentUser = getCurrentUser();
        
        // Kiểm tra quyền: chỉ owner mới được cập nhật
        if (!product.getStore().getOwner().getId().equals(currentUser.getId())) {
            throw new UnauthorizedException("Bạn không có quyền cập nhật sản phẩm này");
        }
        
        // Cập nhật thông tin
        if (request.getName() != null && !request.getName().trim().isEmpty()) {
            product.setName(request.getName());
        }
        
        if (request.getDescription() != null) {
            product.setDescription(request.getDescription());
        }
        
        if (request.getImageUrl() != null) {
            product.setImageUrl(request.getImageUrl());
        }
        
        if (request.getCategoryId() != null) {
            Category category = categoryRepository.findById(request.getCategoryId())
                    .orElseThrow(() -> new ResourceNotFoundException("Category", "id", request.getCategoryId()));
            product.setCategory(category);
        }
        
        Product updatedProduct = productRepository.save(product);
        log.info("Updated product: {}", productId);
        
        return convertToResponse(updatedProduct);
    }
    
    /**
     * Toggle product status (Store owner only)
     */
    @Transactional
    public ProductResponse toggleProductStatus(Long productId) {
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new ResourceNotFoundException("Product", "id", productId));
        
        User currentUser = getCurrentUser();
        
        // Kiểm tra quyền
        if (!product.getStore().getOwner().getId().equals(currentUser.getId())) {
            throw new UnauthorizedException("Bạn không có quyền thay đổi trạng thái sản phẩm này");
        }
        
        // Toggle status
        if (product.getStatus() == Product.ProductStatus.AVAILABLE) {
            product.setStatus(Product.ProductStatus.HIDDEN);
        } else {
            product.setStatus(Product.ProductStatus.AVAILABLE);
        }
        
        Product updatedProduct = productRepository.save(product);
        log.info("Toggled product status: {} to {}", productId, updatedProduct.getStatus());
        
        return convertToResponse(updatedProduct);
    }
    
    /**
     * Xóa product (Store owner only)
     */
    @Transactional
    public void deleteProduct(Long productId) {
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new ResourceNotFoundException("Product", "id", productId));
        
        User currentUser = getCurrentUser();
        
        // Kiểm tra quyền
        if (!product.getStore().getOwner().getId().equals(currentUser.getId())) {
            throw new UnauthorizedException("Bạn không có quyền xóa sản phẩm này");
        }
        
        productRepository.delete(product);
        log.info("Deleted product: {}", productId);
    }
    
    /**
     * Helper: Convert Product entity to ProductResponse DTO
     */
    private ProductResponse convertToResponse(Product product) {
        List<ProductResponse.ProductUnitResponse> unitResponses = product.getUnits().stream()
                .map(unit -> ProductResponse.ProductUnitResponse.builder()
                        .id(unit.getId())
                        .unitName(unit.getUnitName())
                        .price(unit.getPrice())
                        .stockQuantity(unit.getStockQuantity())
                        .build())
                .collect(Collectors.toList());
        
        return ProductResponse.builder()
                .id(product.getId())
                .name(product.getName())
                .description(product.getDescription())
                .imageUrl(product.getImageUrl())
                .storeName(product.getStore().getStoreName())
                .categoryName(product.getCategory() != null ? product.getCategory().getName() : null)
                .status(product.getStatus().name())
                .units(unitResponses)
                .build();
    }
    
    /**
     * Helper: Lấy current user từ SecurityContext
     */
    private User getCurrentUser() {
        String phoneNumber = SecurityContextHolder.getContext().getAuthentication().getName();
        return userRepository.findByPhoneNumber(phoneNumber)
                .orElseThrow(() -> new ResourceNotFoundException("User", "phoneNumber", phoneNumber));
    }
}
