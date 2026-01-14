#!/usr/bin/env bash
set -euo pipefail

# StorySellerSaver Release Script
# Creates a new version tag and triggers GitHub release

usage() {
    cat >&2 << 'USAGE'
Usage: create-release.sh [options]

Create a new version tag and trigger automated release build.

OPTIONS:
    -v, --version VERSION    Specify version (e.g., 1.0.0)
    -p, --patch             Increment patch version (1.0.0 -> 1.0.1)
    -m, --minor             Increment minor version (1.0.0 -> 1.1.0)
    -M, --major             Increment major version (1.0.0 -> 2.0.0)
    -a, --auto              Auto-generate next version based on existing tags
    -s, --smart             Smart version bump based on commit messages
    -b, --beta              Create beta pre-release (adds -beta.N suffix)
    -r, --rc                Create release candidate (adds -rc.N suffix)
    -d, --dry-run           Show what would be done without doing it
    -h, --help              Show this help

EXAMPLES:
    ./scripts/create-release.sh --auto           # Auto-generate next version
    ./scripts/create-release.sh --smart          # Smart bump based on commits
    ./scripts/create-release.sh --patch          # v1.0.0 -> v1.0.1
    ./scripts/create-release.sh --minor          # v1.0.0 -> v1.1.0
    ./scripts/create-release.sh -v 1.2.3         # Specific version
    ./scripts/create-release.sh --patch --beta   # v1.0.0 -> v1.0.1-beta.1
    ./scripts/create-release.sh -v 1.0.0 --rc   # v1.0.0-rc.1
    ./scripts/create-release.sh --dry-run --auto # Preview auto version
USAGE
}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Get current version from git tags
get_current_version() {
    local current_version
    current_version=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "0.0.0")
    echo "$current_version"
}

# Auto-generate next version based on conventional commits
auto_generate_version() {
    local bump_type=$1
    local current_version
    current_version=$(get_current_version)

    # If no tags exist yet, start with 1.0.0 for any bump type
    if [[ "$current_version" == "0.0.0" ]]; then
        case $bump_type in
            major|minor|patch)
                echo "1.0.0"
                return
                ;;
        esac
    fi

    # For existing versions, use conventional logic
    increment_version "$current_version" "$bump_type"
}

# Smart version bump based on commit messages (optional enhancement)
smart_version_bump() {
    local commits_since_last_tag
    commits_since_last_tag=$(git log --oneline "$(git describe --tags --abbrev=0 2>/dev/null || echo "HEAD~1")..HEAD" 2>/dev/null | wc -l || echo "1")

    # If this is the first release, use 1.0.0
    if ! git describe --tags --abbrev=0 >/dev/null 2>&1; then
        echo "1.0.0"
        return
    fi

    # Check for breaking changes in commit messages
    if git log --oneline "$(git describe --tags --abbrev=0)..HEAD" | grep -i -E "(breaking|break|major|!)" >/dev/null 2>&1; then
        local current_version
        current_version=$(get_current_version)
        increment_version "$current_version" "major"
        return
    fi

    # Check for feature additions
    if git log --oneline "$(git describe --tags --abbrev=0)..HEAD" | grep -i -E "(feat|feature|add)" >/dev/null 2>&1; then
        local current_version
        current_version=$(get_current_version)
        increment_version "$current_version" "minor"
        return
    fi

    # Default to patch version
    local current_version
    current_version=$(get_current_version)
    increment_version "$current_version" "patch"
}

# Generate pre-release version with suffix
generate_prerelease_version() {
    local base_version=$1
    local prerelease_type=$2

    # Find the latest tag with this base version and prerelease type
    local latest_prerelease
    latest_prerelease=$(git tag -l "v${base_version}-${prerelease_type}.*" | sort -V | tail -1 || echo "")

    if [[ -z "$latest_prerelease" ]]; then
        # First prerelease for this version
        echo "${base_version}-${prerelease_type}.1"
    else
        # Increment the prerelease number
        local current_num
        current_num=$(echo "$latest_prerelease" | sed -E "s/v${base_version}-${prerelease_type}\.([0-9]+)/\1/")
        local next_num=$((current_num + 1))
        echo "${base_version}-${prerelease_type}.${next_num}"
    fi
}

# Increment version
increment_version() {
    local version=$1
    local part=$2

    IFS='.' read -r major minor patch <<< "$version"

    case $part in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
    esac

    echo "$major.$minor.$patch"
}

# Validate version format
validate_version() {
    local version=$1
    if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log_error "Invalid version format: $version (expected: x.y.z)"
        exit 1
    fi
}

# Check if tag already exists
check_tag_exists() {
    local tag=$1
    if git tag -l | grep -q "^$tag$"; then
        log_error "Tag $tag already exists"
        exit 1
    fi
}

# Main script
main() {
    local version=""
    local increment=""
    local auto_generate=false
    local smart_bump=false
    local prerelease_type=""
    local dry_run=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--version)
                version="$2"
                shift 2
                ;;
            -p|--patch)
                increment="patch"
                shift
                ;;
            -m|--minor)
                increment="minor"
                shift
                ;;
            -M|--major)
                increment="major"
                shift
                ;;
            -a|--auto)
                auto_generate=true
                shift
                ;;
            -s|--smart)
                smart_bump=true
                shift
                ;;
            -b|--beta)
                prerelease_type="beta"
                shift
                ;;
            -r|--rc)
                prerelease_type="rc"
                shift
                ;;
            -d|--dry-run)
                dry_run=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    # Determine version
    local base_version=""
    if [[ -n "$version" ]]; then
        validate_version "$version"
        base_version="$version"
        log_info "Using specified version: v$base_version"
    elif [[ "$auto_generate" == true ]]; then
        local current_version
        current_version=$(get_current_version)
        if [[ "$current_version" == "0.0.0" ]]; then
            base_version="1.0.0"
            log_info "No existing tags found, starting with v$base_version"
        else
            base_version=$(increment_version "$current_version" "patch")
            log_info "Current version: v$current_version"
            log_info "Auto-generated base version: v$base_version (patch increment)"
        fi
    elif [[ "$smart_bump" == true ]]; then
        base_version=$(smart_version_bump)
        local current_version
        current_version=$(get_current_version)
        log_info "Current version: v$current_version"
        log_info "Smart-generated base version: v$base_version (based on commit analysis)"
    elif [[ -n "$increment" ]]; then
        local current_version
        current_version=$(get_current_version)
        base_version=$(increment_version "$current_version" "$increment")
        log_info "Current version: v$current_version"
        log_info "New base version: v$base_version (incremented $increment)"
    else
        log_error "Must specify either --version, --auto, --smart, or an increment option (--patch/--minor/--major)"
        usage
        exit 1
    fi

    # Apply pre-release suffix if requested
    if [[ -n "$prerelease_type" ]]; then
        version=$(generate_prerelease_version "$base_version" "$prerelease_type")
        log_info "Generated pre-release version: v$version"
    else
        version="$base_version"
    fi

    local tag="v$version"

    # Check if tag exists
    check_tag_exists "$tag"

    # Check if working directory is clean
    if [[ -n "$(git status --porcelain)" ]]; then
        log_error "Working directory is not clean. Please commit or stash changes first."
        exit 1
    fi

    # Dry run or actual execution
    if [[ "$dry_run" == true ]]; then
        log_warning "DRY RUN - Would create tag: $tag"
        log_info "Command that would be executed:"
        echo "  git tag -a \"$tag\" -m \"Release $tag\""
        echo "  git push origin \"$tag\""
        exit 0
    fi

    # Create and push tag
    log_info "Creating tag: $tag"
    git tag -a "$tag" -m "Release $tag"

    log_info "Pushing tag to remote..."
    git push origin "$tag"

    log_success "Release $tag created successfully!"
    log_info "GitHub Actions will now build and create the release automatically."
    log_info "Check the Actions tab to monitor the build progress."
}

main "$@"