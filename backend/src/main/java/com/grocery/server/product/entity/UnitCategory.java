package com.grocery.server.product.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Entity: unit_categories
 * Mô tả: Phân loại các đơn vị (VD: Trọng lượng, Thể tích, Số lượng)
 */
@Entity
@Table(name = "unit_categories")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UnitCategory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 50)
    private String code; // WEIGHT, VOLUME, COUNT

    @Column(nullable = false, length = 100)
    private String name; // Trọng lượng, Thể tích, Số lượng
}
