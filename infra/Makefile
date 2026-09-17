# Mỗi lệnh ở đây chạy được từ máy cá nhân. Không có lệnh nào chỉ tồn tại bên
# trong tệp cấu hình CI (CON-72).

COMPOSE_MINI := docker compose -f compose/docker-compose.yml
COMPOSE_DEV  := docker compose -f compose/docker-compose.yml -f compose/docker-compose.dev.yml

.DEFAULT_GOAL := help

## --- Bậc 1 — local-mini --------------------------------------------------

.PHONY: up
up: ## Bậc 1: cơ sở dữ liệu, Redis, bộ bắt email, lưu trữ đối tượng
	$(COMPOSE_MINI) up -d
	@# --wait chỉ dành cho dịch vụ chạy dài; minio-init là việc một lần và thoát.
	$(COMPOSE_MINI) up -d --wait postgres valkey mailpit minio
	@echo "thư:    http://localhost:8025"
	@echo "lưu trữ: http://localhost:9001"

.PHONY: down
down: ## Dừng bậc 1 và bậc 2, giữ nguyên dữ liệu
	$(COMPOSE_DEV) down

.PHONY: reset
reset: ## Xoá sạch dữ liệu và dựng lại bậc 1
	$(COMPOSE_DEV) down -v
	$(MAKE) up

.PHONY: logs
logs: ## Theo dõi nhật ký
	$(COMPOSE_DEV) logs -f

## --- Bậc 2 — dev ---------------------------------------------------------

.PHONY: up-dev
up-dev: ## Bậc 2: thêm bộ gộp kết nối, hệ thống quan sát, máy chủ trung gian, bốn vai trò
	$(COMPOSE_DEV) up -d --build
	$(COMPOSE_DEV) up -d --wait postgres valkey mailpit minio pgbouncer lgtm api realtime worker scheduler caddy
	@echo "ứng dụng: http://localhost:8080"
	@echo "quan sát:  http://localhost:3001"
	@echo "thư:      http://localhost:8025"

.PHONY: pooler
pooler: ## Chỉ bật bộ gộp kết nối, để chạy backend ngoài Docker qua cổng 6432
	$(COMPOSE_DEV) up -d --wait postgres pgbouncer

## --- Kiểm tra ------------------------------------------------------------

.PHONY: check
check: check-docs check-compose check-k8s ## Toàn bộ kiểm tra tĩnh, giống hệt CI

.PHONY: check-docs
check-docs: ## Liên kết, neo tiêu đề, bảng feature, không có DDL trong docs/
	python3 ../.github/scripts/check-docs.py

.PHONY: check-compose
check-compose: ## Cú pháp mọi tệp compose
	$(COMPOSE_MINI) config -q
	$(COMPOSE_DEV) config -q
	KAIJU_IMAGE=x KAIJU_FRONTEND_IMAGE=x KAIJU_DOMAIN=x \
		KAIJU_ENV_FILE=../env/staging.env.example \
		docker compose -f staging/docker-compose.yml config -q

.PHONY: check-k8s
check-k8s: ## Bản kê khai của cả hai lớp phủ dựng được
	kubectl kustomize k8s/overlays/staging  > /dev/null
	kubectl kustomize k8s/overlays/production > /dev/null

.PHONY: smoke
smoke: ## Kiểm tra sau triển khai, mặc định chạy với bậc 2
	./scripts/smoke.sh $${KAIJU_BASE_URL:-http://localhost:8080}

.PHONY: help
help:
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'
