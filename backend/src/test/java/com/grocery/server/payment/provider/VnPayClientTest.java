package com.grocery.server.payment.provider;

import com.grocery.server.payment.config.PaymentProperties;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

public class VnPayClientTest {

    private static String hmacSHA512(String key, String data) throws Exception {
        Mac sha512_HMAC = Mac.getInstance("HmacSHA512");
        SecretKeySpec secret_key = new SecretKeySpec(key.getBytes(StandardCharsets.UTF_8), "HmacSHA512");
        sha512_HMAC.init(secret_key);
        byte[] hash = sha512_HMAC.doFinal(data.getBytes(StandardCharsets.UTF_8));
        StringBuilder sb = new StringBuilder(2 * hash.length);
        for (byte b : hash) sb.append(String.format("%02x", b & 0xff));
        return sb.toString();
    }

    @Test
    void verifyCallback_validSignature_returnsTrue() throws Exception {
        PaymentProperties props = new PaymentProperties();
        PaymentProperties.VnPay vnp = new PaymentProperties.VnPay();
        vnp.setSecretKey("test-secret");
        vnp.setUrl("https://sandbox.vnpayment.vn/paymentv2/vpcpay.html");
        props.setVnpay(vnp);

        VnPayClient client = new VnPayClient(props);

        Map<String, String> params = new HashMap<>();
        params.put("vnp_Version", "2.1.0");
        params.put("vnp_Command", "pay");
        params.put("vnp_TmnCode", "TMN1");
        params.put("vnp_TxnRef", "P123");
        params.put("vnp_OrderInfo", "info");
        params.put("vnp_Amount", "10000");
        params.put("vnp_ReturnUrl", "http://localhost:8080/api/payments/vnpay/callback");

        // Build hash data - sorted by key
        java.util.List<String> keys = new java.util.ArrayList<>(params.keySet());
        java.util.Collections.sort(keys);
        StringBuilder hashData = new StringBuilder();
        for (String k : keys) {
            if (hashData.length() > 0) hashData.append('&');
            hashData.append(k).append('=').append(params.get(k));
        }

        String signature = hmacSHA512(vnp.getSecretKey(), hashData.toString());
        params.put("vnp_SecureHash", signature);

        boolean ok = client.verifyCallback(params);
        Assertions.assertTrue(ok);
    }

    @Test
    void verifyCallback_invalidSignature_returnsFalse() {
        PaymentProperties props = new PaymentProperties();
        PaymentProperties.VnPay vnp = new PaymentProperties.VnPay();
        vnp.setSecretKey("test-secret");
        props.setVnpay(vnp);

        VnPayClient client = new VnPayClient(props);
        Map<String, String> params = new HashMap<>();
        params.put("vnp_TxnRef", "P123");
        params.put("vnp_SecureHash", "bad-hash");

        boolean ok = client.verifyCallback(params);
        Assertions.assertFalse(ok);
    }
}
