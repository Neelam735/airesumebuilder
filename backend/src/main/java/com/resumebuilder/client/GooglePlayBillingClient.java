package com.resumebuilder.client;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.auth.oauth2.AccessToken;
import com.google.auth.oauth2.GoogleCredentials;
import com.resumebuilder.config.GooglePlayProperties;
import com.resumebuilder.exception.ApiException;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;

import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Date;
import java.util.List;

@Component
public class GooglePlayBillingClient {

    private static final Logger log = LoggerFactory.getLogger(GooglePlayBillingClient.class);
    private static final String ANDROID_PUBLISHER_BASE = "https://androidpublisher.googleapis.com/androidpublisher/v3";
    private static final String SCOPE = "https://www.googleapis.com/auth/androidpublisher";

    private final GooglePlayProperties properties;
    private final WebClient webClient = WebClient.builder().build();
    private final ObjectMapper mapper = new ObjectMapper();

    private GoogleCredentials credentials;

    public GooglePlayBillingClient(GooglePlayProperties properties) {
        this.properties = properties;
    }

    @PostConstruct
    void init() {
        log.info("Google Play Billing config: packageName={} productId={} serviceAccount={}",
                properties.getPackageName(), properties.getProductId(),
                properties.getServiceAccountJson() == null ? "<unset>" : "<provided>");

        if (properties.getPackageName() == null || properties.getPackageName().isBlank()) {
            log.warn("google-play.package-name is not configured. Verification will fail.");
        }
        if (properties.getServiceAccountJson() == null || properties.getServiceAccountJson().isBlank()) {
            log.warn("google-play.service-account-json is not set. "
                    + "Provide a service-account credential file or inline JSON via "
                    + "GOOGLE_PLAY_SERVICE_ACCOUNT_JSON.");
            return;
        }
        try {
            credentials = loadCredentials(properties.getServiceAccountJson()).createScoped(List.of(SCOPE));
        } catch (Exception e) {
            log.error("Failed to load Google service-account credentials", e);
        }
    }

    /**
     * Verify a one-time product purchase against Google Play Developer API.
     * Returns the raw JSON response on success and throws ApiException on any
     * failure (invalid token, wrong product, network issue, etc.).
     */
    public JsonNode verifyProductPurchase(String productId, String purchaseToken) {
        if (credentials == null) {
            throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Google Play verification is not configured on the server.");
        }
        if (purchaseToken == null || purchaseToken.isBlank()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "purchaseToken is required");
        }

        URI uri = URI.create(ANDROID_PUBLISHER_BASE
                + "/applications/" + properties.getPackageName()
                + "/purchases/products/" + productId
                + "/tokens/" + purchaseToken);

        log.info("Verifying Google Play purchase: productId={} uri={}", productId, uri);
        String accessToken = bearerToken();

        try {
            String raw = webClient.get()
                    .uri(uri)
                    .headers(h -> h.setBearerAuth(accessToken))
                    .retrieve()
                    .bodyToMono(String.class)
                    .timeout(Duration.ofSeconds(15))
                    .block();
            return mapper.readTree(raw);
        } catch (WebClientResponseException e) {
            String body = e.getResponseBodyAsString();
            log.error("Google Play returned {} body={}", e.getStatusCode(), body);
            throw new ApiException(HttpStatus.BAD_REQUEST,
                    "Purchase verification failed: " + extractErrorMessage(body), e);
        } catch (Exception e) {
            log.error("Google Play verification failed", e);
            throw new ApiException(HttpStatus.BAD_GATEWAY,
                    "Could not reach Google Play. Please retry.", e);
        }
    }

    /**
     * Mark a one-time purchase as consumed so the same token cannot grant the
     * AI improvement twice. Required for consumable products.
     */
    public void consumeProductPurchase(String productId, String purchaseToken) {
        if (credentials == null) return;
        URI uri = URI.create(ANDROID_PUBLISHER_BASE
                + "/applications/" + properties.getPackageName()
                + "/purchases/products/" + productId
                + "/tokens/" + purchaseToken
                + ":consume");

        try {
            webClient.post()
                    .uri(uri)
                    .headers(h -> h.setBearerAuth(bearerToken()))
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue("{}")
                    .retrieve()
                    .bodyToMono(String.class)
                    .timeout(Duration.ofSeconds(10))
                    .block();
            log.info("Consumed Google Play purchase: productId={}", productId);
        } catch (Exception e) {
            log.warn("Failed to consume Google Play purchase {}: {}", purchaseToken, e.getMessage());
        }
    }

    private String bearerToken() {
        try {
            credentials.refreshIfExpired();
            AccessToken token = credentials.getAccessToken();
            if (token == null || token.getExpirationTime() == null
                    || token.getExpirationTime().before(new Date())) {
                credentials.refresh();
                token = credentials.getAccessToken();
            }
            return token.getTokenValue();
        } catch (Exception e) {
            throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Could not obtain Google service-account token", e);
        }
    }

    private static GoogleCredentials loadCredentials(String value) throws Exception {
        String trimmed = value.trim();
        InputStream stream;
        if (trimmed.startsWith("{")) {
            stream = new ByteArrayInputStream(trimmed.getBytes(StandardCharsets.UTF_8));
        } else {
            File file = new File(trimmed);
            if (!file.isFile()) {
                throw new IllegalStateException(
                        "google-play.service-account-json must be either inline JSON or a path to an existing file");
            }
            stream = new FileInputStream(file);
        }
        return GoogleCredentials.fromStream(stream);
    }

    private String extractErrorMessage(String body) {
        if (body == null || body.isBlank()) return "unknown error";
        try {
            JsonNode err = mapper.readTree(body).path("error");
            String msg = err.path("message").asText(null);
            return msg != null && !msg.isBlank() ? msg : body;
        } catch (Exception ignored) {
            return body;
        }
    }
}
