package com.resumebuilder.controller;

import com.resumebuilder.dto.RazorpayOrderResponse;
import com.resumebuilder.dto.RazorpayVerifyRequest;
import com.resumebuilder.dto.VerifyPaymentRequest;
import com.resumebuilder.dto.VerifyPaymentResponse;
import com.resumebuilder.service.PaymentService;
import com.resumebuilder.service.RazorpayService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/payment")
public class PaymentController {

    private final PaymentService paymentService;
    private final RazorpayService razorpayService;

    public PaymentController(PaymentService paymentService, RazorpayService razorpayService) {
        this.paymentService = paymentService;
        this.razorpayService = razorpayService;
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

    /**
     * Creates a Razorpay order for the server-configured amount and returns the
     * details the app needs to open Razorpay Checkout. The amount is decided
     * here, never by the client, so the price cannot be tampered with.
     */
    @PostMapping("/razorpay/order")
    public ResponseEntity<RazorpayOrderResponse> createRazorpayOrder() {
        return ResponseEntity.ok(razorpayService.createOrder());
    }

    /**
     * Verifies a completed Razorpay payment. The app posts the order id,
     * payment id and signature returned by Checkout; on a valid signature the
     * server issues the same single-use payment token a Play purchase yields.
     */
    @PostMapping("/razorpay/verify")
    public ResponseEntity<VerifyPaymentResponse> verifyRazorpay(
            @RequestBody RazorpayVerifyRequest request) {
        return ResponseEntity.ok(razorpayService.verifyPayment(request));
    }
}
