package com.grocery.server.order.entity;

import org.springframework.data.jpa.domain.Specification;
import java.time.LocalDateTime;

/**
 * Utility: OrderSpecification
 * Mục đích: Xây dựng các điều kiện lọc động cho Order
 */
public class OrderSpecification {

    public static Specification<Order> hasStoreId(Long storeId) {
        return (root, query, cb) -> storeId == null ? cb.conjunction() : cb.equal(root.get("store").get("id"), storeId);
    }

    public static Specification<Order> hasCustomerId(Long customerId) {
        return (root, query, cb) -> customerId == null ? cb.conjunction() : cb.equal(root.get("customer").get("id"), customerId);
    }

    public static Specification<Order> hasShipperId(Long shipperId) {
        return (root, query, cb) -> shipperId == null ? cb.conjunction() : cb.equal(root.get("shipper").get("id"), shipperId);
    }

    public static Specification<Order> hasStatus(Order.OrderStatus status) {
        return (root, query, cb) -> status == null ? cb.conjunction() : cb.equal(root.get("status"), status);
    }

    public static Specification<Order> createdAfter(LocalDateTime from) {
        return (root, query, cb) -> from == null ? cb.conjunction() : cb.greaterThanOrEqualTo(root.get("createdAt"), from);
    }

    public static Specification<Order> createdBefore(LocalDateTime to) {
        return (root, query, cb) -> to == null ? cb.conjunction() : cb.lessThanOrEqualTo(root.get("createdAt"), to);
    }
}
