package com.resumebuilder.dto;

/**
 * A lightweight, privacy-safe analytics event sent by the app so user actions
 * (app open, enhance, download, payment, …) show up in the server logs.
 * No personal/resume content should be sent here — only an event name and an
 * optional short, non-identifying detail.
 */
public class EventRequest {
    private String event;
    private String detail;
    private String sessionId;
    private String platform;
    private String appVersion;

    public String getEvent() { return event; }
    public void setEvent(String event) { this.event = event; }

    public String getDetail() { return detail; }
    public void setDetail(String detail) { this.detail = detail; }

    public String getSessionId() { return sessionId; }
    public void setSessionId(String sessionId) { this.sessionId = sessionId; }

    public String getPlatform() { return platform; }
    public void setPlatform(String platform) { this.platform = platform; }

    public String getAppVersion() { return appVersion; }
    public void setAppVersion(String appVersion) { this.appVersion = appVersion; }
}
