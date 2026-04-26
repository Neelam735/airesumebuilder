package com.resumebuilder.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.resumebuilder.client.GrokClient;
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

    private final GrokClient grokClient;
    private final PaymentService paymentService;
    private final ObjectMapper mapper = new ObjectMapper();

    public ResumeService(GrokClient grokClient, PaymentService paymentService) {
        this.grokClient = grokClient;
        this.paymentService = paymentService;
    }

    public ResumeParseResponse parseAndImprove(ResumeParseRequest request) {
        if (!paymentService.isTokenValid(request.getPaymentToken())) {
            log.warn("Resume parse blocked: invalid or missing payment token");
            throw new ApiException(HttpStatus.PAYMENT_REQUIRED,
                    "Payment required. Please complete payment to use AI improvement.");
        }

        String text = request.getResumeText();
        if (text == null || text.isBlank()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Resume text is empty");
        }
        if (text.length() > 50_000) {
            text = text.substring(0, 50_000);
        }

        String userPrompt = USER_PROMPT_TEMPLATE.formatted(text);
        String aiContent = grokClient.chatCompletion(SYSTEM_PROMPT, userPrompt);

        JsonNode parsed;
        try {
            parsed = mapper.readTree(aiContent);
        } catch (Exception e) {
            log.error("Failed to parse AI JSON output: {}", aiContent, e);
            throw new ApiException(HttpStatus.BAD_GATEWAY,
                    "AI returned invalid JSON. Please try again.", e);
        }

        paymentService.consumeToken(request.getPaymentToken());
        return new ResumeParseResponse(parsed, "Resume improved successfully");
    }
}
