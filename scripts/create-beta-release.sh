#!/usr/bin/env bash
set -euo pipefail

# Create Beta Release from Main Branch
# This creates a beta tag directly from main branch and triggers GitHub Actions

usage() {
    cat >&2 << 'USAGE'
Usage: create-beta-release.sh [version]

Create a beta release directly from main branch and trigger GitHub Actions.

ARGUMENTS:
    version    Optional version (e.g., 1.1.0). If not provided, auto-generates.

EXAMPLES:
    ./scripts/create-beta-release.sh         # Auto-generate version
    ./scripts/create-beta-release.sh 1.1.0   # Specific version

NOTES:
    - Creates beta tag directly from main branch
    - Pushes tag to GitHub to trigger Actions workflow
    - Beta releases are marked as pre-releases in GitHub
    - Requires GitHub remote to be configured
USAGE
}

# Check if we're on main branch
check_main_branch() {
    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    if [[ "$current_branch" != "main" ]]; then
        log_error "Must be on main branch. Current branch: $current_branch"
        log_info "Run: git checkout main"
        exit 1
    fi
}

# Check if main has uncommitted changes
check_clean_main() {
    if [[ -n "$(git status --porcelain)" ]]; then
        log_error "Main branch has uncommitted changes"
        log_info "Commit or stash changes first"
        exit 1
    fi
}

# Generate beta version
generate_beta_version() {
    local base_version=${1:-""}

    if [[ -n "$base_version" ]]; then
        # Find latest beta for this version
        local latest_beta
        latest_beta=$(git tag -l "v${base_version}-beta.*" | sort -V | tail -1 || echo "")

        if [[ -z "$latest_beta" ]]; then
            echo "${base_version}-beta.1"
        else
            local current_num
            current_num=$(echo "$latest_beta" | sed -E "s/v${base_version}-beta\.([0-9]+)/\1/")
            local next_num=$((current_num + 1))
            echo "${base_version}-beta.${next_num}"
        fi
    else
        # Auto-generate based on current develop state
        local latest_tag
        latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
        local base_version
        base_version=$(echo "$latest_tag" | sed 's/^v//' | sed 's/-.*//')

        # Increment patch version for beta
        IFS='.' read -r major minor patch <<< "$base_version"
        local next_patch=$((patch + 1))
        base_version="${major}.${minor}.${next_patch}"

        echo "${base_version}-beta.1"
    fi
}

main() {
    local version=""

    if [[ $# -gt 1 ]]; then
        usage
        exit 1
    elif [[ $# -eq 1 ]]; then
        version=$1
    fi

    check_main_branch
    check_clean_main

    # Check if remote is configured
    if ! git remote get-url origin >/dev/null 2>&1; then
        log_error "No GitHub remote configured!"
        log_info "Please set up a GitHub repository first:"
        log_info "1. Create a new repository on GitHub"
        log_info "2. Run: git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
        log_info "3. Run: git push -u origin main"
        exit 1
    fi

    local beta_version
    beta_version=$(generate_beta_version "$version")

    log_info "Creating beta release: v$beta_version"

    # Create beta tag with detailed message
    git tag -a "v$beta_version" -m "Beta release $beta_version

🎠 StorySeller Screensaver Beta Release

✨ Features:
- Smooth carousel animation with vertical word transitions
- Responsive typography that scales to screen size
- Dynamic scaling and fade effects for words near center
- Ultra-smooth 60fps animation with quintic easing

🏷️ Logo Animation:
- 'CREATIVE BUSINESS' logo in corners, rotates every 5 minutes
- Smooth 8-second transitions between corners
- Subtle styling (10% opacity, no background)

⚠️ This is a pre-release version for testing purposes only.
This version may contain bugs or incomplete features. Use at your own risk."

    # Push tag to trigger GitHub Actions release
    log_info "Pushing beta tag to GitHub..."
    git push origin "v$beta_version"

    log_success "Beta release v$beta_version pushed to GitHub!"
    log_info "GitHub Actions will automatically:"
    log_info "  - Build the screensaver in Release configuration"
    log_info "  - Package it as StorySellerSaver-v${beta_version}.zip"
    log_info "  - Create a GitHub release with the package"
    log_info "  - Mark it as a pre-release"

    log_success "Beta release v$beta_version is being processed by GitHub Actions!"
    log_info "Check your repository's Actions tab for progress"
}

# Import logging functions from create-release.sh
log_error() {
    echo -e "\033[0;31m❌ $1\033[0m"
}

log_success() {
    echo -e "\033[0;32m✅ $1\033[0m"
}

log_warning() {
    echo -e "\033[1;33m⚠️  $1\033[0m"
}

log_info() {
    echo -e "\033[0;34mℹ️  $1\033[0m"
}

main "$@"