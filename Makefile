# pia-wg-config Makefile

# Variables
BINARY_NAME=pia-wg-config
BINARY_PATH=./$(BINARY_NAME)
MAIN_PACKAGE=.
VERSION=$(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
LDFLAGS=-ldflags "-X main.version=$(VERSION)"

# Docker variables
DOCKER_IMAGE=pia-wg-config
DOCKER_TAG=$(VERSION)
DOCKER_LATEST=latest
DOCKERFILE_PATH=docker/Dockerfile

# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOTEST=$(GOCMD) test
GOGET=$(GOCMD) get
GOMOD=$(GOCMD) mod
GOFMT=gofmt
GOLINT=golint
GOVET=$(GOCMD) vet

# Build targets
.PHONY: all build clean test coverage lint fmt vet check install uninstall deps tidy help docker-build docker-build-multiarch docker-build-no-cache docker-clean clean-all

# Default target
all: check build

# Build the binary
build:
	@echo "Building $(BINARY_NAME)..."
	$(GOBUILD) $(LDFLAGS) -o $(BINARY_PATH) $(MAIN_PACKAGE)
	@echo "✓ Build complete: $(BINARY_PATH)"

# Build for multiple platforms
build-all: build-linux build-darwin build-windows

build-linux:
	@echo "Building for Linux..."
	GOOS=linux GOARCH=amd64 $(GOBUILD) $(LDFLAGS) -o $(BINARY_NAME)-linux-amd64 $(MAIN_PACKAGE)
	GOOS=linux GOARCH=arm64 $(GOBUILD) $(LDFLAGS) -o $(BINARY_NAME)-linux-arm64 $(MAIN_PACKAGE)

build-darwin:
	@echo "Building for macOS..."
	GOOS=darwin GOARCH=amd64 $(GOBUILD) $(LDFLAGS) -o $(BINARY_NAME)-darwin-amd64 $(MAIN_PACKAGE)
	GOOS=darwin GOARCH=arm64 $(GOBUILD) $(LDFLAGS) -o $(BINARY_NAME)-darwin-arm64 $(MAIN_PACKAGE)

build-windows:
	@echo "Building for Windows..."
	GOOS=windows GOARCH=amd64 $(GOBUILD) $(LDFLAGS) -o $(BINARY_NAME)-windows-amd64.exe $(MAIN_PACKAGE)
	GOOS=windows GOARCH=arm64 $(GOBUILD) $(LDFLAGS) -o $(BINARY_NAME)-windows-arm64.exe $(MAIN_PACKAGE)

# Docker targets
docker-build:
	@echo "Building Docker image $(DOCKER_IMAGE):$(DOCKER_TAG)..."
	docker build -f $(DOCKERFILE_PATH) \
		--build-arg VERSION=$(VERSION) \
		-t $(DOCKER_IMAGE):$(DOCKER_TAG) .
	docker tag $(DOCKER_IMAGE):$(DOCKER_TAG) $(DOCKER_IMAGE):$(DOCKER_LATEST)
	@echo "✓ Docker image built: $(DOCKER_IMAGE):$(DOCKER_TAG)"
	@echo "✓ Docker image tagged: $(DOCKER_IMAGE):$(DOCKER_LATEST)"

docker-build-multiarch:
	@echo "Building multi-architecture Docker image $(DOCKER_IMAGE):$(DOCKER_TAG)..."
	docker buildx create --use --name multiarch-builder 2>/dev/null || true
	docker buildx build -f $(DOCKERFILE_PATH) \
		--platform linux/amd64,linux/arm64 \
		--build-arg VERSION=$(VERSION) \
		-t $(DOCKER_IMAGE):$(DOCKER_TAG) \
		-t $(DOCKER_IMAGE):$(DOCKER_LATEST) \
		.
	@echo "✓ Multi-architecture Docker images built and pushed"

docker-build-no-cache:
	@echo "Building Docker image $(DOCKER_IMAGE):$(DOCKER_TAG) without cache..."
	docker build --no-cache -f $(DOCKERFILE_PATH) \
		--build-arg VERSION=$(VERSION) \
		-t $(DOCKER_IMAGE):$(DOCKER_TAG) .
	docker tag $(DOCKER_IMAGE):$(DOCKER_TAG) $(DOCKER_IMAGE):$(DOCKER_LATEST)
	@echo "✓ Docker image built: $(DOCKER_IMAGE):$(DOCKER_TAG)"

docker-clean:
	@echo "Cleaning Docker images..."
	-docker rmi $(DOCKER_IMAGE):$(DOCKER_TAG) 2>/dev/null || true
	-docker rmi $(DOCKER_IMAGE):$(DOCKER_LATEST) 2>/dev/null || true
	@echo "✓ Docker images cleaned"

# Clean build artifacts
clean:
	@echo "Cleaning..."
	$(GOCLEAN)
	rm -f $(BINARY_NAME)
	rm -f $(BINARY_NAME)-*
	@echo "✓ Clean complete"

# Clean everything including Docker images
clean-all: clean docker-clean
	@echo "✓ All artifacts cleaned"

# Run tests
test:
	@echo "Running tests..."
	$(GOTEST) -v ./...

# Run tests with coverage
coverage:
	@echo "Running tests with coverage..."
	$(GOTEST) -coverprofile=coverage.out ./...
	$(GOCMD) tool cover -html=coverage.out -o coverage.html
	@echo "✓ Coverage report generated: coverage.html"

# Format code
fmt:
	@echo "Formatting code..."
	$(GOFMT) -s -w .
	@echo "✓ Code formatted"

# Lint code
lint:
	@echo "Linting code..."
	@if command -v golint >/dev/null 2>&1; then \
		golint ./...; \
	else \
		echo "golint not installed. Install with: go install golang.org/x/lint/golint@latest"; \
	fi

# Vet code
vet:
	@echo "Vetting code..."
	$(GOVET) ./...
	@echo "✓ Code vetted"

# Run all checks
check: fmt vet lint test
	@echo "✓ All checks passed"

# Install dependencies
deps:
	@echo "Installing dependencies..."
	$(GOMOD) download
	$(GOMOD) verify
	@echo "✓ Dependencies installed"

# Tidy dependencies
tidy:
	@echo "Tidying dependencies..."
	$(GOMOD) tidy
	@echo "✓ Dependencies tidied"

# Install the binary to GOPATH/bin
install: build
	@echo "Installing $(BINARY_NAME)..."
	$(GOCMD) install $(LDFLAGS) $(MAIN_PACKAGE)
	@echo "✓ $(BINARY_NAME) installed"

# Uninstall the binary
uninstall:
	@echo "Uninstalling $(BINARY_NAME)..."
	rm -f $(GOPATH)/bin/$(BINARY_NAME)
	@echo "✓ $(BINARY_NAME) uninstalled"

# Development helpers
dev-setup: deps
	@echo "Setting up development environment..."
	@if ! command -v golint >/dev/null 2>&1; then \
		echo "Installing golint..."; \
		$(GOCMD) install golang.org/x/lint/golint@latest; \
	fi
	@echo "✓ Development environment ready"

# Quick test run with a region list
test-regions: build
	@echo "Testing regions command..."
	./$(BINARY_NAME) regions

# Test build with example (requires valid credentials)
test-build: build
	@echo "To test config generation, run:"
	@echo "  ./$(BINARY_NAME) -r uk_london YOUR_USERNAME YOUR_PASSWORD"

# Release preparation
release-check: check build-all
	@echo "✓ Release artifacts ready"
	@ls -la $(BINARY_NAME)-*

# Show version
version:
	@echo "Version: $(VERSION)"

# Show help
help:
	@echo "Available targets:"
	@echo ""
	@echo "Build targets:"
	@echo "  build        - Build the binary"
	@echo "  build-all    - Build for all platforms"
	@echo "  clean        - Clean build artifacts"
	@echo "  clean-all    - Clean all artifacts including Docker images"
	@echo ""
	@echo "Docker targets:"
	@echo "  docker-build - Build Docker image"
	@echo "  docker-build-multiarch - Build multi-architecture image (amd64/arm64)"
	@echo "  docker-build-no-cache - Build Docker image without cache"
	@echo "  docker-clean - Remove Docker images"
	@echo ""
	@echo "Test targets:"
	@echo "  test         - Run tests"
	@echo "  coverage     - Run tests with coverage"
	@echo "  test-regions - Test the regions command"
	@echo ""
	@echo "Code quality:"
	@echo "  fmt          - Format code"
	@echo "  lint         - Lint code"
	@echo "  vet          - Vet code"
	@echo "  check        - Run all checks (fmt, vet, lint, test)"
	@echo ""
	@echo "Dependencies:"
	@echo "  deps         - Install dependencies"
	@echo "  tidy         - Tidy dependencies"
	@echo ""
	@echo "Installation:"
	@echo "  install      - Install binary to GOPATH/bin"
	@echo "  uninstall    - Remove binary from GOPATH/bin"
	@echo ""
	@echo "Development:"
	@echo "  dev-setup    - Set up development environment"
	@echo "  release-check- Prepare and check release artifacts"
	@echo "  version      - Show version"
	@echo "  help         - Show this help"
