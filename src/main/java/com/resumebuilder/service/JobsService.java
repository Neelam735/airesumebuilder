package com.resumebuilder.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.resumebuilder.client.GeminiClient;
import com.resumebuilder.client.RemotiveClient;
import com.resumebuilder.dto.CoverLetterRequest;
import com.resumebuilder.dto.CoverLetterResponse;
import com.resumebuilder.dto.JobMatch;
import com.resumebuilder.dto.JobMatchRequest;
import com.resumebuilder.dto.JobMatchResponse;
import com.resumebuilder.exception.ApiException;
import org.jsoup.Jsoup;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class JobsService {

    private static final Logger log = LoggerFactory.getLogger(JobsService.class);
    private static final int DEFAULT_LIMIT = 12;
    private static final int FETCH_POOL = 50;

    private final RemotiveClient remotiveClient;
    private final GeminiClient geminiClient;

    public JobsService(RemotiveClient remotiveClient, GeminiClient geminiClient) {
        this.remotiveClient = remotiveClient;
        this.geminiClient = geminiClient;
    }

    public JobMatchResponse match(JobMatchRequest request) {
        List<String> rawSkills = request.getSkills() == null ? List.of() : request.getSkills();
        Set<String> normalizedSkills = rawSkills.stream()
                .filter(Objects::nonNull)
                .map(s -> s.toLowerCase(Locale.ROOT).trim())
                .filter(s -> !s.isEmpty())
                .collect(Collectors.toCollection(java.util.LinkedHashSet::new));

        if (normalizedSkills.isEmpty() && (request.getTitle() == null || request.getTitle().isBlank())) {
            throw new ApiException(HttpStatus.BAD_REQUEST,
                    "Add at least one skill or a job title before searching.");
        }

        String search = buildSearchQuery(request.getTitle(), normalizedSkills);
        JsonNode response = remotiveClient.searchJobs(search, null, FETCH_POOL);
        JsonNode jobsNode = response.path("jobs");
        if (!jobsNode.isArray()) {
            return new JobMatchResponse(List.of(), 0, "remotive");
        }

        List<JobMatch> ranked = new ArrayList<>();
        for (JsonNode jobNode : jobsNode) {
            JobMatch match = toJobMatch(jobNode, normalizedSkills);
            if (request.getLocation() != null && !request.getLocation().isBlank()) {
                String want = request.getLocation().toLowerCase(Locale.ROOT);
                String have = match.getLocation() == null ? "" : match.getLocation().toLowerCase(Locale.ROOT);
                if (!have.contains(want) && !have.contains("worldwide") && !have.contains("anywhere")) {
                    continue;
                }
            }
            ranked.add(match);
        }

        ranked.sort(Comparator.comparingDouble(JobMatch::getScore).reversed());
        int limit = request.getLimit() != null && request.getLimit() > 0
                ? Math.min(request.getLimit(), 50)
                : DEFAULT_LIMIT;
        List<JobMatch> trimmed = ranked.stream().limit(limit).toList();

        log.info("Job match: skills={} fetched={} returned={}",
                normalizedSkills, jobsNode.size(), trimmed.size());
        return new JobMatchResponse(trimmed, jobsNode.size(), "remotive");
    }

    public CoverLetterResponse draftCoverLetter(CoverLetterRequest request) {
        if (request.getJobTitle() == null || request.getJobTitle().isBlank()
                || request.getCompany() == null || request.getCompany().isBlank()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "jobTitle and company are required");
        }
        String name = nullSafe(request.getName(), "the candidate");
        String title = nullSafe(request.getTitle(), "");
        String summary = nullSafe(request.getSummary(), "");
        String skills = request.getSkills() == null ? "" : String.join(", ", request.getSkills());
        String jobDesc = truncate(nullSafe(request.getJobDescription(), ""), 4000);

        String system = """
                You are a recruiter-grade cover-letter writer. You write concise, sincere,
                modern cover letters in plain text (no markdown, no bullet points).
                Hard rules:
                  - Three short paragraphs. Maximum 200 words total.
                  - Reference 1–2 concrete skills the candidate actually has, mapped to
                    1–2 needs in the job description.
                  - Do NOT invent experience, employers, or numbers.
                  - End with a single short closing line. No "Sincerely" / no signature.
                  - First line: "Dear Hiring Team,"
                """;

        String user = """
                Candidate name: %s
                Candidate current title: %s
                Candidate summary: %s
                Candidate skills: %s

                Target role: %s at %s
                Job description (may be truncated):
                \"\"\"
                %s
                \"\"\"
                """.formatted(name, title, summary, skills, request.getJobTitle(), request.getCompany(), jobDesc);

        String letter = geminiClient.generateContent(system, user);
        return new CoverLetterResponse(letter == null ? "" : letter.trim());
    }

    private JobMatch toJobMatch(JsonNode node, Set<String> userSkills) {
        JobMatch m = new JobMatch();
        m.setId(node.path("id").asText());
        m.setTitle(node.path("title").asText());
        m.setCompany(node.path("company_name").asText());
        m.setLocation(node.path("candidate_required_location").asText());
        m.setJobType(node.path("job_type").asText());
        m.setSalary(node.path("salary").asText());
        m.setUrl(node.path("url").asText());
        m.setPublishedAt(node.path("publication_date").asText());

        List<String> tags = new ArrayList<>();
        JsonNode tagsNode = node.path("tags");
        if (tagsNode.isArray()) {
            for (JsonNode t : tagsNode) tags.add(t.asText());
        }
        m.setTags(tags);

        String descriptionHtml = node.path("description").asText("");
        String descriptionText = Jsoup.parse(descriptionHtml).text();
        m.setSnippet(truncate(descriptionText, 280));

        ScoreResult score = scoreJob(m.getTitle(), tags, descriptionText, userSkills);
        m.setScore(score.value);
        m.setMatchedSkills(score.matched);
        return m;
    }

    private ScoreResult scoreJob(String title, List<String> tags, String description, Set<String> userSkills) {
        if (userSkills.isEmpty()) {
            return new ScoreResult(0.0, List.of());
        }
        String titleLower = title == null ? "" : title.toLowerCase(Locale.ROOT);
        String descLower = description == null ? "" : description.toLowerCase(Locale.ROOT);
        Set<String> tagSet = new HashSet<>();
        for (String tag : tags) tagSet.add(tag.toLowerCase(Locale.ROOT));

        double score = 0;
        List<String> matched = new ArrayList<>();
        for (String skill : userSkills) {
            boolean inTags = tagSet.contains(skill);
            boolean inTitle = titleLower.contains(skill);
            boolean inDesc = descLower.contains(skill);
            if (!(inTags || inTitle || inDesc)) continue;

            matched.add(skill);
            if (inTags) score += 3;
            if (inTitle) score += 2;
            if (inDesc) score += 1;
        }
        double normalized = Math.min(100, (score / (userSkills.size() * 3.0)) * 100);
        return new ScoreResult(normalized, matched);
    }

    private String buildSearchQuery(String title, Set<String> skills) {
        if (title != null && !title.isBlank()) return title.trim();
        if (skills.isEmpty()) return "developer";
        return skills.iterator().next();
    }

    private static String truncate(String s, int n) {
        if (s == null) return "";
        return s.length() <= n ? s : s.substring(0, n).trim() + "…";
    }

    private static String nullSafe(String s, String fallback) {
        return s == null || s.isBlank() ? fallback : s;
    }

    private record ScoreResult(double value, List<String> matched) {}
}
