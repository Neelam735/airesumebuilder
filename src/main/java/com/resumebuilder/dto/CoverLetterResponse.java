package com.resumebuilder.dto;

public class CoverLetterResponse {
    private String coverLetter;

    public CoverLetterResponse() {}

    public CoverLetterResponse(String coverLetter) {
        this.coverLetter = coverLetter;
    }

    public String getCoverLetter() { return coverLetter; }
    public void setCoverLetter(String coverLetter) { this.coverLetter = coverLetter; }
}
