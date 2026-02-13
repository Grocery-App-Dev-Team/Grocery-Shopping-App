package com.grocery.server.product.repository;

import com.grocery.server.product.entity.Category;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * Repository: CategoryRepository
 * Mục đích: Truy vấn database cho bảng categories
 */
@Repository
public interface CategoryRepository extends JpaRepository<Category, Long> {
    
    /**
     * Tìm category theo tên
     */
    Optional<Category> findByName(String name);
    
    /**
     * Kiểm tra category có tồn tại theo tên
     */
    boolean existsByName(String name);
}
