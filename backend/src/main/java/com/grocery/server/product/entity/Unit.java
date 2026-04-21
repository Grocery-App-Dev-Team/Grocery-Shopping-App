package com.grocery.server.product.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Entity: units
 * Mô tả: Các đơn vị cụ thể (VD: kg, gram, lít, bó, quả)
 */
@Entity
@Table(name = "units")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Unit {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id", nullable = false)
    private UnitCategory category;

    @Column(nullable = false, unique = true, length = 20)
    private String code; // KG, G, L, ML, PIECE

    @Column(nullable = false, length = 50)
    private String name; // Kilogram, Gram, Lít, Bó, Quả

    @Column(length = 10)
    private String symbol; // kg, g, l, ml

    @Column(name = "step_value", precision = 10, scale = 4)
    @Builder.Default
    private BigDecimal stepValue = BigDecimal.ONE;

    @Column(name = "requires_quantity_input")
    @Builder.Default
    private Boolean requiresQuantityInput = false;
}
