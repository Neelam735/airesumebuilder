package com.resumebuilder.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "google-play")
public class GooglePlayProperties {
    /** Android package name registered in Play Console. */
    private String packageName;

    /** Product id of the consumable in-app product (e.g. ai_resume_improvement). */
    private String productId;

    /** Either an absolute file path to the service-account JSON OR the JSON itself. */
    private String serviceAccountJson;

    /** Server-side signing secret used to mint payment tokens after a verified purchase. */
    private String tokenSigningKey;

    public String getPackageName() { return packageName; }
    public void setPackageName(String packageName) { this.packageName = packageName; }

    public String getProductId() { return productId; }
    public void setProductId(String productId) { this.productId = productId; }

    public String getServiceAccountJson() { return serviceAccountJson; }
    public void setServiceAccountJson(String serviceAccountJson) { this.serviceAccountJson = serviceAccountJson; }

    public String getTokenSigningKey() { return tokenSigningKey; }
    public void setTokenSigningKey(String tokenSigningKey) { this.tokenSigningKey = tokenSigningKey; }
}
