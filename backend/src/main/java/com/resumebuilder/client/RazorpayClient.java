package com.resumebuilder.client;

import com.fasterxml.jackson.databind.JsonNode;
import com.resumebuilder.config.RazorpayProperties;
import com.resumebuilder.exception.ApiException;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;

import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Base64;
import java.util.Map;

/**
 * Thin client over the Razorpay Orders REST API.
 *
 * Only order creation needs an outbound call — payment verification is a local
 * HMAC check (see RazorpayService), so it costs no network round trip.
 */
@Component
public class RazorpayClient {

    private static final Logger log = LoggerFactory.getLogger(RazorpayClient.class);
    private static final String ORDERS_URL = "https://api.razorpay.com/v1/orders";

    private final RazorpayProperties properties;
    private final WebClient webClient = WebClient.builder().build();

    public RazorpayClient(RazorpayProperties properties) {
        this.properties = properties;
    }

    @PostConstruct
    void init() {
        // Never log the secret itself — only whether it is present.
        log.info("Razorpay config: keyId={} secret={} amount={} {}",
                properties.getKeyId() == null || properties.getKeyId().isBlank()
                        ? "<unset>" : properties.getKeyId(),
                properties.getKeySecret() == null || properties.getKeySecret().isBlank()
                        ? "<unset>" : "<provided>",
                properties.getAmount(), properties.getCurrency());
        if (!properties.isConfigured()) {
            log.warn("Razorpay is not configured. Set RAZORPAY_KEY_ID and "
                    + "RAZORPAY_KEY_SECRET to enable Razorpay checkout.");
        }
    }

    /**
     * Creates a Razorpay order for the configured amount and returns the raw
     * order JSON (its {@code id} is what the app hands to Checkout).
     */
    public JsonNode createOrder(String receipt) {
        if (!properties.isConfigured()) {
            throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Razorpay is not configured on the server");
        }
        Map<String, Object> body = Map.of(
                "amount", properties.getAmount(),
                "currency", properties.getCurrency(),
                "receipt", receipt,
                // Capture automatically so a successful payment needs no second step.
                "payment_capture", 1
        );
        try {
            JsonNode order = webClient.post()
                    .uri(ORDERS_URL)
                    .header(HttpHeaders.AUTHORIZATION, basicAuth())
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(body)
                    .retrieve()
                    .bodyToMono(JsonNode.class)
                    .timeout(Duration.ofSeconds(20))
                    .block();
            if (order == null || order.path("id").asText("").isBlank()) {
                throw new ApiException(HttpStatus.BAD_GATEWAY,
                        "Razorpay did not return an order id");
            }
            return order;
        } catch (ApiException e) {
            throw e;
        } catch (WebClientResponseException e) {
            log.warn("Razorpay order creation failed: status={} body={}",
                    e.getStatusCode(), e.getResponseBodyAsString());
            if (e.getStatusCode() == HttpStatus.UNAUTHORIZED) {
                throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE,
                        "Razorpay rejected the API key. Check RAZORPAY_KEY_ID / RAZORPAY_KEY_SECRET.", e);
            }
            throw new ApiException(HttpStatus.BAD_GATEWAY,
                    "Could not create the Razorpay order", e);
        } catch (Exception e) {
            log.warn("Razorpay order creation error", e);
            throw new ApiException(HttpStatus.BAD_GATEWAY,
                    "Could not reach Razorpay", e);
        }
    }

    private String basicAuth() {
        String creds = properties.getKeyId() + ":" + properties.getKeySecret();
        return "Basic " + Base64.getEncoder()
                .encodeToString(creds.getBytes(StandardCharsets.UTF_8));
    }
}
