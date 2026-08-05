package com.resumebuilder.dto;

import com.fasterxml.jackson.databind.JsonNode;

public class ResumeParseResponse {
    private JsonNode resume;
    private String message;

    public ResumeParseResponse() {}

    public ResumeParseResponse(JsonNode resume, String message) {
        this.resume = resume;
        this.message = message;
    }

    public JsonNode getResume() { return resume; }
    public void setResume(JsonNode resume) { this.resume = resume; }

    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }
}
