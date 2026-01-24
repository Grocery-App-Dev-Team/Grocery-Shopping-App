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
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
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
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User owner;

    /**
     * Tên cửa hàng
     */
    @Column(name = "store_name", nullable = false, length = 100)
    private String storeName;

    /**
     * Địa chỉ cửa hàng
     */
    @Column(nullable = false, length = 500)
    private String address;

    /**
     * Số điện thoại liên hệ
     */
    @Column(name = "phone_number", length = 15)
    private String phoneNumber;

    /**
     * Mô tả về cửa hàng
     */
    @Column(columnDefinition = "TEXT")
    private String description;

    /**
     * Ảnh cửa hàng
     */
    @Column(name = "image_url")
    private String imageUrl;

    /**
     * Trạng thái mở/đóng cửa
     */
    @Column(name = "is_open", nullable = false)
    @Builder.Default
    private Boolean isOpen = true;

    /**
     * Thời gian tạo
     */
    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    /**
     * Thời gian cập nhật
     */
    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

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
