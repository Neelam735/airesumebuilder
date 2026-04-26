package com.buildifyai.api.controller;

import com.buildifyai.api.model.ContactMessage;
import com.buildifyai.api.service.ContactService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/contact")
public class ContactController {

    private final ContactService service;

    public ContactController(ContactService service) {
        this.service = service;
    }

    @PostMapping
    public ResponseEntity<Map<String, Object>> create(@Valid @RequestBody ContactMessage payload) {
        ContactMessage saved = service.save(payload);
        return ResponseEntity.status(201).body(Map.of(
            "success", true,
            "id", saved.getId()
        ));
    }

    @GetMapping
    public Map<String, Object> list() {
        List<ContactMessage> items = service.findAll();
        return Map.of("count", items.size(), "items", items);
    }
}
