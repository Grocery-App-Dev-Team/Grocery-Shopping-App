package com.grocery.server.product.service;

import com.grocery.server.product.dto.request.CreateCategoryRequest;
import com.grocery.server.product.dto.request.UpdateCategoryRequest;
import com.grocery.server.product.dto.response.CategoryResponse;
import com.grocery.server.product.entity.Category;
import com.grocery.server.product.repository.CategoryRepository;
import com.grocery.server.shared.exception.BadRequestException;
import com.grocery.server.shared.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Service: CategoryService
 * Mục đích: Xử lý business logic cho Category management
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CategoryService {
    
    private final CategoryRepository categoryRepository;
    
    /**
     * Lấy tất cả categories (Public)
     */
    public List<CategoryResponse> getAllCategories() {
        List<Category> categories = categoryRepository.findAll();
        log.info("Get all categories, total: {}", categories.size());
        
        return categories.stream()
                .map(CategoryResponse::fromEntity)
                .collect(Collectors.toList());
    }
    
    /**
     * Lấy category theo ID (Public)
     */
    public CategoryResponse getCategoryById(Long categoryId) {
        Category category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new ResourceNotFoundException("Category", "id", categoryId));
        
        log.info("Get category by ID: {}", categoryId);
        return CategoryResponse.fromEntity(category);
    }
    
    /**
     * Tạo category mới (Admin only)
     */
    @Transactional
    public CategoryResponse createCategory(CreateCategoryRequest request) {
        // Kiểm tra tên category đã tồn tại chưa
        if (categoryRepository.existsByName(request.getName())) {
            throw new BadRequestException("Danh mục '" + request.getName() + "' đã tồn tại");
        }
        
        Category category = Category.builder()
                .name(request.getName())
                .iconUrl(request.getIconUrl())
                .build();
        
        Category savedCategory = categoryRepository.save(category);
        log.info("Created new category: {}", savedCategory.getName());
        
        return CategoryResponse.fromEntity(savedCategory);
    }
    
    /**
     * Cập nhật category (Admin only)
     */
    @Transactional
    public CategoryResponse updateCategory(Long categoryId, UpdateCategoryRequest request) {
        Category category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new ResourceNotFoundException("Category", "id", categoryId));
        
        // Kiểm tra tên mới có trùng với category khác không
        if (request.getName() != null && !request.getName().equals(category.getName())) {
            if (categoryRepository.existsByName(request.getName())) {
                throw new BadRequestException("Danh mục '" + request.getName() + "' đã tồn tại");
            }
            category.setName(request.getName());
        }
        
        if (request.getIconUrl() != null) {
            category.setIconUrl(request.getIconUrl());
        }
        
        Category updatedCategory = categoryRepository.save(category);
        log.info("Updated category: {}", categoryId);
        
        return CategoryResponse.fromEntity(updatedCategory);
    }
    
    /**
     * Xóa category (Admin only)
     */
    @Transactional
    public void deleteCategory(Long categoryId) {
        Category category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new ResourceNotFoundException("Category", "id", categoryId));
        
        // Kiểm tra xem category có products hay không
        if (category.getProducts() != null && !category.getProducts().isEmpty()) {
            throw new BadRequestException(
                    "Không thể xóa danh mục này vì còn " + category.getProducts().size() + " sản phẩm");
        }
        
        categoryRepository.delete(category);
        log.info("Deleted category: {}", categoryId);
    }
}
