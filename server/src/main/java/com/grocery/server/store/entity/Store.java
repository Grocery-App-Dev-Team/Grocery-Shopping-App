package com.grocery.server.store.entity;

import com.grocery.server.user.entity.User;
import com.grocery.server.product.entity.Product;
import com.grocery.server.order.entity.Order;
import com.grocery.server.review.entity.Review;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Entity: stores
 * Mô tả: Bảng cửa hàng
 * Module: STORE
 */
@Entity
@Table(name = "stores")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Store {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Chủ cửa hàng (User có role = STORE)
     */
    @OneToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User owner;

    /**
     * Tên hiển thị cửa hàng
     * VD: "Tạp hóa cô Ba", "Siêu thị mini Hoàng Anh"
     */
    @Column(name = "store_name", nullable = false, length = 100)
    private String storeName;

    /**
     * Địa chỉ thực tế của cửa hàng
     */
    @Column(nullable = false)
    private String address;

    /**
     * Trạng thái cửa hàng:
     * - true: Đang mở cửa
     * - false: Tạm đóng cửa
     */
    @Column(name = "is_open", nullable = false)
    @Builder.Default
    private Boolean isOpen = true;

    // ========== RELATIONSHIPS ==========

    /**
     * Danh sách sản phẩm của cửa hàng
     */
    @OneToMany(mappedBy = "store", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Product> products;

    /**
     * Danh sách đơn hàng nhận được
     */
    @OneToMany(mappedBy = "store", cascade = CascadeType.ALL)
    private List<Order> orders;

    /**
     * Danh sách đánh giá về cửa hàng
     */
    @OneToMany(mappedBy = "store", cascade = CascadeType.ALL)
    private List<Review> reviews;
}
