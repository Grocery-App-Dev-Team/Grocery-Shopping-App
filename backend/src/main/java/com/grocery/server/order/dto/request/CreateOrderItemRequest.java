package com.grocery.server.order.dto.request;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * DTO: CreateOrderItemRequest
 * Mô tả: Chi tiết một sản phẩm trong đơn hàng
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateOrderItemRequest {

    /**
     * ID của ProductUnitMapping (biến thể sản phẩm cụ thể)
     */
    @NotNull(message = "ID biến thể sản phẩm không được để trống")
    private Long productUnitMappingId;

    /**
     * Số lượng mua
     */
    @NotNull(message = "Số lượng không được để trống")
    @Positive(message = "Số lượng phải lớn hơn 0")
    private BigDecimal quantity;
}
