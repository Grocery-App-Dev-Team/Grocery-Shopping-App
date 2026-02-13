package com.grocery.server.order.dto.request;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

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
     * ID của ProductUnit (đơn vị sản phẩm cụ thể, ví dụ: Gói 300g, Khay 1kg)
     */
    @NotNull(message = "ID đơn vị sản phẩm không được để trống")
    private Long productUnitId;

    /**
     * Số lượng mua
     */
    @NotNull(message = "Số lượng không được để trống")
    @Positive(message = "Số lượng phải lớn hơn 0")
    private Integer quantity;
}
