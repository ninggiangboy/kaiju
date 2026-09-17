# Next dùng như SPA shell (ADR-0008): không Server Action cho mutation nghiệp
# vụ, không lấy dữ liệu nghiệp vụ ở server component. Tiến trình Node ở đây chỉ
# phục vụ trang tiếp thị và trang nhận magic link.

FROM node:22-alpine AS deps
WORKDIR /src
COPY frontend/package.json frontend/package-lock.json* ./
RUN npm ci

FROM node:22-alpine AS build
WORKDIR /src
COPY --from=deps /src/node_modules ./node_modules
COPY frontend/ .
RUN npm run build

FROM node:22-alpine AS runtime
WORKDIR /app
RUN addgroup -S kaiju && adduser -S kaiju -G kaiju

COPY --from=build --chown=kaiju:kaiju /src/.next/standalone ./
COPY --from=build --chown=kaiju:kaiju /src/.next/static ./.next/static
COPY --from=build --chown=kaiju:kaiju /src/public ./public

USER kaiju
EXPOSE 3000
ENV PORT=3000 HOSTNAME=0.0.0.0
CMD ["node", "server.js"]
