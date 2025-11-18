.PHONY: help dev build test lint clean install docker-up docker-down k8s-apply k8s-delete

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Install all dependencies
	pnpm install

dev: ## Start all services in development mode
	pnpm dev

build: ## Build all services
	pnpm build

test: ## Run all tests
	pnpm test

lint: ## Run linter
	pnpm lint

clean: ## Clean all build artifacts
	pnpm clean
	rm -rf node_modules
	rm -rf .turbo

docker-up: ## Start Docker Compose services
	docker compose up -d

docker-down: ## Stop Docker Compose services
	docker compose down

docker-logs: ## View Docker Compose logs
	docker compose logs -f

k8s-apply: ## Apply Kubernetes manifests
	kubectl apply -f infrastructure/kubernetes/

k8s-delete: ## Delete Kubernetes resources
	kubectl delete -f infrastructure/kubernetes/

