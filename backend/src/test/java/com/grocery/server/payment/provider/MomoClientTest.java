package com.grocery.server.payment.provider;

import com.grocery.server.payment.config.PaymentProperties;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;

public class MomoClientTest {

    private static String hmacSHA256(String key, String data) throws Exception {
        Mac sha256_HMAC = Mac.getInstance("HmacSHA256");
        SecretKeySpec secret_key = new SecretKeySpec(key.getBytes(StandardCharsets.UTF_8), "HmacSHA256");
        sha256_HMAC.init(secret_key);
        byte[] hash = sha256_HMAC.doFinal(data.getBytes(StandardCharsets.UTF_8));
        StringBuilder sb = new StringBuilder(2 * hash.length);
        for (byte b : hash) sb.append(String.format("%02x", b & 0xff));
        return sb.toString();
    }

    @Test
    void verifyCallback_validSignature_returnsTrue() throws Exception {
        PaymentProperties props = new PaymentProperties();
        PaymentProperties.Momo momo = new PaymentProperties.Momo();
        momo.setSecretKey("test-secret");
        props.setMomo(momo);

        MomoClient client = new MomoClient(props);

        Map<String, String> params = new LinkedHashMap<>();
        params.put("partnerCode", "P1");
        params.put("accessKey", "A1");
        params.put("requestId", "R1");
        params.put("amount", "10000");
        params.put("orderId", "O1");
        params.put("orderInfo", "info");
        params.put("orderType", "");
        params.put("transId", "");
        params.put("message", "");
        params.put("localMessage", "");
        params.put("responseTime", "");
        params.put("errorCode", "0");
        params.put("payType", "");
        params.put("extraData", "123");

        // build raw string same as client
        StringBuilder raw = new StringBuilder();
        params.forEach((k, v) -> {
            if (raw.length() > 0) raw.append('&');
            raw.append(k).append('=').append(v);
        });

        String signature = hmacSHA256(momo.getSecretKey(), raw.toString());
        params.put("signature", signature);

        boolean ok = client.verifyCallback(params);
        Assertions.assertTrue(ok);
    }

    @Test
    void verifyCallback_invalidSignature_returnsFalse() throws Exception {
        PaymentProperties props = new PaymentProperties();
        PaymentProperties.Momo momo = new PaymentProperties.Momo();
        momo.setSecretKey("test-secret");
        props.setMomo(momo);

        MomoClient client = new MomoClient(props);
        Map<String, String> params = new LinkedHashMap<>();
        params.put("partnerCode", "P1");
        params.put("accessKey", "A1");
        params.put("requestId", "R1");
        params.put("amount", "10000");
        params.put("orderId", "O1");
        params.put("orderInfo", "info");
        params.put("extraData", "123");
        params.put("signature", "bad-signature");

        boolean ok = client.verifyCallback(params);
        Assertions.assertFalse(ok);
    }
}
