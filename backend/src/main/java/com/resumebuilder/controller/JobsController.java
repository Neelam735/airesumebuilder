package com.resumebuilder.controller;

import com.resumebuilder.dto.CoverLetterRequest;
import com.resumebuilder.dto.CoverLetterResponse;
import com.resumebuilder.dto.JobMatchRequest;
import com.resumebuilder.dto.JobMatchResponse;
import com.resumebuilder.service.JobsService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/jobs")
public class JobsController {

    private final JobsService jobsService;

    public JobsController(JobsService jobsService) {
        this.jobsService = jobsService;
    }

    @PostMapping("/match")
    public ResponseEntity<JobMatchResponse> match(@RequestBody JobMatchRequest request) {
        return ResponseEntity.ok(jobsService.match(request));
    }

    @PostMapping("/cover-letter")
    public ResponseEntity<CoverLetterResponse> coverLetter(@RequestBody CoverLetterRequest request) {
        return ResponseEntity.ok(jobsService.draftCoverLetter(request));
    }
}
