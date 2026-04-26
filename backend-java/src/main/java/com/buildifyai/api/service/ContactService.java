package com.buildifyai.api.service;

import com.buildifyai.api.model.ContactMessage;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CopyOnWriteArrayList;

@Service
public class ContactService {

    private final List<ContactMessage> store = new CopyOnWriteArrayList<>();

    public ContactMessage save(ContactMessage msg) {
        msg.setId(UUID.randomUUID().toString());
        msg.setCreatedAt(Instant.now());
        store.add(msg);
        System.out.println("[CONTACT] " + msg.getEmail() + " - " + msg.getName());
        return msg;
    }

    public List<ContactMessage> findAll() {
        return List.copyOf(store);
    }
}
