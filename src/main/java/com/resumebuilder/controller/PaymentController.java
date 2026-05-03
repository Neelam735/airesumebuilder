package com.resumebuilder.controller;

import com.resumebuilder.dto.VerifyPaymentRequest;
import com.resumebuilder.dto.VerifyPaymentResponse;
import com.resumebuilder.service.PaymentService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/payment")
public class PaymentController {

    private final PaymentService paymentService;

    public PaymentController(PaymentService paymentService) {
        this.paymentService = paymentService;
    }

    /**
     * Verifies a Google Play in-app purchase. The mobile client purchases a
     * consumable product via Google Play Billing, receives a {@code productId}
     * and {@code purchaseToken}, and posts them here. On success the server
     * issues a single-use signed token the client uses to call /resume/parse.
     */
    @PostMapping("/verify")
    public ResponseEntity<VerifyPaymentResponse> verify(@RequestBody VerifyPaymentRequest request) {
        return ResponseEntity.ok(paymentService.verifyPayment(request));
    }
}
