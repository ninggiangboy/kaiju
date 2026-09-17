# Next is used as an SPA shell (ADR-0008): no Server Actions for business
# mutations, no business data fetching in server components. The Node process
# here only serves marketing pages and the magic-link landing page.

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
