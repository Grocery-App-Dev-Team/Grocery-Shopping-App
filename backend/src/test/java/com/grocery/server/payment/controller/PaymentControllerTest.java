package com.grocery.server.payment.controller;

import com.grocery.server.payment.config.PaymentProperties;
import com.grocery.server.payment.provider.MomoClient;
import com.grocery.server.payment.provider.VnPayClient;
import com.grocery.server.payment.service.PaymentService;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Map;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = PaymentController.class)
public class PaymentControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private PaymentService paymentService;

    @MockBean
    private MomoClient momoClient;

    @MockBean
    private VnPayClient vnpayClient;

    @MockBean
    private PaymentProperties paymentProperties;

    @Test
    void momoCallback_validSignature_returns200() throws Exception {
        Mockito.when(momoClient.verifyCallback(Mockito.anyMap())).thenReturn(true);

        mockMvc.perform(post("/api/payments/momo/callback")
                .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                .content("partnerCode=P1&accessKey=A1&requestId=R1&amount=10000&orderId=O1&orderInfo=info&extraData=123&signature=abc"))
                .andExpect(status().isOk());
    }

    @Test
    void momoCallback_invalidSignature_returns400() throws Exception {
        Mockito.when(momoClient.verifyCallback(Mockito.anyMap())).thenReturn(false);

        mockMvc.perform(post("/api/payments/momo/callback")
                        .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                        .content("partnerCode=P1&accessKey=A1&requestId=R1&amount=10000&orderId=O1&orderInfo=info&extraData=123&signature=abc"))
                .andExpect(status().isBadRequest());
    }
}
