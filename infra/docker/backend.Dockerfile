# MỘT ảnh cho cả bốn vai trò ứng dụng (CON-66).
#
# Vai trò được chọn lúc khởi động bằng KAIJU_ROLE, không bằng ảnh khác nhau.
# Không có nhánh nào trong ảnh này rẽ theo tên môi trường (CON-67).
#
# Tầng phụ thuộc tách khỏi tầng mã nguồn, để sửa code không phải tải lại toàn
# bộ phụ thuộc.

# ---------- Tầng dựng ----------
FROM eclipse-temurin:26-jdk-alpine AS build
WORKDIR /src

# Chỉ chép phần khai báo trước: tầng này chỉ dựng lại khi phụ thuộc đổi.
COPY backend/gradle/ gradle/
COPY backend/gradlew backend/settings.gradle.kts backend/build.gradle.kts ./
COPY backend/gradle.properties* ./
RUN ./gradlew --no-daemon dependencies --quiet || true

COPY backend/ .
RUN ./gradlew --no-daemon clean bootJar -x test

# ---------- Tầng chạy ----------
FROM eclipse-temurin:26-jre-alpine AS runtime

RUN addgroup -S kaiju && adduser -S kaiju -G kaiju
WORKDIR /app

COPY --from=build --chown=kaiju:kaiju /src/bootstrap/build/libs/*.jar app.jar

USER kaiju
EXPOSE 8080

# Vai trò mặc định là `api`; ba vai trò còn lại ghi đè bằng biến môi trường.
ENV KAIJU_ROLE=api \
    JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75 -XX:+ExitOnOutOfMemoryError"

# Vai trò `realtime` giữ kết nối dài hạn, nên thời gian tắt êm phải dài hơn chu
# kỳ nhịp tim — client cần kịp nhận tín hiệu đóng và nối lại chủ động.
STOPSIGNAL SIGTERM

ENTRYPOINT ["sh", "-c", "exec java -jar app.jar --spring.profiles.active=${KAIJU_ROLE}"]
