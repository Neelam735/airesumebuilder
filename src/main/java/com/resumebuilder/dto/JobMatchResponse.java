package com.resumebuilder.dto;

import java.util.List;

public class JobMatchResponse {
    private List<JobMatch> matches;
    private int totalScanned;
    private String source;

    public JobMatchResponse() {}

    public JobMatchResponse(List<JobMatch> matches, int totalScanned, String source) {
        this.matches = matches;
        this.totalScanned = totalScanned;
        this.source = source;
    }

    public List<JobMatch> getMatches() { return matches; }
    public void setMatches(List<JobMatch> matches) { this.matches = matches; }

    public int getTotalScanned() { return totalScanned; }
    public void setTotalScanned(int totalScanned) { this.totalScanned = totalScanned; }

    public String getSource() { return source; }
    public void setSource(String source) { this.source = source; }
}
