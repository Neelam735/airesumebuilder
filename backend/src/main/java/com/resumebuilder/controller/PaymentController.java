package com.resumebuilder.controller;

import com.resumebuilder.dto.CreateOrderRequest;
import com.resumebuilder.dto.CreateOrderResponse;
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

    @PostMapping("/create-order")
    public ResponseEntity<CreateOrderResponse> createOrder(@RequestBody(required = false) CreateOrderRequest request) {
        CreateOrderRequest req = request != null ? request : new CreateOrderRequest();
        return ResponseEntity.ok(paymentService.createOrder(req));
    }

    @PostMapping("/verify")
    public ResponseEntity<VerifyPaymentResponse> verify(@RequestBody VerifyPaymentRequest request) {
        return ResponseEntity.ok(paymentService.verifyPayment(request));
    }
}
