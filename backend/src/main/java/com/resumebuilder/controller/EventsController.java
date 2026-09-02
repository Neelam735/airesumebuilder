package com.resumebuilder.controller;

import com.resumebuilder.dto.EventRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Receives lightweight analytics events from the app and writes them to the
 * server log so usage (app open, enhance, download, payment, …) is visible in
 * Railway logs. Fire-and-forget: always returns 204, never fails the client.
 */
@RestController
@RequestMapping("/api/v1")
public class EventsController {

    // Dedicated logger name so events are easy to grep/filter in Railway.
    private static final Logger log = LoggerFactory.getLogger("USER_EVENT");

    @PostMapping("/events")
    public ResponseEntity<Void> logEvent(@RequestBody(required = false) EventRequest req) {
        if (req == null || req.getEvent() == null || req.getEvent().isBlank()) {
            return ResponseEntity.noContent().build();
        }
        log.info("event=\"{}\" detail=\"{}\" session={} platform={} appVersion={}",
                clean(req.getEvent()),
                clean(req.getDetail()),
                clean(req.getSessionId()),
                clean(req.getPlatform()),
                clean(req.getAppVersion()));
        return ResponseEntity.noContent().build();
    }

    /** Strip newlines (log-injection safe) and cap length. */
    private static String clean(String s) {
        if (s == null) return "";
        String v = s.replaceAll("[\\r\\n\\t]", " ").trim();
        return v.length() > 200 ? v.substring(0, 200) : v;
    }
}
