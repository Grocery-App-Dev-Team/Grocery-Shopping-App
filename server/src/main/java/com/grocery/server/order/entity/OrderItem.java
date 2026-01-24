package com.grocery.server.order.entity;

import com.grocery.server.product.entity.ProductUnit;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Entity: order_items
 * Mô tả: Bảng chi tiết đơn hàng
 * 
 * Giải thích:
 * Mỗi dòng là 1 sản phẩm (với đơn vị cụ thể) trong đơn hàng
 * VD: Đơn hàng #123 có:
 *   - Thịt ba rọi (Gói 300g) x 2 = 70,000đ
 *   - Rau muống (1 Bó) x 3 = 15,000đ
 */
@Entity
@Table(name = "order_items")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OrderItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Thuộc về đơn hàng nào
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id", nullable = false)
    private Order order;

    /**
     * Khách mua ĐƠN VỊ sản phẩm nào
     * VD: Mua "Gói 300g" hay "Khay 1kg"
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_unit_id", nullable = false)
    private ProductUnit productUnit;

    /**
     * Số lượng mua
     * VD: Mua 2 gói, 3 bó, 5 chai...
     */
    @Column(nullable = false)
    private Integer quantity;

    /**
     * Đơn giá tại thời điểm mua (VNĐ)
     * Lưu lại để sau này giá hàng đổi thì giá trong đơn không bị nhảy theo
     */
    @Column(name = "unit_price", nullable = false, precision = 10, scale = 2)
    private BigDecimal unitPrice;

    // ========== HELPER METHOD ==========

    /**
     * Tính tổng tiền của dòng này
     * @return quantity * unitPrice
     */
    public BigDecimal getSubtotal() {
        return unitPrice.multiply(BigDecimal.valueOf(quantity));
    }
}
