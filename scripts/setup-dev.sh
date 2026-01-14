#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Setting up StorySellerSaver development environment..."

# Check if Homebrew is installed
if ! command -v brew >/dev/null 2>&1; then
    echo "❌ Homebrew is required but not installed. Please install Homebrew first:"
    echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

echo "📦 Installing development dependencies..."

# Install development tools
brew install swiftlint
brew install swiftformat
brew install lefthook
brew install shellcheck

echo "🔗 Setting up git hooks..."

# Install lefthook
lefthook install

echo "✅ Development environment setup complete!"
echo ""
echo "Available commands:"
echo "  make help        - Show all available make targets"
echo "  make build       - Build the project"
echo "  make preview     - Build and preview screensaver"
echo "  make lint        - Run SwiftLint"
echo "  make format      - Format Swift code"
echo "  make ci          - Run full CI pipeline"
echo ""
echo "Git hooks are now active for:"
echo "  • SwiftLint checking on pre-commit"
echo "  • Code formatting on pre-commit"
echo "  • Shell script checking on pre-commit"
echo "  • Build verification on pre-push"