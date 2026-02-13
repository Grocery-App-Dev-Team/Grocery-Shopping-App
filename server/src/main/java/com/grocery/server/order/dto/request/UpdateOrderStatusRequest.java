package com.grocery.server.order.dto.request;

import com.grocery.server.order.entity.Order.OrderStatus;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO: UpdateOrderStatusRequest
 * Mô tả: Yêu cầu cập nhật trạng thái đơn hàng
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpdateOrderStatusRequest {

    /**
     * Trạng thái mới của đơn hàng
     */
    @NotNull(message = "Trạng thái đơn hàng không được để trống")
    private OrderStatus newStatus;

    /**
     * Lý do hủy đơn (bắt buộc khi newStatus = CANCELLED)
     */
    private String cancelReason;

    /**
     * URL ảnh chứng minh giao hàng (bắt buộc khi newStatus = DELIVERED)
     */
    private String podImageUrl;
}
