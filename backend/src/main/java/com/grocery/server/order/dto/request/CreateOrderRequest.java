package com.grocery.server.order.dto.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * DTO: CreateOrderRequest
 * Mô tả: Yêu cầu tạo đơn hàng mới từ khách hàng
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateOrderRequest {

    /**
     * ID cửa hàng (khách hàng đặt từ cửa hàng nào)
     */
    @NotNull(message = "ID cửa hàng không được để trống")
    private Long storeId;

    /**
     * Địa chỉ giao hàng cụ thể
     */
    @NotBlank(message = "Địa chỉ giao hàng không được để trống")
    private String deliveryAddress;

    /**
     * Danh sách sản phẩm trong đơn hàng
     */
    @NotEmpty(message = "Đơn hàng phải có ít nhất một sản phẩm")
    @Valid
    private List<CreateOrderItemRequest> items;
}
