package com.grocery.server.user.entity;

import com.grocery.server.store.entity.Store;
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
 * Entity: users
 * Mô tả: Bảng quản lý người dùng (Khách hàng, Shipper, Cửa hàng, Admin)
 * Module: USER
 */
@Entity
@Table(name = "users")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Số điện thoại - Dùng làm tài khoản đăng nhập
     * Unique: Không được trùng
     */
    @Column(name = "phone_number", unique = true, nullable = false, length = 15)
    private String phoneNumber;

    /**
     * Mật khẩu đã mã hóa (BCrypt)
     */
    @Column(name = "password_hash", nullable = false)
    private String passwordHash;

    /**
     * Vai trò tài khoản:
     * - CUSTOMER: Khách hàng
     * - SHIPPER: Tài xế giao hàng
     * - STORE: Chủ cửa hàng
     * - ADMIN: Quản trị viên
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private UserRole role;

    /**
     * Trạng thái tài khoản:
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private UserStatus status = UserStatus.ACTIVE;

    /**
     * Họ và tên người dùng
     */
    @Column(name = "full_name", length = 100)
    private String fullName;

    /**
     * Đường dẫn ảnh đại diện
     */
    @Column(name = "avatar_url")
    private String avatarUrl;

    /**
     * Địa chỉ cá nhân
     */
    @Column(length = 255)
    private String address;

    /**
     * Thời gian tạo tài khoản
     */
    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    /**
     * Thời gian cập nhật thông tin gần nhất
     */
    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // ========== RELATIONSHIPS ==========

    /**
     * Nếu user có role = STORE → có 1 cửa hàng
     */
    @OneToOne(mappedBy = "owner", cascade = CascadeType.ALL, orphanRemoval = true)
    private Store store;

    /**
     * Nếu user có role = CUSTOMER → có nhiều đơn hàng
     */
    @OneToMany(mappedBy = "customer", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Order> customerOrders;

    /**
     * Nếu user có role = SHIPPER → nhận nhiều đơn giao hàng
     */
    @OneToMany(mappedBy = "shipper", cascade = CascadeType.ALL)
    private List<Order> shipperOrders;

    /**
     * Đánh giá đã viết
     */
    @OneToMany(mappedBy = "reviewer", cascade = CascadeType.ALL)
    private List<Review> reviews;

    // ========== ENUMS ==========

    public enum UserRole {
        CUSTOMER,  // Khách hàng
        SHIPPER,   // Tài xế
        STORE,     // Cửa hàng
        ADMIN      // Quản trị viên
    }

    public enum UserStatus {
        ACTIVE,    // Đang hoạt động
        BANNED     // Bị khóa
    }
}
