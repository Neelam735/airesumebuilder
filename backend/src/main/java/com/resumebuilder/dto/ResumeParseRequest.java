package com.resumebuilder.dto;

public class ResumeParseRequest {
    private String paymentToken;
    private String resumeText;

    public String getPaymentToken() { return paymentToken; }
    public void setPaymentToken(String paymentToken) { this.paymentToken = paymentToken; }

    public String getResumeText() { return resumeText; }
    public void setResumeText(String resumeText) { this.resumeText = resumeText; }
}
