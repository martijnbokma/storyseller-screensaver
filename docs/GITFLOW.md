# Gitflow Workflow Guide

This guide explains how we use Gitflow for the StorySellerSaver development workflow.

## Overview

Gitflow is a branching model that helps organize development, releases and hotfixes. It uses different branches for different purposes.

```
main (production) ──┬── hotfix/1.0.1 ───┬── tag:v1.0.1
                   │                   │
                   ├─ tag:v1.0.0 ──────┘
                   │
develop ──────────┬── feature/user-prefs ──┬─ merge to develop
(integration)     │                        │
                  ├─ release/1.0.0 ───────┼─ merge to main ── tag:v1.0.0
                  │                        │
                  └─ feature/dark-mode ───┘
```

## Branch Structure

### Permanent Branches
- **`main`** - Production releases (only merges, no direct commits)
- **`develop`** - Integration branch for features

### Temporary Branches
- **`feature/*`** - New features
- **`release/*`** - Release preparation
- **`hotfix/*`** - Urgent production fixes

## Feature Workflow

### Starting a New Feature
```bash
# Start a new feature
make gitflow-status                    # Check current status
./scripts/gitflow.sh feature start dark-mode

# Or manually:
git checkout develop
git checkout -b feature/dark-mode
```

### Developing the Feature
```bash
# Work on your feature on the feature/dark-mode branch
git add .
git commit -m "Add dark mode toggle"

# Push regularly to remote
git push origin feature/dark-mode
```

### Finishing the Feature
```bash
# Merge feature back to develop
./scripts/gitflow.sh feature finish dark-mode

# Or manually:
git checkout develop
git merge --no-ff feature/dark-mode
git branch -d feature/dark-mode
git push origin develop
```

## Release Workflow

### Preparing a Release
```bash
# Start release branch from develop
./scripts/gitflow.sh release start 1.1.0

# Or manually:
git checkout develop
git checkout -b release/1.1.0
# Update VERSION file to 1.1.0
```

### Testing & Finalizing the Release
```bash
# Do final testing on release/1.1.0 branch
make build
make preview

# Commit last bug fixes
git add .
git commit -m "Fix release blocking bug"
```

### Publishing the Release
```bash
# Finish release (merge to main & develop, create tag)
./scripts/gitflow.sh release finish 1.1.0

# This automatically:
# 1. Merges to main
# 2. Creates tag v1.1.0
# 3. Merges back to develop
# 4. Cleans up branches
# 5. GitHub Actions automatically creates the release
```

## Hotfix Workflow

### Urgent Problem in Production
```bash
# Start hotfix from main
./scripts/gitflow.sh hotfix start 1.0.1

# Or manually:
git checkout main
git checkout -b hotfix/1.0.1
```

### Implementing the Hotfix
```bash
# Fix the problem
git add .
git commit -m "Fix critical production bug"
```

### Deploying the Hotfix
```bash
# Finish hotfix
./scripts/gitflow.sh hotfix finish 1.0.1

# This automatically:
# 1. Merges to main
# 2. Creates tag v1.0.1
# 3. Merges to develop
# 4. Cleans up branches
```

## Makefile Commands

```bash
# Check gitflow status
make gitflow-status

# Initialize gitflow
make gitflow-init

# Clean up merged branches
make gitflow-cleanup

# Releases (using Gitflow)
make release-patch     # v1.0.0 → v1.0.1
make release-beta      # v1.0.1-beta.1
make release-rc        # v1.0.1-rc.1
```

## Complete Workflow Examples

### Feature Development
```bash
# 1. Start feature
./scripts/gitflow.sh feature start user-preferences

# 2. Develop feature
git commit -m "Add user preferences panel"
git commit -m "Add settings persistence"

# 3. Finish feature
./scripts/gitflow.sh feature finish user-preferences
```

### Release Process
```bash
# 1. Start release
./scripts/gitflow.sh release start 1.1.0

# 2. Final testing
make ci

# 3. Release to production
./scripts/gitflow.sh release finish 1.1.0
```

### Hotfix Process
```bash
# 1. Urgent bug discovered
./scripts/gitflow.sh hotfix start 1.0.1

# 2. Apply fix
git commit -m "Fix crash on startup"

# 3. Deploy immediately
./scripts/gitflow.sh hotfix finish 1.0.1
```

## Best Practices

### Branches
- Use descriptive names: `feature/user-auth`, `hotfix/crash-fix`
- Commit regularly with clear messages
- Push feature branches to remote for backup

### Merges
- Always use `--no-ff` merges for traceability
- Merge commits should have clear messages
- Delete merged branches to keep history clean

### Releases
- Test releases thoroughly before finishing
- Use semantic versioning (major.minor.patch)
- Use beta releases for early testing
- Use RC (release candidate) for final validation

### Hotfixes
- Only for critical production problems
- Minimal changes - fix only the specific problem
- Test thoroughly before deploying

## Troubleshooting

### Branch Conflicts
```bash
# When merge conflicts occur:
git status                    # View conflicting files
# Edit files to resolve conflicts
git add <resolved-files>
git commit                    # Gitflow script creates merge commit automatically
```

### Wrong Branch
```bash
# Check current branch
git branch

# Switch to correct branch
git checkout develop
```

### Remote Sync Issues
```bash
# Force push if needed (be careful!)
git push origin feature/my-feature --force-with-lease

# Or rebase on remote
git fetch origin
git rebase origin/develop
```

## Gitflow Status

Always check status before starting:

```bash
./scripts/gitflow.sh status
```

This shows:
- Current branch
- Active feature/release/hotfix branches
- Recent commits

## Benefits of Gitflow

- **Organized development** - Clear roles per branch
- **Parallel development** - Multiple features simultaneously
- **Release stability** - Dedicated release preparation
- **Hotfix capability** - Fast production fixes
- **Clean history** - Traceable merges and tags
- **Team collaboration** - Clear workflow for everyone

---

**Gitflow enables professional software development!**
