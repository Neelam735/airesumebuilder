package com.resumebuilder.config;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/**
 * Logs every incoming API request so real user activity is visible in the
 * server (Railway) logs without any change to the mobile app.
 *
 * Each request produces one line under the "USER_EVENT" logger, e.g.
 *   action=RESUME_ENHANCE method=POST path=/api/v1/resume/parse status=200 durationMs=2143 ip=1.2.3.4 ua="Dart/3.3 (dart:io)"
 *
 * Health checks are logged at DEBUG so Railway's constant probes don't drown
 * out real traffic. Nothing from the request body is logged, so no resume
 * content or personal data is written to the logs.
 */
@Component
@Order(Ordered.HIGHEST_PRECEDENCE + 10)
public class RequestLoggingFilter extends OncePerRequestFilter {

    // Same logger name the app-event endpoint uses, so one filter shows everything.
    private static final Logger log = LoggerFactory.getLogger("USER_EVENT");

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        long start = System.currentTimeMillis();
        try {
            chain.doFilter(request, response);
        } finally {
            String path = request.getRequestURI();
            // Only report our own API surface; ignore favicon/static probes.
            if (path != null && path.startsWith("/api/")) {
                long ms = System.currentTimeMillis() - start;
                String line = "action={} method={} path={} status={} durationMs={} ip={} ua=\"{}\"";
                Object[] args = {
                        action(path),
                        clean(request.getMethod()),
                        clean(path),
                        response.getStatus(),
                        ms,
                        clientIp(request),
                        clean(request.getHeader("User-Agent"))
                };
                if (isHealth(path)) {
                    log.debug(line, args);
                } else {
                    log.info(line, args);
                }
            }
        }
    }

    private static boolean isHealth(String path) {
        return path.endsWith("/health");
    }

    /** Friendly label so the logs read as user actions rather than raw paths. */
    private static String action(String path) {
        if (path.endsWith("/resume/parse")) return "RESUME_ENHANCE";
        if (path.endsWith("/payment/verify")) return "PAYMENT_VERIFY";
        if (path.endsWith("/events")) return "APP_EVENT";
        if (path.endsWith("/jobs/match")) return "JOBS_MATCH";
        if (path.endsWith("/jobs/cover-letter")) return "COVER_LETTER";
        if (isHealth(path)) return "HEALTH";
        return "API_CALL";
    }

    /**
     * Railway terminates TLS at a proxy, so the socket address is the proxy's.
     * Prefer the first hop in X-Forwarded-For, which is the real client.
     */
    private static String clientIp(HttpServletRequest request) {
        String fwd = request.getHeader("X-Forwarded-For");
        if (fwd != null && !fwd.isBlank()) {
            int comma = fwd.indexOf(',');
            return clean(comma > 0 ? fwd.substring(0, comma) : fwd);
        }
        return clean(request.getRemoteAddr());
    }

    /** Strip newlines (log-injection safe) and cap length. */
    private static String clean(String s) {
        if (s == null) return "";
        String v = s.replaceAll("[\\r\\n\\t]", " ").trim();
        return v.length() > 200 ? v.substring(0, 200) : v;
    }
}
