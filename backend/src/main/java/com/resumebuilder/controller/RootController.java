package com.resumebuilder.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * Friendly landing response for the root URL so visiting the base domain in a
 * browser returns a clean 200 (with a pointer to the API) instead of an error.
 */
@RestController
public class RootController {

    @GetMapping("/")
    public Map<String, Object> root() {
        return Map.of(
                "service", "resume-builder-backend",
                "status", "UP",
                "docs", "Use the API under /api/v1 (e.g. GET /api/v1/health)"
        );
    }
}
