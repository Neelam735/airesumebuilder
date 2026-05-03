package com.resumebuilder.client;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.resumebuilder.exception.ApiException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;
import org.springframework.web.util.UriComponentsBuilder;

import java.net.URI;
import java.time.Duration;

@Component
public class RemotiveClient {

    private static final Logger log = LoggerFactory.getLogger(RemotiveClient.class);
    private static final String BASE_URL = "https://remotive.com/api/remote-jobs";

    private final WebClient webClient = WebClient.builder()
            .defaultHeader("User-Agent", "ResumeForgeAI/1.0")
            .build();
    private final ObjectMapper mapper = new ObjectMapper();

    public JsonNode searchJobs(String search, String category, int limit) {
        UriComponentsBuilder url = UriComponentsBuilder.fromHttpUrl(BASE_URL);
        if (search != null && !search.isBlank()) url.queryParam("search", search);
        if (category != null && !category.isBlank()) url.queryParam("category", category);
        if (limit > 0) url.queryParam("limit", Math.min(limit, 50));
        URI uri = url.build().encode().toUri();

        log.info("Fetching jobs from Remotive: {}", uri);

        try {
            String raw = webClient.get()
                    .uri(uri)
                    .retrieve()
                    .bodyToMono(String.class)
                    .timeout(Duration.ofSeconds(15))
                    .block();
            return mapper.readTree(raw);
        } catch (WebClientResponseException e) {
            log.error("Remotive returned {} body={}", e.getStatusCode(), e.getResponseBodyAsString());
            throw new ApiException(HttpStatus.BAD_GATEWAY,
                    "Job board is unavailable. Please try again later.", e);
        } catch (Exception e) {
            log.error("Remotive request failed", e);
            throw new ApiException(HttpStatus.BAD_GATEWAY,
                    "Job board is unavailable. Please try again later.", e);
        }
    }
}
