package com.resumebuilder.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.resumebuilder.client.RazorpayClient;
import com.resumebuilder.config.RazorpayProperties;
import com.resumebuilder.dto.RazorpayOrderResponse;
import com.resumebuilder.dto.RazorpayVerifyRequest;
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
import java.util.UUID;

/**
 * Razorpay checkout flow.
 *
 * <ol>
 *   <li>The app asks for an order; we create one server-side for the configured
 *       amount so the price cannot be tampered with by the client.</li>
 *   <li>The app opens Razorpay Checkout with that order id.</li>
 *   <li>On success Razorpay returns order id, payment id and a signature. We
 *       recompute {@code HMAC_SHA256(orderId + "|" + paymentId, keySecret)} and
 *       compare it in constant time — this is what proves the payment is real.</li>
 *   <li>We then mint the same signed payment token Google Play purchases get,
 *       so the download unlock path is identical for both providers.</li>
 * </ol>
 */
@Service
public class RazorpayService {

    private static final Logger log = LoggerFactory.getLogger(RazorpayService.class);

    private final RazorpayClient client;
    private final RazorpayProperties properties;
    private final PaymentService paymentService;

    public RazorpayService(RazorpayClient client,
                           RazorpayProperties properties,
                           PaymentService paymentService) {
        this.client = client;
        this.properties = properties;
        this.paymentService = paymentService;
    }

    /** Creates an order for the server-configured amount. */
    public RazorpayOrderResponse createOrder() {
        String receipt = "rcpt_" + UUID.randomUUID().toString().replace("-", "").substring(0, 20);
        JsonNode order = client.createOrder(receipt);
        String orderId = order.path("id").asText();
        log.info("Created Razorpay order {} for {} {}", orderId,
                properties.getAmount(), properties.getCurrency());
        return new RazorpayOrderResponse(
                orderId,
                order.path("amount").asInt(properties.getAmount()),
                order.path("currency").asText(properties.getCurrency()),
                properties.getKeyId(),
                properties.getCompanyName(),
                properties.getDescription());
    }

    /** Verifies the checkout signature and, on success, issues a payment token. */
    public VerifyPaymentResponse verifyPayment(RazorpayVerifyRequest request) {
        if (!properties.isConfigured()) {
            throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Razorpay is not configured on the server");
        }
        String orderId = request == null ? null : request.getRazorpayOrderId();
        String paymentId = request == null ? null : request.getRazorpayPaymentId();
        String signature = request == null ? null : request.getRazorpaySignature();

        if (isBlank(orderId) || isBlank(paymentId) || isBlank(signature)) {
            throw new ApiException(HttpStatus.BAD_REQUEST,
                    "razorpayOrderId, razorpayPaymentId and razorpaySignature are required");
        }

        String expected = hmacHex(orderId + "|" + paymentId, properties.getKeySecret());
        if (!constantTimeEquals(expected, signature)) {
            log.warn("Rejected Razorpay payment: signature mismatch. order={} payment={}",
                    abbreviate(orderId), abbreviate(paymentId));
            throw new ApiException(HttpStatus.BAD_REQUEST,
                    "Payment signature verification failed");
        }

        log.info("Verified Razorpay payment. order={} payment={}",
                abbreviate(orderId), abbreviate(paymentId));
        String token = paymentService.issueExternalPaymentToken("razorpay:" + paymentId);
        return new VerifyPaymentResponse(true, token, "Payment verified successfully");
    }

    private static String hmacHex(String payload, String secret) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            return HexFormat.of().formatHex(mac.doFinal(payload.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception e) {
            throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR,
                    "Could not verify the payment signature", e);
        }
    }

    private static boolean constantTimeEquals(String a, String b) {
        if (a == null || b == null || a.length() != b.length()) return false;
        int result = 0;
        for (int i = 0; i < a.length(); i++) {
            result |= a.charAt(i) ^ b.charAt(i);
        }
        return result == 0;
    }

    private static boolean isBlank(String s) {
        return s == null || s.isBlank();
    }

    private static String abbreviate(String s) {
        if (s == null) return "<null>";
        return s.length() > 16 ? s.substring(0, 8) + "..." + s.substring(s.length() - 4) : s;
    }
}
