package com.resumebuilder.client;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.resumebuilder.config.GeminiProperties;
import com.resumebuilder.exception.ApiException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;

import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Component
public class GeminiClient {

    private static final Logger log = LoggerFactory.getLogger(GeminiClient.class);

    private final GeminiProperties properties;
    private final WebClient webClient;
    private final ObjectMapper mapper = new ObjectMapper();

    public GeminiClient(GeminiProperties properties) {
        this.properties = properties;
        this.webClient = WebClient.builder()
                .baseUrl(properties.getBaseUrl())
                .defaultHeader("x-goog-api-key", properties.getApiKey())
                .build();
    }

    public String generateContent(String systemPrompt, String userPrompt) {
        Map<String, Object> generationConfig = new LinkedHashMap<>();
        generationConfig.put("temperature", 0.4);
        if (properties.isJsonMode()) {
            generationConfig.put("responseMimeType", "application/json");
        }

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("systemInstruction", Map.of("parts", List.of(Map.of("text", systemPrompt))));
        body.put("contents", List.of(
                Map.of(
                        "role", "user",
                        "parts", List.of(Map.of("text", userPrompt))
                )
        ));
        body.put("generationConfig", generationConfig);

        String uri = "/models/" + properties.getModel() + ":generateContent";
        log.info("Calling Gemini model={} jsonMode={}", properties.getModel(), properties.isJsonMode());

        try {
            String raw = webClient.post()
                    .uri(uri)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(body)
                    .retrieve()
                    .bodyToMono(String.class)
                    .timeout(Duration.ofSeconds(properties.getTimeoutSeconds()))
                    .block();

            JsonNode response = mapper.readTree(raw);
            JsonNode candidates = response.path("candidates");
            if (candidates.isMissingNode() || !candidates.isArray() || candidates.isEmpty()) {
                JsonNode promptFeedback = response.path("promptFeedback");
                String reason = promptFeedback.path("blockReason").asText("no candidates returned");
                throw new ApiException(HttpStatus.BAD_GATEWAY, "Empty response from AI service: " + reason);
            }

            JsonNode firstCandidate = candidates.get(0);
            String finishReason = firstCandidate.path("finishReason").asText("");
            if ("SAFETY".equals(finishReason) || "RECITATION".equals(finishReason)) {
                throw new ApiException(HttpStatus.BAD_GATEWAY,
                        "AI declined to process this content (" + finishReason + "). Try a different resume.");
            }

            JsonNode parts = firstCandidate.path("content").path("parts");
            if (!parts.isArray() || parts.isEmpty()) {
                throw new ApiException(HttpStatus.BAD_GATEWAY, "AI response had no content parts");
            }

            StringBuilder text = new StringBuilder();
            for (JsonNode part : parts) {
                String chunk = part.path("text").asText("");
                if (!chunk.isEmpty()) text.append(chunk);
            }
            return text.toString();
        } catch (WebClientResponseException e) {
            String responseBody = e.getResponseBodyAsString();
            log.error("Gemini API returned {} body={}", e.getStatusCode(), responseBody);
            throw new ApiException(HttpStatus.BAD_GATEWAY,
                    "AI service rejected the request: " + extractErrorMessage(responseBody), e);
        } catch (ApiException e) {
            throw e;
        } catch (Exception e) {
            log.error("Gemini API call failed", e);
            throw new ApiException(HttpStatus.BAD_GATEWAY,
                    "AI service is temporarily unavailable. Please try again.", e);
        }
    }

    private String extractErrorMessage(String responseBody) {
        if (responseBody == null || responseBody.isBlank()) return "unknown error";
        try {
            JsonNode err = mapper.readTree(responseBody).path("error");
            String msg = err.isObject() ? err.path("message").asText(null) : err.asText(null);
            return msg != null && !msg.isBlank() ? msg : responseBody;
        } catch (Exception ignored) {
            return responseBody;
        }
    }
}
