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

    @OneToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User owner;

    @Column(name = "store_name", nullable = false, length = 100)
    private String storeName;

    @Column(nullable = false)
    private String address;


    @Column(name = "is_open", nullable = false)
    @Builder.Default
    private Boolean isOpen = true;

    // ========== RELATIONSHIPS ==========

    @OneToMany(mappedBy = "store", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Product> products;

    @OneToMany(mappedBy = "store", cascade = CascadeType.ALL)
    private List<Order> orders;

    @OneToMany(mappedBy = "store", cascade = CascadeType.ALL)
    private List<Review> reviews;
}
