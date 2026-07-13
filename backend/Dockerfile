# --- Build stage -------------------------------------------------------------
# Use the official Maven + JDK 17 image so we don't depend on a committed Maven
# wrapper (mvnw / .mvn), which isn't in the repo.
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app

# Cache dependencies separately from source for fast incremental builds.
COPY pom.xml ./
RUN mvn -B -q -DskipTests dependency:go-offline

COPY src ./src
RUN mvn -B -q -DskipTests package && cp target/*.jar app.jar

# --- Runtime stage -----------------------------------------------------------
FROM eclipse-temurin:17-jre-jammy AS runtime
WORKDIR /app

# Run as non-root.
RUN groupadd --system spring && useradd --system --gid spring --home /app spring \
 && mkdir -p /app/secrets && chown -R spring:spring /app
USER spring

COPY --from=build --chown=spring:spring /app/app.jar app.jar

ENV JAVA_OPTS="-XX:MaxRAMPercentage=75 -XX:+UseG1GC -Djava.security.egd=file:/dev/./urandom" \
    SERVER_PORT=8080
EXPOSE 8080

# Use the platform-assigned PORT (Railway/Render set it); fall back to 8080.
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD wget -qO- http://127.0.0.1:${PORT:-${SERVER_PORT:-8080}}/api/v1/health || exit 1

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar /app/app.jar"]
