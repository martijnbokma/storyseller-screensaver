#!/usr/bin/env bash
set -euo pipefail

# Create Beta Release from Develop Branch
# This creates a beta tag directly from develop branch

usage() {
    cat >&2 << 'USAGE'
Usage: create-beta-release.sh [version]

Create a beta release directly from develop branch.

ARGUMENTS:
    version    Optional version (e.g., 1.1.0). If not provided, auto-generates.

EXAMPLES:
    ./scripts/create-beta-release.sh         # Auto-generate version
    ./scripts/create-beta-release.sh 1.1.0   # Specific version

NOTES:
    - Creates beta tag directly from develop branch
    - Use with caution - ensure develop is stable
    - Beta releases are marked as pre-releases in GitHub
USAGE
}

# Check if we're on develop branch
check_develop_branch() {
    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    if [[ "$current_branch" != "develop" ]]; then
        log_error "Must be on develop branch. Current branch: $current_branch"
        log_info "Run: git checkout develop"
        exit 1
    fi
}

# Check if develop has uncommitted changes
check_clean_develop() {
    if [[ -n "$(git status --porcelain)" ]]; then
        log_error "Develop branch has uncommitted changes"
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

    check_develop_branch
    check_clean_develop

    local beta_version
    beta_version=$(generate_beta_version "$version")

    log_info "Creating beta release: v$beta_version"

    # Create beta tag
    git tag -a "v$beta_version" -m "Beta release $beta_version"

    # Push tag to trigger release
    if git remote get-url origin >/dev/null 2>&1; then
        log_info "Pushing beta tag to remote..."
        git push origin "v$beta_version"
        log_success "Beta release v$beta_version pushed to remote"
        log_info "GitHub Actions will create the beta release automatically"
    else
        log_success "Beta tag v$beta_version created locally"
        log_warning "No remote configured - tag not pushed"
    fi

    log_success "Beta release v$beta_version ready!"
    log_info "This will appear as a pre-release on GitHub"
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