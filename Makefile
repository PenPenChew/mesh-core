# Mesh Network Project Makefile
# Comprehensive build, test, and development automation

.PHONY: help build test clean lint fmt doc install dev release
.PHONY: test-unit test-integration test-reliability test-tls test-all
.PHONY: check check-all clippy audit security
.PHONY: certs certs-localhost certs-test clean-certs
.PHONY: run-listener run-connector run-tls-listener run-tls-connector
.PHONY: bench profile flamegraph coverage
.PHONY: docker docker-build docker-run docker-clean
.PHONY: deps deps-update deps-tree deps-licenses
.PHONY: workspace-check workspace-update workspace-clean

# Default target
.DEFAULT_GOAL := help

# Project configuration
PROJECT_NAME := mesh
RUST_VERSION := $(shell rustc --version | cut -d' ' -f2)
CARGO_VERSION := $(shell cargo --version | cut -d' ' -f2)
BUILD_DATE := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
GIT_COMMIT := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

# Build configuration
CARGO_FLAGS := --workspace
RELEASE_FLAGS := --release
TEST_FLAGS := --workspace --all-features
CLIPPY_FLAGS := --workspace --all-targets --all-features -- -D warnings
DOC_FLAGS := --workspace --all-features --no-deps

# Feature flags
DEFAULT_FEATURES := tls
ALL_FEATURES := --all-features
TLS_FEATURES := --features tls

# Directories
BUILD_DIR := target
DOCS_DIR := target/doc
COVERAGE_DIR := target/coverage
CERTS_DIR := certs

# Colors for output
RED := \033[31m
GREEN := \033[32m
YELLOW := \033[33m
BLUE := \033[34m
MAGENTA := \033[35m
CYAN := \033[36m
RESET := \033[0m

# Help target
help: ## Show this help message
	@echo "$(CYAN)Mesh Network Project - Development Makefile$(RESET)"
	@echo ""
	@echo "$(YELLOW)Project Info:$(RESET)"
	@echo "  Name:        $(PROJECT_NAME)"
	@echo "  Rust:        $(RUST_VERSION)"
	@echo "  Cargo:       $(CARGO_VERSION)"
	@echo "  Git Commit:  $(GIT_COMMIT)"
	@echo "  Git Branch:  $(GIT_BRANCH)"
	@echo "  Build Date:  $(BUILD_DATE)"
	@echo ""
	@echo "$(YELLOW)Available targets:$(RESET)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-20s$(RESET) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Build targets
build: ## Build the project in debug mode with default features (tls)
	@echo "$(BLUE)Building project in debug mode with TLS...$(RESET)"
	cargo build $(CARGO_FLAGS) $(TLS_FEATURES)

build-minimal: ## Build the project in debug mode without features
	@echo "$(BLUE)Building project in debug mode (minimal)...$(RESET)"
	cargo build $(CARGO_FLAGS)

build-all: ## Build the project in debug mode with all features
	@echo "$(BLUE)Building project in debug mode with all features...$(RESET)"
	cargo build $(CARGO_FLAGS) $(ALL_FEATURES)

release: ## Build the project in release mode with default features (tls)
	@echo "$(BLUE)Building project in release mode with TLS...$(RESET)"
	cargo build $(CARGO_FLAGS) $(RELEASE_FLAGS) $(TLS_FEATURES)

release-minimal: ## Build the project in release mode without features
	@echo "$(BLUE)Building project in release mode (minimal)...$(RESET)"
	cargo build $(CARGO_FLAGS) $(RELEASE_FLAGS)

release-all: ## Build the project in release mode with all features
	@echo "$(BLUE)Building project in release mode with all features...$(RESET)"
	cargo build $(CARGO_FLAGS) $(RELEASE_FLAGS) $(ALL_FEATURES)

install: ## Install the mesh binary with TLS support
	@echo "$(BLUE)Installing mesh binary with TLS...$(RESET)"
	cargo install --path mesh-bin --force $(TLS_FEATURES)

install-minimal: ## Install the mesh binary without features
	@echo "$(BLUE)Installing mesh binary (minimal)...$(RESET)"
	cargo install --path mesh-bin --force

dev: ## Build for development with all features
	@echo "$(BLUE)Building for development...$(RESET)"
	cargo build $(CARGO_FLAGS) --all-features

# Test targets
test: test-unit ## Run unit tests (default)

test-unit: ## Run unit tests
	@echo "$(BLUE)Running unit tests...$(RESET)"
	cargo test $(TEST_FLAGS)

test-integration: ## Run integration tests
	@echo "$(BLUE)Running integration tests...$(RESET)"
	cargo test $(TEST_FLAGS) --test '*'

test-reliability: build ## Test reliability features
	@echo "$(BLUE)Testing reliability features...$(RESET)"
	./tests/test_reliability.sh

test-tls: build certs-localhost ## Test TLS functionality
	@echo "$(BLUE)Testing TLS functionality...$(RESET)"
	./tests/test_tls_mvp.sh

test-all: test-unit test-integration test-reliability test-tls ## Run all tests

# Code quality targets
check: ## Run cargo check
	@echo "$(BLUE)Running cargo check...$(RESET)"
	cargo check $(CARGO_FLAGS)

check-all: ## Run cargo check with all features
	@echo "$(BLUE)Running cargo check with all features...$(RESET)"
	cargo check $(CARGO_FLAGS) --all-features

clippy: ## Run clippy linter
	@echo "$(BLUE)Running clippy...$(RESET)"
	cargo clippy $(CLIPPY_FLAGS)

fmt: ## Format code with rustfmt
	@echo "$(BLUE)Formatting code...$(RESET)"
	cargo fmt --all

lint: fmt clippy ## Run all linting tools

audit: ## Run security audit
	@echo "$(BLUE)Running security audit...$(RESET)"
	cargo audit

security: audit ## Alias for audit

# Documentation targets
doc: ## Generate documentation
	@echo "$(BLUE)Generating documentation...$(RESET)"
	cargo doc $(DOC_FLAGS)

doc-open: doc ## Generate and open documentation
	@echo "$(BLUE)Opening documentation...$(RESET)"
	cargo doc $(DOC_FLAGS) --open

# Certificate management
certs: certs-test ## Generate test certificates (default)

certs-test: ## Generate test certificates for nodes
	@echo "$(BLUE)Generating test certificates...$(RESET)"
	./generate_test_certs.sh

certs-localhost: ## Generate localhost certificates for local testing
	@echo "$(BLUE)Generating localhost certificates...$(RESET)"
	./generate_localhost_certs.sh

clean-certs: ## Clean up certificate files
	@echo "$(YELLOW)Cleaning certificate files...$(RESET)"
	rm -rf $(CERTS_DIR) $(CERTS_DIR)

# Development server targets
run-listener: build-minimal ## Run mesh node as listener (plain TCP)
	@echo "$(BLUE)Starting mesh listener on 127.0.0.1:9000...$(RESET)"
	./target/debug/mesh --node-id 1001 --listen 127.0.0.1:9000 --log-level info

run-connector: build-minimal ## Run mesh node as connector (plain TCP)
	@echo "$(BLUE)Starting mesh connector to 127.0.0.1:9000...$(RESET)"
	./target/debug/mesh --node-id 2002 --connect 127.0.0.1:9000 --log-level info

run-tls-listener: build certs-localhost ## Run mesh node as TLS listener
	@echo "$(BLUE)Starting mesh TLS listener on 127.0.0.1:9000...$(RESET)"
	./target/debug/mesh --node-id 1001 --listen 127.0.0.1:9000 --log-level info \
		--tls --tls-cert $(CERTS_DIR)/node-1001.crt \
		--tls-key $(CERTS_DIR)/node-1001.key \
		--tls-ca $(CERTS_DIR)/ca.crt

run-tls-connector: build certs-localhost ## Run mesh node as TLS connector
	@echo "$(BLUE)Starting mesh TLS connector to 127.0.0.1:9000...$(RESET)"
	./target/debug/mesh --node-id 2002 --connect 127.0.0.1:9000 --log-level info \
		--tls --tls-cert $(CERTS_DIR)/node-2002.crt \
		--tls-key $(CERTS_DIR)/node-2002.key \
		--tls-ca $(CERTS_DIR)/ca.crt --tls-sni localhost

# Performance and profiling
bench: ## Run benchmarks
	@echo "$(BLUE)Running benchmarks...$(RESET)"
	cargo bench $(CARGO_FLAGS)

profile: release ## Build with profiling symbols
	@echo "$(BLUE)Building with profiling...$(RESET)"
	RUSTFLAGS="-g" cargo build $(CARGO_FLAGS) $(RELEASE_FLAGS)

flamegraph: ## Generate flamegraph (requires flamegraph tool)
	@echo "$(BLUE)Generating flamegraph...$(RESET)"
	@if ! command -v flamegraph >/dev/null 2>&1; then \
		echo "$(RED)Error: flamegraph not installed. Run: cargo install flamegraph$(RESET)"; \
		exit 1; \
	fi
	flamegraph --output flamegraph.svg -- ./target/release/mesh --help

coverage: ## Generate code coverage report (requires tarpaulin)
	@echo "$(BLUE)Generating coverage report...$(RESET)"
	@if ! command -v cargo-tarpaulin >/dev/null 2>&1; then \
		echo "$(RED)Error: tarpaulin not installed. Run: cargo install cargo-tarpaulin$(RESET)"; \
		exit 1; \
	fi
	mkdir -p $(COVERAGE_DIR)
	cargo tarpaulin --out Html --output-dir $(COVERAGE_DIR) $(TEST_FLAGS)
	@echo "$(GREEN)Coverage report generated in $(COVERAGE_DIR)/tarpaulin-report.html$(RESET)"

# Docker targets
docker-build: ## Build Docker image
	@echo "$(BLUE)Building Docker image...$(RESET)"
	docker build -t $(PROJECT_NAME):latest .

docker-run: docker-build ## Run Docker container
	@echo "$(BLUE)Running Docker container...$(RESET)"
	docker run --rm -p 9000:9000 $(PROJECT_NAME):latest

docker-clean: ## Clean Docker images and containers
	@echo "$(YELLOW)Cleaning Docker images...$(RESET)"
	docker rmi $(PROJECT_NAME):latest 2>/dev/null || true
	docker system prune -f

# Dependency management
deps: ## Show dependency tree
	@echo "$(BLUE)Dependency tree:$(RESET)"
	cargo tree

deps-update: ## Update dependencies
	@echo "$(BLUE)Updating dependencies...$(RESET)"
	cargo update

deps-tree: ## Show detailed dependency tree
	@echo "$(BLUE)Detailed dependency tree:$(RESET)"
	cargo tree --all-features -e all

deps-licenses: ## Show dependency licenses (requires cargo-license)
	@echo "$(BLUE)Dependency licenses:$(RESET)"
	@if ! command -v cargo-license >/dev/null 2>&1; then \
		echo "$(RED)Error: cargo-license not installed. Run: cargo install cargo-license$(RESET)"; \
		exit 1; \
	fi
	cargo license

# Workspace management
workspace-check: ## Check all workspace members
	@echo "$(BLUE)Checking workspace members...$(RESET)"
	@for crate in mesh-wire mesh-crypto mesh-storage mesh-session mesh-routing \
	              mesh-topology mesh-grpc mesh-config mesh-observe mesh-bin; do \
		echo "$(CYAN)Checking $$crate...$(RESET)"; \
		cargo check -p $$crate || exit 1; \
	done

workspace-update: ## Update all workspace members
	@echo "$(BLUE)Updating workspace...$(RESET)"
	cargo update --workspace

workspace-clean: ## Clean all workspace build artifacts
	@echo "$(YELLOW)Cleaning workspace...$(RESET)"
	cargo clean

# Clean targets
clean: ## Clean build artifacts
	@echo "$(YELLOW)Cleaning build artifacts...$(RESET)"
	cargo clean

clean-all: clean clean-certs ## Clean everything (build artifacts and certificates)
	@echo "$(YELLOW)Cleaning all generated files...$(RESET)"
	rm -rf $(COVERAGE_DIR)
	rm -f flamegraph.svg
	rm -rf meshdata_test_*

# CI/CD targets
ci-check: fmt clippy check-all test-unit ## Run CI checks (formatting, linting, tests)

ci-test: test-all ## Run all tests for CI

ci-build: release ## Build release for CI

ci-full: ci-check ci-test ci-build ## Run full CI pipeline

# Development workflow
dev-setup: ## Set up development environment
	@echo "$(BLUE)Setting up development environment...$(RESET)"
	@echo "$(CYAN)Installing required tools...$(RESET)"
	cargo install cargo-audit cargo-tarpaulin cargo-license flamegraph
	@echo "$(GREEN)Development environment ready!$(RESET)"

dev-check: fmt clippy test-unit ## Quick development check (format, lint, test)

dev-full: clean build test-all lint doc ## Full development build and test

# Release preparation
pre-release: clean ci-full doc ## Prepare for release (full CI + docs)
	@echo "$(GREEN)Pre-release checks completed successfully!$(RESET)"

# Information targets
info: ## Show project information
	@echo "$(CYAN)Project Information:$(RESET)"
	@echo "  Name:           $(PROJECT_NAME)"
	@echo "  Rust Version:   $(RUST_VERSION)"
	@echo "  Cargo Version:  $(CARGO_VERSION)"
	@echo "  Git Commit:     $(GIT_COMMIT)"
	@echo "  Git Branch:     $(GIT_BRANCH)"
	@echo "  Build Date:     $(BUILD_DATE)"
	@echo ""
	@echo "$(CYAN)Workspace Crates:$(RESET)"
	@cargo metadata --format-version 1 | jq -r '.workspace_members[]' | sed 's/.*#/  /'

status: ## Show git and build status
	@echo "$(CYAN)Git Status:$(RESET)"
	@git status --porcelain || echo "  Not a git repository"
	@echo ""
	@echo "$(CYAN)Build Status:$(RESET)"
	@if [ -f "$(BUILD_DIR)/debug/mesh" ]; then \
		echo "  Debug build:   $(GREEN)✓$(RESET)"; \
	else \
		echo "  Debug build:   $(RED)✗$(RESET)"; \
	fi
	@if [ -f "$(BUILD_DIR)/release/mesh" ]; then \
		echo "  Release build: $(GREEN)✓$(RESET)"; \
	else \
		echo "  Release build: $(RED)✗$(RESET)"; \
	fi

# Feature-specific targets
build-tls: build ## Alias for build (with TLS)

run-release-tls-listener: release certs-localhost ## Run release TLS listener
	@echo "$(BLUE)Starting release mesh TLS listener on 127.0.0.1:9000...$(RESET)"
	./target/release/mesh --node-id 1001 --listen 127.0.0.1:9000 --log-level info \
		--tls --tls-cert $(CERTS_DIR)/node-1001.crt \
		--tls-key $(CERTS_DIR)/node-1001.key \
		--tls-ca $(CERTS_DIR)/ca.crt

run-release-tls-connector: release certs-localhost ## Run release TLS connector
	@echo "$(BLUE)Starting release mesh TLS connector to 127.0.0.1:9000...$(RESET)"
	./target/release/mesh --node-id 2002 --connect 127.0.0.1:9000 --log-level info \
		--tls --tls-cert $(CERTS_DIR)/node-2002.crt \
		--tls-key $(CERTS_DIR)/node-2002.key \
		--tls-ca $(CERTS_DIR)/ca.crt --tls-sni localhost

# Quick aliases
b: build ## Alias for build
t: test ## Alias for test
c: check ## Alias for check
r: release ## Alias for release
d: doc ## Alias for doc
f: fmt ## Alias for fmt
l: lint ## Alias for lint
