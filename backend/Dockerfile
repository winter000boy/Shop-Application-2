# ---- Build stage: compile and package the Spring Boot jar ----
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
# Download dependencies first so they are cached between builds when only source code changes
COPY pom.xml .
RUN mvn -q dependency:go-offline
COPY src ./src
RUN mvn -q package -DskipTests

# ---- Run stage: small image with just the JRE and the jar ----
FROM eclipse-temurin:17-jre
WORKDIR /app
RUN useradd --system --uid 1001 appuser
COPY --from=build /app/target/backend-*.jar app.jar
USER appuser
ENV SPRING_PROFILES_ACTIVE=prod
EXPOSE 8080
# Fit the JVM into small (512 MB) containers
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75", "-jar", "/app/app.jar"]
