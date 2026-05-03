package com.resumebuilder.dto;

public class VerifyPaymentResponse {
    private boolean verified;
    private String paymentToken;
    private String message;

    public VerifyPaymentResponse() {}

    public VerifyPaymentResponse(boolean verified, String paymentToken, String message) {
        this.verified = verified;
        this.paymentToken = paymentToken;
        this.message = message;
    }

    public boolean isVerified() { return verified; }
    public void setVerified(boolean verified) { this.verified = verified; }

    public String getPaymentToken() { return paymentToken; }
    public void setPaymentToken(String paymentToken) { this.paymentToken = paymentToken; }

    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }
}
