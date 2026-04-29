package com.resumebuilder.dto;

public class VerifyPaymentRequest {
    private String productId;
    private String purchaseToken;

    public String getProductId() { return productId; }
    public void setProductId(String productId) { this.productId = productId; }

    public String getPurchaseToken() { return purchaseToken; }
    public void setPurchaseToken(String purchaseToken) { this.purchaseToken = purchaseToken; }
}
