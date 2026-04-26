package com.resumebuilder.client;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.resumebuilder.config.GrokProperties;
import com.resumebuilder.exception.ApiException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

import java.time.Duration;
import java.util.List;
import java.util.Map;

@Component
public class GrokClient {

    private static final Logger log = LoggerFactory.getLogger(GrokClient.class);

    private final GrokProperties properties;
    private final WebClient webClient;
    private final ObjectMapper mapper = new ObjectMapper();

    public GrokClient(GrokProperties properties) {
        this.properties = properties;
        this.webClient = WebClient.builder()
                .baseUrl(properties.getBaseUrl())
                .defaultHeader("Authorization", "Bearer " + properties.getApiKey())
                .build();
    }

    public String chatCompletion(String systemPrompt, String userPrompt) {
        Map<String, Object> body = Map.of(
                "model", properties.getModel(),
                "temperature", 0.4,
                "response_format", Map.of("type", "json_object"),
                "messages", List.of(
                        Map.of("role", "system", "content", systemPrompt),
                        Map.of("role", "user", "content", userPrompt)
                )
        );

        log.info("Calling Grok model={}", properties.getModel());

        try {
            String raw = webClient.post()
                    .uri("/chat/completions")
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(body)
                    .retrieve()
                    .bodyToMono(String.class)
                    .timeout(Duration.ofSeconds(properties.getTimeoutSeconds()))
                    .block();

            JsonNode response = mapper.readTree(raw);
            JsonNode choices = response.path("choices");
            if (choices.isMissingNode() || !choices.isArray() || choices.isEmpty()) {
                throw new ApiException(HttpStatus.BAD_GATEWAY, "Empty response from AI service");
            }
            return choices.get(0).path("message").path("content").asText();
        } catch (ApiException e) {
            throw e;
        } catch (Exception e) {
            log.error("Grok API call failed", e);
            throw new ApiException(HttpStatus.BAD_GATEWAY,
                    "AI service is temporarily unavailable. Please try again.", e);
        }
    }
}
