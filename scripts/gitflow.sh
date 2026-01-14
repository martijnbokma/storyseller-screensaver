#!/usr/bin/env bash
set -euo pipefail

# Gitflow Workflow Script for StorySellerSaver
# Implements Gitflow branching model operations

usage() {
    cat >&2 << 'USAGE'
Usage: gitflow.sh <command> [options]

Gitflow commands for StorySellerSaver development workflow.

FEATURE COMMANDS:
    feature start <name>     Start a new feature branch
    feature finish <name>    Finish a feature branch (merge to develop)

RELEASE COMMANDS:
    release start <version>  Start a release branch
    release finish <version> Finish a release branch (merge to main & develop)

HOTFIX COMMANDS:
    hotfix start <version>   Start a hotfix branch from main
    hotfix finish <version>  Finish a hotfix branch (merge to main & develop)

UTILITY COMMANDS:
    status                  Show current Gitflow status
    init                    Initialize Gitflow branches (if needed)
    cleanup                 Remove merged branches

EXAMPLES:
    ./scripts/gitflow.sh feature start user-preferences
    ./scripts/gitflow.sh feature finish user-preferences
    ./scripts/gitflow.sh release start 1.1.0
    ./scripts/gitflow.sh release finish 1.1.0
    ./scripts/gitflow.sh hotfix start 1.0.1
    ./scripts/gitflow.sh status

BRANCH STRUCTURE:
    main        Production releases
    develop     Integration branch
    feature/*   Feature development
    release/*   Release preparation
    hotfix/*    Production hotfixes
USAGE
}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

log_feature() {
    echo -e "${CYAN}🌟 $1${NC}"
}

log_release() {
    echo -e "${PURPLE}📦 $1${NC}"
}

log_hotfix() {
    echo -e "${RED}🔥 $1${NC}"
}

# Check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        log_error "Not in a git repository"
        exit 1
    fi
}

# Check if branch exists
branch_exists() {
    local branch=$1
    git show-ref --verify --quiet "refs/heads/$branch"
}

# Check if remote branch exists
remote_branch_exists() {
    local branch=$1
    git ls-remote --heads origin "$branch" >/dev/null 2>&1
}

# Get current branch
get_current_branch() {
    git rev-parse --abbrev-ref HEAD
}

# Ensure branch is clean
ensure_clean_branch() {
    if [[ -n "$(git status --porcelain)" ]]; then
        log_error "Working directory is not clean. Please commit or stash changes first."
        exit 1
    fi
}

# Initialize Gitflow branches
init_gitflow() {
    log_info "Initializing Gitflow branches..."

    # Create develop if it doesn't exist
    if ! branch_exists "develop"; then
        log_info "Creating develop branch..."
        git checkout -b develop
        log_success "Created develop branch"
    else
        log_info "Develop branch already exists"
    fi

    # Ensure we're on develop
    git checkout develop

    # Push branches to remote if remote exists
    if git remote get-url origin >/dev/null 2>&1; then
        log_info "Pushing branches to remote..."
        git push -u origin main develop
        log_success "Branches pushed to remote"
    fi

    log_success "Gitflow initialized successfully"
}

# Feature operations
feature_start() {
    local feature_name=$1

    if [[ -z "$feature_name" ]]; then
        log_error "Feature name is required"
        exit 1
    fi

    local branch_name="feature/$feature_name"

    ensure_clean_branch

    if branch_exists "$branch_name"; then
        log_error "Feature branch '$branch_name' already exists"
        exit 1
    fi

    log_feature "Starting feature: $feature_name"
    git checkout -b "$branch_name" develop

    if git remote get-url origin >/dev/null 2>&1; then
        git push -u origin "$branch_name"
    fi

    log_success "Feature branch '$branch_name' created and ready for development"
}

feature_finish() {
    local feature_name=$1

    if [[ -z "$feature_name" ]]; then
        log_error "Feature name is required"
        exit 1
    fi

    local branch_name="feature/$feature_name"
    local current_branch
    current_branch=$(get_current_branch)

    if [[ "$current_branch" != "$branch_name" ]]; then
        if branch_exists "$branch_name"; then
            git checkout "$branch_name"
        else
            log_error "Feature branch '$branch_name' does not exist"
            exit 1
        fi
    fi

    ensure_clean_branch

    log_feature "Finishing feature: $feature_name"

    # Merge back to develop
    git checkout develop
    git merge --no-ff "$branch_name" -m "Merge feature '$feature_name' into develop"

    # Push changes
    if git remote get-url origin >/dev/null 2>&1; then
        git push origin develop
        git push origin --delete "$branch_name"
    fi

    # Delete local branch
    git branch -d "$branch_name"

    log_success "Feature '$feature_name' successfully merged into develop"
}

# Release operations
release_start() {
    local version=$1

    if [[ -z "$version" ]]; then
        log_error "Version is required"
        exit 1
    fi

    local branch_name="release/$version"

    ensure_clean_branch

    if branch_exists "$branch_name"; then
        log_error "Release branch '$branch_name' already exists"
        exit 1
    fi

    log_release "Starting release: $version"
    git checkout -b "$branch_name" develop

    # Update version file
    echo "$version" > VERSION

    # Commit version update
    git add VERSION
    git commit -m "Bump version to $version"

    if git remote get-url origin >/dev/null 2>&1; then
        git push -u origin "$branch_name"
    fi

    log_success "Release branch '$branch_name' created and version bumped to $version"
    log_info "Perform final testing and bug fixes on this branch"
}

release_finish() {
    local version=$1

    if [[ -z "$version" ]]; then
        log_error "Version is required"
        exit 1
    fi

    local branch_name="release/$version"
    local current_branch
    current_branch=$(get_current_branch)

    if [[ "$current_branch" != "$branch_name" ]]; then
        if branch_exists "$branch_name"; then
            git checkout "$branch_name"
        else
            log_error "Release branch '$branch_name' does not exist"
            exit 1
        fi
    fi

    ensure_clean_branch

    log_release "Finishing release: $version"

    # Merge to main
    git checkout main
    git merge --no-ff "$branch_name" -m "Release version $version"

    # Tag the release
    git tag -a "v$version" -m "Release version $version"

    # Merge back to develop
    git checkout develop
    git merge --no-ff "$branch_name" -m "Merge release '$version' into develop"

    # Push everything
    if git remote get-url origin >/dev/null 2>&1; then
        git push origin main
        git push origin develop
        git push origin --tags
        git push origin --delete "$branch_name"
    fi

    # Delete local branch
    git branch -d "$branch_name"

    log_success "Release $version successfully deployed to production"
    log_info "GitHub Actions will automatically build and create the release"
}

# Hotfix operations
hotfix_start() {
    local version=$1

    if [[ -z "$version" ]]; then
        log_error "Version is required"
        exit 1
    fi

    local branch_name="hotfix/$version"

    ensure_clean_branch

    if branch_exists "$branch_name"; then
        log_error "Hotfix branch '$branch_name' already exists"
        exit 1
    fi

    log_hotfix "Starting hotfix: $version"
    git checkout -b "$branch_name" main

    # Update version file
    echo "$version" > VERSION

    # Commit version update
    git add VERSION
    git commit -m "Start hotfix $version"

    if git remote get-url origin >/dev/null 2>&1; then
        git push -u origin "$branch_name"
    fi

    log_success "Hotfix branch '$branch_name' created from main"
    log_warning "Apply your hotfix changes to this branch"
}

hotfix_finish() {
    local version=$1

    if [[ -z "$version" ]]; then
        log_error "Version is required"
        exit 1
    fi

    local branch_name="hotfix/$version"
    local current_branch
    current_branch=$(get_current_branch)

    if [[ "$current_branch" != "$branch_name" ]]; then
        if branch_exists "$branch_name"; then
            git checkout "$branch_name"
        else
            log_error "Hotfix branch '$branch_name' does not exist"
            exit 1
        fi
    fi

    ensure_clean_branch

    log_hotfix "Finishing hotfix: $version"

    # Merge to main
    git checkout main
    git merge --no-ff "$branch_name" -m "Hotfix version $version"

    # Tag the hotfix
    git tag -a "v$version" -m "Hotfix version $version"

    # Merge to develop
    git checkout develop
    git merge --no-ff "$branch_name" -m "Merge hotfix '$version' into develop"

    # Push everything
    if git remote get-url origin >/dev/null 2>&1; then
        git push origin main
        git push origin develop
        git push origin --tags
        git push origin --delete "$branch_name"
    fi

    # Delete local branch
    git branch -d "$branch_name"

    log_success "Hotfix $version successfully applied to production"
}

# Status overview
show_status() {
    log_info "Gitflow Status Overview"
    echo

    local current_branch
    current_branch=$(get_current_branch)
    echo "Current branch: $current_branch"
    echo

    echo "Branch Structure:"
    echo "  main      $(branch_exists "main" && echo "✅" || echo "❌") Production releases"
    echo "  develop   $(branch_exists "develop" && echo "✅" || echo "❌") Integration branch"
    echo

    echo "Active Branches:"
    local feature_branches
    feature_branches=$(git branch -l "feature/*" 2>/dev/null | wc -l)
    local release_branches
    release_branches=$(git branch -l "release/*" 2>/dev/null | wc -l)
    local hotfix_branches
    hotfix_branches=$(git branch -l "hotfix/*" 2>/dev/null | wc -l)

    echo "  Features:  $feature_branches active"
    echo "  Releases:  $release_branches active"
    echo "  Hotfixes:  $hotfix_branches active"
    echo

    if [[ $feature_branches -gt 0 ]]; then
        echo "Feature branches:"
        git branch -l "feature/*" | sed 's/^/  /'
        echo
    fi

    if [[ $release_branches -gt 0 ]]; then
        echo "Release branches:"
        git branch -l "release/*" | sed 's/^/  /'
        echo
    fi

    if [[ $hotfix_branches -gt 0 ]]; then
        echo "Hotfix branches:"
        git branch -l "hotfix/*" | sed 's/^/  /'
        echo
    fi

    echo "Recent commits:"
    git log --oneline -5 | sed 's/^/  /'
}

# Cleanup merged branches
cleanup_branches() {
    log_info "Cleaning up merged branches..."

    local merged_branches
    merged_branches=$(git branch --merged develop | grep -E "(feature|release|hotfix)" | grep -v "^*" || true)

    if [[ -z "$merged_branches" ]]; then
        log_info "No merged branches to clean up"
        return
    fi

    echo "Found merged branches:"
    echo "$merged_branches" | sed 's/^/  /'
    echo

    echo "$merged_branches" | while read -r branch; do
        branch=$(echo "$branch" | xargs) # trim whitespace
        if [[ -n "$branch" ]]; then
            log_info "Deleting branch: $branch"
            git branch -d "$branch"
        fi
    done

    log_success "Cleanup completed"
}

# Main script logic
main() {
    check_git_repo

    if [[ $# -lt 1 ]]; then
        usage
        exit 1
    fi

    local command=$1
    shift

    case $command in
        feature)
            if [[ $# -lt 1 ]]; then
                log_error "Feature command requires a subcommand"
                usage
                exit 1
            fi
            local subcommand=$1
            shift
            case $subcommand in
                start)
                    feature_start "$1"
                    ;;
                finish)
                    feature_finish "$1"
                    ;;
                *)
                    log_error "Unknown feature subcommand: $subcommand"
                    usage
                    exit 1
                    ;;
            esac
            ;;
        release)
            if [[ $# -lt 1 ]]; then
                log_error "Release command requires a subcommand"
                usage
                exit 1
            fi
            local subcommand=$1
            shift
            case $subcommand in
                start)
                    release_start "$1"
                    ;;
                finish)
                    release_finish "$1"
                    ;;
                *)
                    log_error "Unknown release subcommand: $subcommand"
                    usage
                    exit 1
                    ;;
            esac
            ;;
        hotfix)
            if [[ $# -lt 1 ]]; then
                log_error "Hotfix command requires a subcommand"
                usage
                exit 1
            fi
            local subcommand=$1
            shift
            case $subcommand in
                start)
                    hotfix_start "$1"
                    ;;
                finish)
                    hotfix_finish "$1"
                    ;;
                *)
                    log_error "Unknown hotfix subcommand: $subcommand"
                    usage
                    exit 1
                    ;;
            esac
            ;;
        status)
            show_status
            ;;
        init)
            init_gitflow
            ;;
        cleanup)
            cleanup_branches
            ;;
        *)
            log_error "Unknown command: $command"
            usage
            exit 1
            ;;
    esac
}

main "$@"