package com.buildifyai.api.controller;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    public static class SignupRequest {
        @NotBlank @Size(min = 2) public String name;
        @NotBlank @Email public String email;
        @NotBlank @Size(min = 6) public String password;
    }

    public static class LoginRequest {
        @NotBlank @Email public String email;
        @NotBlank @Size(min = 6) public String password;
    }

    @PostMapping("/signup")
    public ResponseEntity<Map<String, Object>> signup(@Valid @RequestBody SignupRequest req) {
        // TODO: hash password, save user, return JWT
        return ResponseEntity.status(201).body(Map.of(
            "success", true,
            "user", Map.of("name", req.name, "email", req.email.toLowerCase()),
            "token", "demo-token-" + System.currentTimeMillis()
        ));
    }

    @PostMapping("/login")
    public Map<String, Object> login(@Valid @RequestBody LoginRequest req) {
        return Map.of(
            "success", true,
            "user", Map.of("email", req.email.toLowerCase()),
            "token", "demo-token-" + System.currentTimeMillis()
        );
    }
}
