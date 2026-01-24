package com.grocery.server.product.repository;

import com.grocery.server.product.entity.Product;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Repository: ProductRepository
 * Mục đích: Truy vấn database cho bảng products
 * 
 * Spring Data JPA tự động implement tất cả methods!
 * Không cần viết code implementation.
 */
@Repository
public interface ProductRepository extends JpaRepository<Product, Long> {
    
    // ========== DERIVED QUERIES (Spring tự tạo SQL) ==========
    
    /**
     * Tìm sản phẩm theo store_id
     * SQL: SELECT * FROM products WHERE store_id = ?
     */
    List<Product> findByStoreId(Long storeId);
    
    /**
     * Tìm sản phẩm theo store_id và category_id
     * SQL: SELECT * FROM products WHERE store_id = ? AND category_id = ?
     */
    List<Product> findByStoreIdAndCategoryId(Long storeId, Long categoryId);
    
    /**
     * Tìm sản phẩm theo store_id và status
     * SQL: SELECT * FROM products WHERE store_id = ? AND status = ?
     */
    List<Product> findByStoreIdAndStatus(Long storeId, Product.ProductStatus status);
    
    /**
     * Tìm sản phẩm theo tên (LIKE %name%)
     * SQL: SELECT * FROM products WHERE name LIKE %?%
     */
    List<Product> findByNameContaining(String name);
    
    /**
     * Đếm số sản phẩm của 1 cửa hàng
     * SQL: SELECT COUNT(*) FROM products WHERE store_id = ?
     */
    long countByStoreId(Long storeId);
    
    /**
     * Kiểm tra sản phẩm có tồn tại không
     * SQL: SELECT EXISTS(SELECT 1 FROM products WHERE store_id = ? AND name = ?)
     */
    boolean existsByStoreIdAndName(Long storeId, String name);
    
    // ========== CUSTOM QUERIES (Tự viết SQL) ==========
    
    /**
     * Tìm sản phẩm còn hàng của 1 cửa hàng
     * Sắp xếp theo tên
     */
    @Query("SELECT p FROM Product p " +
           "WHERE p.store.id = :storeId " +
           "AND p.status = 'AVAILABLE' " +
           "ORDER BY p.name ASC")
    List<Product> findAvailableProductsByStore(@Param("storeId") Long storeId);
    
    /**
     * Tìm kiếm sản phẩm theo từ khóa (Full-text search)
     */
    @Query("SELECT p FROM Product p " +
           "WHERE LOWER(p.name) LIKE LOWER(CONCAT('%', :keyword, '%')) " +
           "AND p.status = 'AVAILABLE'")
    List<Product> searchByKeyword(@Param("keyword") String keyword);
    
    /**
     * Lấy top sản phẩm bán chạy (dựa vào số lượng order_items)
     */
    @Query(value = 
        "SELECT p.* FROM products p " +
        "JOIN product_units pu ON pu.product_id = p.id " +
        "JOIN order_items oi ON oi.product_unit_id = pu.id " +
        "WHERE p.store_id = :storeId " +
        "GROUP BY p.id " +
        "ORDER BY SUM(oi.quantity) DESC " +
        "LIMIT :limit", 
        nativeQuery = true)
    List<Product> findTopSellingProducts(@Param("storeId") Long storeId, 
                                         @Param("limit") int limit);
}
