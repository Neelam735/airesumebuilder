package com.resumebuilder.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.resumebuilder.client.RazorpayClient;
import com.resumebuilder.config.RazorpayProperties;
import com.resumebuilder.dto.CreateOrderRequest;
import com.resumebuilder.dto.CreateOrderResponse;
import com.resumebuilder.dto.VerifyPaymentRequest;
import com.resumebuilder.dto.VerifyPaymentResponse;
import com.resumebuilder.exception.ApiException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.util.HexFormat;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class PaymentService {

    private static final Logger log = LoggerFactory.getLogger(PaymentService.class);
    private static final long TOKEN_TTL_MS = 30 * 60 * 1000L;

    private final RazorpayClient razorpayClient;
    private final RazorpayProperties properties;
    private final Map<String, TokenRecord> verifiedTokens = new ConcurrentHashMap<>();

    public PaymentService(RazorpayClient razorpayClient, RazorpayProperties properties) {
        this.razorpayClient = razorpayClient;
        this.properties = properties;
    }

    public CreateOrderResponse createOrder(CreateOrderRequest request) {
        int amount = request.getAmount() != null ? request.getAmount() : properties.getAmount();
        String currency = request.getCurrency() != null ? request.getCurrency() : properties.getCurrency();
        String receipt = request.getReceipt() != null
                ? request.getReceipt()
                : "rcpt_" + UUID.randomUUID().toString().substring(0, 12);

        if (amount != properties.getAmount()) {
            log.warn("Client requested amount {} differs from configured {}; using configured value",
                    amount, properties.getAmount());
            amount = properties.getAmount();
        }

        JsonNode order = razorpayClient.createOrder(amount, currency, receipt);

        CreateOrderResponse response = new CreateOrderResponse();
        response.setOrderId(order.path("id").asText());
        response.setAmount(order.path("amount").asInt());
        response.setCurrency(order.path("currency").asText());
        response.setReceipt(order.path("receipt").asText());
        response.setStatus(order.path("status").asText());
        response.setKeyId(properties.getKeyId());
        return response;
    }

    public VerifyPaymentResponse verifyPayment(VerifyPaymentRequest request) {
        boolean valid = razorpayClient.verifySignature(
                request.getRazorpayOrderId(),
                request.getRazorpayPaymentId(),
                request.getRazorpaySignature()
        );

        if (!valid) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Payment signature verification failed");
        }

        String token = issueToken(request.getRazorpayOrderId(), request.getRazorpayPaymentId());
        return new VerifyPaymentResponse(true, token, "Payment verified successfully");
    }

    public boolean isTokenValid(String token) {
        if (token == null) return false;
        TokenRecord record = verifiedTokens.get(token);
        if (record == null) return false;
        if (record.expiresAt < System.currentTimeMillis()) {
            verifiedTokens.remove(token);
            return false;
        }
        return verifySignedToken(token, record);
    }

    public void consumeToken(String token) {
        verifiedTokens.remove(token);
    }

    private String issueToken(String orderId, String paymentId) {
        String tokenId = UUID.randomUUID().toString();
        long expiresAt = System.currentTimeMillis() + TOKEN_TTL_MS;
        String payload = tokenId + "|" + orderId + "|" + paymentId + "|" + expiresAt;
        String sig = hmac(payload);
        String token = tokenId + "." + sig;
        verifiedTokens.put(token, new TokenRecord(orderId, paymentId, expiresAt, sig));
        return token;
    }

    private boolean verifySignedToken(String token, TokenRecord record) {
        int dot = token.indexOf('.');
        if (dot < 0) return false;
        String tokenId = token.substring(0, dot);
        String sig = token.substring(dot + 1);
        String payload = tokenId + "|" + record.orderId + "|" + record.paymentId + "|" + record.expiresAt;
        String expected = hmac(payload);
        return constantTimeEquals(expected, sig);
    }

    private String hmac(String payload) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(
                    properties.getKeySecret().getBytes(StandardCharsets.UTF_8),
                    "HmacSHA256"));
            return HexFormat.of().formatHex(mac.doFinal(payload.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception e) {
            throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "Token signing failed", e);
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

    private record TokenRecord(String orderId, String paymentId, long expiresAt, String signature) {}
}
