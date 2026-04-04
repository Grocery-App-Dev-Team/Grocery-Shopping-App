package com.grocery.server.payment.service;

import com.grocery.server.order.entity.Order;
import com.grocery.server.order.repository.OrderRepository;
import com.grocery.server.payment.entity.Payment;
import com.grocery.server.payment.repository.PaymentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Optional;
import com.grocery.server.payment.provider.MomoClient;
import com.grocery.server.payment.provider.VnPayClient;
import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
@Slf4j
public class PaymentService {

    private final PaymentRepository paymentRepository;
    private final OrderRepository orderRepository;
    private final MomoClient momoClient;
    private final VnPayClient vnpayClient;

    /**
     * Tạo bản ghi payment và trả về URL redirect tới cổng thanh toán (stub)
     */
    @Transactional
    public Payment initiatePayment(Long orderId, Payment.PaymentMethod method) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new IllegalArgumentException("Order not found"));

        BigDecimal amount = order.getTotalAmount().add(order.getShippingFee());

        Payment payment = Payment.builder()
                .order(order)
                .paymentMethod(method)
                .amount(amount)
                .status(Payment.PaymentStatus.PENDING)
                .build();

        Payment saved = paymentRepository.save(payment);
        log.info("Created payment #{} for order {} with method {}", saved.getId(), orderId, method);
        return saved;
    }

    public Optional<Payment> findById(Long id) {
        return paymentRepository.findById(id);
    }

    /**
     * Xử lý callback từ cổng thanh toán
     */
    @Transactional
    public void handlePaymentResult(Long paymentId, boolean success, String transactionCode) {
        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() -> new IllegalArgumentException("Payment not found"));

        if (success) {
            payment.setStatus(Payment.PaymentStatus.SUCCESS);
            payment.setTransactionCode(transactionCode);
            // Cập nhật trạng thái payment
            paymentRepository.save(payment);

            // Update order paymentStatus -> SUCCESS and order status -> CONFIRMED
            Order order = payment.getOrder();
            order.setPaymentStatus(Payment.PaymentStatus.SUCCESS);
            order.setStatus(Order.OrderStatus.CONFIRMED);
            orderRepository.save(order);
            log.info("Payment #{} SUCCESS, order #{} set to CONFIRMED", paymentId, order.getId());
        } else {
            payment.setStatus(Payment.PaymentStatus.FAILED);
            payment.setTransactionCode(transactionCode);
            paymentRepository.save(payment);

            Order order = payment.getOrder();
            order.setPaymentStatus(Payment.PaymentStatus.FAILED);
            orderRepository.save(order);
            log.info("Payment #{} FAILED for order #{}", paymentId, order.getId());
        }
    }
}
