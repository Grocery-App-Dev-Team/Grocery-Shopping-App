package com.grocery.server.product.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Entity: categories
 * Mô tả: Bảng danh mục sản phẩm
 * Module: PRODUCT
 */
@Entity
@Table(name = "categories")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Category {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Tên danh mục
     * VD: "Thực phẩm", "Thịt cá", "Rau củ", "Trái cây"
     */
    @Column(nullable = false, length = 100)
    private String name;

    /**
     * Đường dẫn hình ảnh biểu tượng của danh mục
     */
    @Column(name = "icon_url")
    private String iconUrl;

    // ========== RELATIONSHIPS ==========

    /**
     * Danh sách sản phẩm thuộc danh mục này
     */
    @OneToMany(mappedBy = "category", cascade = CascadeType.ALL)
    private List<Product> products;
}
