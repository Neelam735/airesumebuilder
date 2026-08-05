package com.resumebuilder.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.resumebuilder.client.GeminiClient;
import com.resumebuilder.dto.ResumeParseRequest;
import com.resumebuilder.dto.ResumeParseResponse;
import com.resumebuilder.exception.ApiException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

@Service
public class ResumeService {

    private static final Logger log = LoggerFactory.getLogger(ResumeService.class);

    private static final String SYSTEM_PROMPT = """
            You are an expert resume editor. Convert the user's raw resume text
            into structured JSON and improve it professionally.
            Rules:
              - Fix grammar and clarity
              - Use strong action verbs
              - Keep bullet points concise
              - Do NOT add fake information
              - Keep it realistic and professional
            Return ONLY valid JSON in the exact schema provided.
            """;

    private static final String USER_PROMPT_TEMPLATE = """
            Convert the following resume text into structured JSON and improve it professionally.

            Return ONLY valid JSON in this exact shape:
            {
              "name": "",
              "title": "",
              "email": "",
              "phone": "",
              "location": "",
              "linkedin": "",
              "summary": "",
              "skills": [],
              "experience": [
                { "role": "", "company": "", "duration": "", "description": "" }
              ],
              "education": [
                { "degree": "", "institution": "", "duration": "", "description": "" }
              ],
              "projects": [
                { "name": "", "description": "", "link": "" }
              ],
              "languages": []
            }

            Resume Text:
            \"\"\"
            %s
            \"\"\"
            """;

    private final GeminiClient geminiClient;
    private final ObjectMapper mapper = new ObjectMapper();

    public ResumeService(GeminiClient geminiClient) {
        this.geminiClient = geminiClient;
    }

    public ResumeParseResponse parseAndImprove(ResumeParseRequest request) {
        String text = request.getResumeText();
        if (text == null || text.isBlank()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Resume text is empty");
        }
        if (text.length() > 50_000) {
            text = text.substring(0, 50_000);
        }

        String userPrompt = USER_PROMPT_TEMPLATE.formatted(text);
        String aiContent = geminiClient.generateContent(SYSTEM_PROMPT, userPrompt);
        String cleaned = extractJsonBlock(aiContent);

        JsonNode parsed;
        try {
            parsed = mapper.readTree(cleaned);
        } catch (Exception e) {
            log.error("Failed to parse AI JSON output. raw=<{}> cleaned=<{}>", aiContent, cleaned, e);
            throw new ApiException(HttpStatus.BAD_GATEWAY,
                    "AI returned invalid JSON. Please try again.", e);
        }

        return new ResumeParseResponse(parsed, "Resume improved successfully");
    }

    private String extractJsonBlock(String content) {
        if (content == null) return "";
        String trimmed = content.trim();
        if (trimmed.startsWith("```")) {
            int firstNewline = trimmed.indexOf('\n');
            if (firstNewline > 0) trimmed = trimmed.substring(firstNewline + 1);
            int closingFence = trimmed.lastIndexOf("```");
            if (closingFence >= 0) trimmed = trimmed.substring(0, closingFence);
            trimmed = trimmed.trim();
        }
        int firstBrace = trimmed.indexOf('{');
        int lastBrace = trimmed.lastIndexOf('}');
        if (firstBrace >= 0 && lastBrace > firstBrace) {
            return trimmed.substring(firstBrace, lastBrace + 1);
        }
        return trimmed;
    }
}
