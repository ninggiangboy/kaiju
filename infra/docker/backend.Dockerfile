# ONE image for all four application roles (CON-66).
#
# The role is chosen at startup through KAIJU_ROLE, not by building different
# images. Nothing in here branches on an environment name (CON-67).
#
# The dependency layer is separate from the source layer, so changing code does
# not re-download every dependency.

# ---------- Build stage ----------
FROM eclipse-temurin:26-jdk-alpine AS build
WORKDIR /src

# Copy the declarations first: this layer only rebuilds when dependencies change.
COPY backend/gradle/ gradle/
COPY backend/gradlew backend/settings.gradle.kts backend/build.gradle.kts ./
COPY backend/gradle.properties* ./
RUN ./gradlew --no-daemon dependencies --quiet || true

COPY backend/ .
RUN ./gradlew --no-daemon clean bootJar -x test

# ---------- Runtime stage ----------
FROM eclipse-temurin:26-jre-alpine AS runtime

RUN addgroup -S kaiju && adduser -S kaiju -G kaiju
WORKDIR /app

COPY --from=build --chown=kaiju:kaiju /src/bootstrap/build/libs/*.jar app.jar

USER kaiju
EXPOSE 8080

# The default role is `api`; the other three override it through the environment.
ENV KAIJU_ROLE=api \
    JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75 -XX:+ExitOnOutOfMemoryError"

# The `realtime` role holds long-lived connections, so its shutdown grace period
# must exceed the heartbeat interval - clients need time to see the close and
# reconnect deliberately.
STOPSIGNAL SIGTERM

ENTRYPOINT ["sh", "-c", "exec java -jar app.jar --spring.profiles.active=${KAIJU_ROLE}"]
