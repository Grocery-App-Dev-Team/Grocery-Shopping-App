package com.grocery.server.order.repository;

import com.grocery.server.order.entity.OrderItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

/**
 * Repository: OrderItemRepository
 * Mô tả: Quản lý truy vấn database cho OrderItem
 */
@Repository
public interface OrderItemRepository extends JpaRepository<OrderItem, Long> {
    // Các query cơ bản đã có sẵn từ JpaRepository
    // Nếu cần query phức tạp hơn sẽ thêm sau
}
