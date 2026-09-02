package com.resumebuilder.dto;

/**
 * Everything the app needs to open the Razorpay checkout sheet.
 * Deliberately carries the public key id only — never the key secret.
 */
public class RazorpayOrderResponse {
    private String orderId;
    private int amount;
    private String currency;
    private String keyId;
    private String companyName;
    private String description;

    public RazorpayOrderResponse() {}

    public RazorpayOrderResponse(String orderId, int amount, String currency,
                                 String keyId, String companyName, String description) {
        this.orderId = orderId;
        this.amount = amount;
        this.currency = currency;
        this.keyId = keyId;
        this.companyName = companyName;
        this.description = description;
    }

    public String getOrderId() { return orderId; }
    public void setOrderId(String orderId) { this.orderId = orderId; }

    public int getAmount() { return amount; }
    public void setAmount(int amount) { this.amount = amount; }

    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }

    public String getKeyId() { return keyId; }
    public void setKeyId(String keyId) { this.keyId = keyId; }

    public String getCompanyName() { return companyName; }
    public void setCompanyName(String companyName) { this.companyName = companyName; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
}
