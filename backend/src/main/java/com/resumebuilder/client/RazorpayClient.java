package com.resumebuilder.client;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.resumebuilder.config.RazorpayProperties;
import com.resumebuilder.exception.ApiException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.HexFormat;
import java.util.Map;

@Component
public class RazorpayClient {

    private static final Logger log = LoggerFactory.getLogger(RazorpayClient.class);
    private static final String RAZORPAY_BASE = "https://api.razorpay.com/v1";

    private final RazorpayProperties properties;
    private final WebClient webClient;
    private final ObjectMapper mapper = new ObjectMapper();

    public RazorpayClient(RazorpayProperties properties) {
        this.properties = properties;
        this.webClient = WebClient.builder().baseUrl(RAZORPAY_BASE).build();
    }

    public JsonNode createOrder(int amount, String currency, String receipt) {
        Map<String, Object> body = Map.of(
                "amount", amount,
                "currency", currency,
                "receipt", receipt,
                "payment_capture", 1
        );

        log.info("Creating Razorpay order: amount={} currency={} receipt={}", amount, currency, receipt);

        try {
            String response = webClient.post()
                    .uri("/orders")
                    .headers(h -> h.setBasicAuth(properties.getKeyId(), properties.getKeySecret()))
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(body)
                    .retrieve()
                    .bodyToMono(String.class)
                    .timeout(Duration.ofSeconds(15))
                    .block();
            return mapper.readTree(response);
        } catch (Exception e) {
            log.error("Razorpay order creation failed", e);
            throw new ApiException(HttpStatus.BAD_GATEWAY,
                    "Unable to create payment order. Please try again.", e);
        }
    }

    public boolean verifySignature(String orderId, String paymentId, String signature) {
        if (orderId == null || paymentId == null || signature == null) {
            return false;
        }
        String payload = orderId + "|" + paymentId;
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            SecretKeySpec key = new SecretKeySpec(
                    properties.getKeySecret().getBytes(StandardCharsets.UTF_8),
                    "HmacSHA256"
            );
            mac.init(key);
            byte[] hash = mac.doFinal(payload.getBytes(StandardCharsets.UTF_8));
            String generated = HexFormat.of().formatHex(hash);
            boolean ok = constantTimeEquals(generated, signature);
            log.info("Payment verification result for orderId={} -> {}", orderId, ok);
            return ok;
        } catch (Exception e) {
            log.error("Signature verification failed", e);
            return false;
        }
    }

    private boolean constantTimeEquals(String a, String b) {
        if (a == null || b == null || a.length() != b.length()) return false;
        int result = 0;
        for (int i = 0; i < a.length(); i++) {
            result |= a.charAt(i) ^ b.charAt(i);
        }
        return result == 0;
    }
}
