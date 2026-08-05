package com.resumebuilder.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.resumebuilder.client.GooglePlayBillingClient;
import com.resumebuilder.config.GooglePlayProperties;
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

/**
 * Verifies Google Play in-app purchases and issues short-lived signed tokens
 * the client can present to {@code /api/v1/resume/parse}.
 */
@Service
public class PaymentService {

    private static final Logger log = LoggerFactory.getLogger(PaymentService.class);
    private static final long TOKEN_TTL_MS = 30 * 60 * 1000L;

    private final GooglePlayBillingClient billingClient;
    private final GooglePlayProperties properties;
    private final Map<String, TokenRecord> verifiedTokens = new ConcurrentHashMap<>();

    public PaymentService(GooglePlayBillingClient billingClient, GooglePlayProperties properties) {
        this.billingClient = billingClient;
        this.properties = properties;
    }

    public VerifyPaymentResponse verifyPayment(VerifyPaymentRequest request) {
        String productId = request.getProductId();
        String purchaseToken = request.getPurchaseToken();
        if (productId == null || productId.isBlank()) {
            productId = properties.getProductId();
        }
        if (productId == null || productId.isBlank()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "productId is required");
        }
        if (!productId.equals(properties.getProductId())) {
            throw new ApiException(HttpStatus.BAD_REQUEST,
                    "Unknown product id: " + productId);
        }

        JsonNode purchase = billingClient.verifyProductPurchase(productId, purchaseToken);

        // purchaseState: 0 = purchased, 1 = canceled, 2 = pending
        int purchaseState = purchase.path("purchaseState").asInt(-1);
        if (purchaseState != 0) {
            log.warn("Rejected Google Play purchase. state={} token={}",
                    purchaseState, abbreviate(purchaseToken));
            throw new ApiException(HttpStatus.BAD_REQUEST,
                    "Purchase is not in PURCHASED state (state=" + purchaseState + ")");
        }

        // consumptionState: 0 = yet to be consumed, 1 = consumed.
        // The Android client buys with autoConsume, so by the time we verify,
        // the purchase is often already consumed on Google's side. That is still
        // a legitimate, paid purchase — only consume it ourselves if the client
        // hasn't already, and never reject solely because it was consumed.
        int consumptionState = purchase.path("consumptionState").asInt(-1);
        if (consumptionState != 1) {
            // Mark as consumed on Google's side so it can't be reused.
            billingClient.consumeProductPurchase(productId, purchaseToken);
        } else {
            log.info("Purchase already consumed client-side; accepting. token={}",
                    abbreviate(purchaseToken));
        }

        String token = issueToken(productId, purchaseToken);
        return new VerifyPaymentResponse(true, token, "Purchase verified successfully");
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

    private String issueToken(String productId, String purchaseToken) {
        String tokenId = UUID.randomUUID().toString();
        long expiresAt = System.currentTimeMillis() + TOKEN_TTL_MS;
        String payload = tokenId + "|" + productId + "|" + purchaseToken + "|" + expiresAt;
        String sig = hmac(payload);
        String token = tokenId + "." + sig;
        verifiedTokens.put(token, new TokenRecord(productId, purchaseToken, expiresAt));
        return token;
    }

    private boolean verifySignedToken(String token, TokenRecord record) {
        int dot = token.indexOf('.');
        if (dot < 0) return false;
        String tokenId = token.substring(0, dot);
        String sig = token.substring(dot + 1);
        String payload = tokenId + "|" + record.productId + "|" + record.purchaseToken + "|" + record.expiresAt;
        return constantTimeEquals(hmac(payload), sig);
    }

    private String hmac(String payload) {
        try {
            String key = properties.getTokenSigningKey();
            if (key == null || key.isBlank()) {
                throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE,
                        "google-play.token-signing-key is not configured");
            }
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(key.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            return HexFormat.of().formatHex(mac.doFinal(payload.getBytes(StandardCharsets.UTF_8)));
        } catch (ApiException e) {
            throw e;
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

    private static String abbreviate(String s) {
        if (s == null) return "<null>";
        return s.length() > 16 ? s.substring(0, 8) + "..." + s.substring(s.length() - 4) : s;
    }

    private record TokenRecord(String productId, String purchaseToken, long expiresAt) {}
}
