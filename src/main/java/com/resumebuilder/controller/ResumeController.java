package com.resumebuilder.controller;

import com.resumebuilder.dto.ResumeParseRequest;
import com.resumebuilder.dto.ResumeParseResponse;
import com.resumebuilder.service.ResumeService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/resume")
public class ResumeController {

    private final ResumeService resumeService;

    public ResumeController(ResumeService resumeService) {
        this.resumeService = resumeService;
    }

    @PostMapping("/parse")
    public ResponseEntity<ResumeParseResponse> parse(@RequestBody ResumeParseRequest request) {
        return ResponseEntity.ok(resumeService.parseAndImprove(request));
    }
}
