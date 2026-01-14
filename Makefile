.PHONY: help build preview clean install release release-auto release-smart release-patch release-minor release-major release-version release-dry-run lint format test ci

# Default target
help: ## Show this help message
	@echo "StorySellerSaver Build System"
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Development targets
build: ## Build the screensaver in debug mode
	@echo "Building StorySellerSaver (Debug)..."
	@xcodebuild -project StorysellerScreensaver.xcodeproj -scheme StorySellerSaver -configuration Debug build

build-release: ## Build the screensaver in release mode
	@echo "Building StorySellerSaver (Release)..."
	@xcodebuild -project StorysellerScreensaver.xcodeproj -scheme StorySellerSaver -configuration Release build

preview: ## Build and preview the screensaver
	@echo "Building and previewing StorySellerSaver..."
	@./scripts/build_link_preview.sh --debug

preview-release: ## Build and preview the screensaver (release mode)
	@echo "Building and previewing StorySellerSaver (Release)..."
	@./scripts/build_link_preview.sh --release

install: ## Install screensaver for testing
	@echo "Installing StorySellerSaver..."
	@./scripts/preview_screensaver.sh --build --clean

install-release: ## Install screensaver for testing (release mode)
	@echo "Installing StorySellerSaver (Release)..."
	@./scripts/preview_screensaver.sh --build --clean --release

# Maintenance targets
clean: ## Clean build artifacts
	@echo "Cleaning build artifacts..."
	@xcodebuild -project StorysellerScreensaver.xcodeproj -scheme StorySellerSaver clean
	@rm -rf ~/Library/Developer/Xcode/DerivedData/StorysellerScreensaver-*

clean-all: ## Clean all artifacts including screen saver
	@make clean
	@rm -rf ~/Library/Screen\ Savers/StorySellerSaver.saver

# Development tools
lint: ## Run SwiftLint if installed
	@echo "Running SwiftLint..."
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint lint StorySellerSaver/; \
	else \
		echo "SwiftLint not installed. Install with: brew install swiftlint"; \
	fi

format: ## Format code with SwiftFormat if installed
	@echo "Formatting Swift code..."
	@if command -v swiftformat >/dev/null 2>&1; then \
		swiftformat StorySellerSaver/ --swiftversion 5.7; \
	else \
		echo "SwiftFormat not installed. Install with: brew install swiftformat"; \
	fi

test: ## Run tests (if any exist)
	@echo "Running tests..."
	@xcodebuild -project StorysellerScreensaver.xcodeproj -scheme StorySellerSaver test

# Release targets
release-auto: ## Create an auto-generated release based on existing tags
	@echo "Creating auto-generated release..."
	@./scripts/create-release.sh --auto

release-smart: ## Create a smart release based on commit message analysis
	@echo "Creating smart release based on commits..."
	@./scripts/create-release.sh --smart

release-patch: ## Create a patch release (e.g., v1.0.0 -> v1.0.1)
	@echo "Creating patch release..."
	@./scripts/create-release.sh --patch

release-minor: ## Create a minor release (e.g., v1.0.0 -> v1.1.0)
	@echo "Creating minor release..."
	@./scripts/create-release.sh --minor

release-major: ## Create a major release (e.g., v1.0.0 -> v2.0.0)
	@echo "Creating major release..."
	@./scripts/create-release.sh --major

release-version: ## Create a specific version release (usage: make release-version VERSION=1.2.3)
	@echo "Creating release v$(VERSION)..."
	@if [ -z "$(VERSION)" ]; then \
		echo "Error: VERSION is required. Usage: make release-version VERSION=1.2.3"; \
		exit 1; \
	fi
	@./scripts/create-release.sh --version $(VERSION)

release-dry-run: ## Preview what an auto release would do
	@echo "Dry run for auto release..."
	@./scripts/create-release.sh --dry-run --auto

# CI/CD targets
ci: ## Run full CI pipeline (build + lint)
	@make clean
	@make lint
	@make build
	@make test
	@echo "CI pipeline completed successfully!"

# Utility targets
check-scripts: ## Check if scripts are executable
	@echo "Checking script permissions..."
	@ls -la scripts/
	@echo "Making scripts executable..."
	@chmod +x scripts/*.sh

open: ## Open project in Xcode
	@open StorysellerScreensaver.xcodeproj

logs: ## Show recent Xcode build logs
	@echo "Recent build logs:"
	@find ~/Library/Developer/Xcode/DerivedData/StorysellerScreensaver-*/Logs/Build -name "*.xcactivitylog" -exec ls -la {} \; | head -5