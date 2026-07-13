# --- Build stage -------------------------------------------------------------
FROM eclipse-temurin:17-jdk-jammy AS build
WORKDIR /app

# Cache deps separately from source for fast incremental builds.
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN if [ -x ./mvnw ]; then chmod +x ./mvnw && ./mvnw -B -q -DskipTests dependency:go-offline; fi

COPY src ./src
RUN if [ -x ./mvnw ]; then ./mvnw -B -q -DskipTests package; \
    else apt-get update && apt-get install -y --no-install-recommends maven \
         && rm -rf /var/lib/apt/lists/* && mvn -B -q -DskipTests package; fi \
 && cp target/*.jar app.jar

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
