package com.resumebuilder.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Razorpay checkout configuration.
 *
 * The key secret is used only on the server: it authenticates order creation
 * and verifies the payment signature. It must never be shipped to the app —
 * only {@link #getKeyId()} is sent to the client.
 */
@ConfigurationProperties(prefix = "razorpay")
public class RazorpayProperties {

    /** Razorpay Key Id (public — safe to send to the app, e.g. rzp_test_xxx). */
    private String keyId;

    /** Razorpay Key Secret (SERVER ONLY — never expose to the client). */
    private String keySecret;

    /** Amount charged for one AI-enhanced download, in the currency's smallest unit (paise). */
    private int amount = 2900;

    /** ISO currency code for the charge. */
    private String currency = "INR";

    /** Name shown on the Razorpay checkout sheet. */
    private String companyName = "AI Resume Builder";

    /** Description shown on the Razorpay checkout sheet. */
    private String description = "AI-enhanced resume download";

    /** True when both key id and secret are present, so checkout can be offered. */
    public boolean isConfigured() {
        return keyId != null && !keyId.isBlank()
                && keySecret != null && !keySecret.isBlank();
    }

    public String getKeyId() { return keyId; }
    public void setKeyId(String keyId) { this.keyId = keyId; }

    public String getKeySecret() { return keySecret; }
    public void setKeySecret(String keySecret) { this.keySecret = keySecret; }

    public int getAmount() { return amount; }
    public void setAmount(int amount) { this.amount = amount; }

    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }

    public String getCompanyName() { return companyName; }
    public void setCompanyName(String companyName) { this.companyName = companyName; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
}
