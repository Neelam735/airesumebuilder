package com.resumebuilder;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

@SpringBootApplication
@ConfigurationPropertiesScan(basePackages = "com.resumebuilder.config")
public class ResumeBuilderApplication {
    public static void main(String[] args) {
        SpringApplication.run(ResumeBuilderApplication.class, args);
    }
}
