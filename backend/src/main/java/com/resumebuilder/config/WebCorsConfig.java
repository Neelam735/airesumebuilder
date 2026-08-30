package com.resumebuilder.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.util.Arrays;

/**
 * Enables CORS for the browser-based web frontend. Origins come from the
 * {@code cors.allowed-origins} property (env {@code CORS_ORIGINS}), a
 * comma-separated list. Wildcard patterns are supported (e.g.
 * {@code https://*.vercel.app}).
 */
@Configuration
public class WebCorsConfig implements WebMvcConfigurer {

    @Value("${cors.allowed-origins:http://localhost:5173,http://localhost:3000}")
    private String allowedOrigins;

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        String[] origins = Arrays.stream(allowedOrigins.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .toArray(String[]::new);
        if (origins.length == 0) {
            origins = new String[]{"http://localhost:5173", "http://localhost:3000"};
        }
        registry.addMapping("/api/**")
                // allowedOriginPatterns supports wildcards like https://*.vercel.app
                .allowedOriginPatterns(origins)
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .maxAge(3600);
    }
}
