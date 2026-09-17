# Every command here runs from a developer machine. No check exists only inside
# a CI configuration file (CON-72).

COMPOSE_MINI := docker compose -f compose/docker-compose.yml
COMPOSE_DEV  := docker compose -f compose/docker-compose.yml -f compose/docker-compose.dev.yml

.DEFAULT_GOAL := help

## --- Tier 1 - local-mini -------------------------------------------------

.PHONY: up
up: ## Tier 1: database, Redis, mail catcher, object storage
	$(COMPOSE_MINI) up -d
	@# --wait is only for long-running services; minio-init runs once and exits.
	$(COMPOSE_MINI) up -d --wait postgres valkey mailpit minio
	@echo "mail:    http://localhost:8025"
	@echo "storage: http://localhost:9001"

.PHONY: down
down: ## Stop tiers 1 and 2, keeping the data
	$(COMPOSE_DEV) down

.PHONY: reset
reset: ## Wipe all data and rebuild tier 1
	$(COMPOSE_DEV) down -v
	$(MAKE) up

.PHONY: logs
logs: ## Follow the logs
	$(COMPOSE_DEV) logs -f

## --- Tier 2 - dev --------------------------------------------------------

.PHONY: up-dev
up-dev: ## Tier 2: adds the pooler, observability, reverse proxy and four roles
	$(COMPOSE_DEV) up -d --build
	$(COMPOSE_DEV) up -d --wait postgres valkey mailpit minio pgbouncer lgtm api realtime worker scheduler caddy
	@echo "app:           http://localhost:8080"
	@echo "observability: http://localhost:3001"
	@echo "mail:          http://localhost:8025"

.PHONY: pooler
pooler: ## Start only the connection pooler, to run the backend outside Docker on 6432
	$(COMPOSE_DEV) up -d --wait postgres pgbouncer

## --- Checks --------------------------------------------------------------

.PHONY: check
check: check-docs check-compose check-k8s check-ci ## Every static check, exactly as CI runs them

.PHONY: check-docs
check-docs: ## Links, heading anchors, the feature table, and no DDL under docs/
	python3 ../.github/scripts/check-docs.py

.PHONY: check-compose
check-compose: ## Syntax of every compose file
	$(COMPOSE_MINI) config -q
	$(COMPOSE_DEV) config -q
	KAIJU_IMAGE=x KAIJU_FRONTEND_IMAGE=x KAIJU_DOMAIN=x \
		KAIJU_ENV_FILE=../env/staging.env.example \
		docker compose -f staging/docker-compose.yml config -q

.PHONY: check-k8s
check-k8s: ## Both overlays build
	kubectl kustomize k8s/overlays/staging  > /dev/null
	kubectl kustomize k8s/overlays/production > /dev/null

.PHONY: check-ci
check-ci: ## CI workflows, reverse proxy configuration, operational scripts
	@command -v actionlint >/dev/null && (cd .. && actionlint) || echo "  (skipped: actionlint not installed)"
	@command -v shellcheck >/dev/null && shellcheck scripts/*.sh || echo "  (skipped: shellcheck not installed)"
	docker run --rm -e KAIJU_DOMAIN=example.com -v "$$PWD/proxy:/w" -w /w caddy:2-alpine \
		sh -c 'caddy validate --config Caddyfile.dev --adapter caddyfile && \
		       caddy validate --config Caddyfile.staging --adapter caddyfile' 2>&1 | tail -1

.PHONY: smoke
smoke: ## Post-deployment checks; defaults to tier 2
	./scripts/smoke.sh $${KAIJU_BASE_URL:-http://localhost:8080}

.PHONY: help
help:
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'
