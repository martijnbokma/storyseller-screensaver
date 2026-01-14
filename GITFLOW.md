# Gitflow Workflow Guide

Deze gids legt uit hoe we Gitflow gebruiken voor de StorySellerSaver development workflow.

## 🎯 Gitflow Overzicht

Gitflow is een branching model dat helpt bij het organiseren van development, releases en hotfixes. Het gebruikt verschillende branches voor verschillende doeleinden.

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

## 🌿 Branch Structuur

### Permanente Branches
- **`main`** - Productie releases (alleen merges, geen direct commits)
- **`develop`** - Integratie branch voor features

### Temporaire Branches
- **`feature/*`** - Nieuwe features
- **`release/*`** - Release voorbereiding
- **`hotfix/*`** - Dringende productie fixes

## 🚀 Workflow voor Features

### Nieuwe Feature Starten
```bash
# Start een nieuwe feature
make gitflow-status                    # Bekijk huidige status
./scripts/gitflow.sh feature start dark-mode

# Of handmatig:
git checkout develop
git checkout -b feature/dark-mode
```

### Feature Ontwikkelen
```bash
# Werk aan je feature op de feature/dark-mode branch
git add .
git commit -m "Add dark mode toggle"

# Push regelmatig naar remote
git push origin feature/dark-mode
```

### Feature Afronden
```bash
# Merge feature terug naar develop
./scripts/gitflow.sh feature finish dark-mode

# Of handmatig:
git checkout develop
git merge --no-ff feature/dark-mode
git branch -d feature/dark-mode
git push origin develop
```

## 📦 Release Workflow

### Release Voorbereiden
```bash
# Start release branch vanaf develop
./scripts/gitflow.sh release start 1.1.0

# Of handmatig:
git checkout develop
git checkout -b release/1.1.0
# Update VERSION file naar 1.1.0
```

### Release Testen & Finaliseren
```bash
# Doe final testing op release/1.1.0 branch
make build
make preview

# Commit laatste bug fixes
git add .
git commit -m "Fix release blocking bug"
```

### Release Publiceren
```bash
# Finish release (merge naar main & develop, create tag)
./scripts/gitflow.sh release finish 1.1.0

# Dit doet automatisch:
# 1. Merge naar main
# 2. Tag v1.1.0 aanmaken
# 3. Merge terug naar develop
# 4. Branches opruimen
# 5. GitHub Actions maakt automatisch de release
```

## 🔥 Hotfix Workflow

### Urgent Probleem in Productie
```bash
# Start hotfix vanaf main
./scripts/gitflow.sh hotfix start 1.0.1

# Of handmatig:
git checkout main
git checkout -b hotfix/1.0.1
```

### Hotfix Implementeren
```bash
# Fix het probleem
git add .
git commit -m "Fix critical production bug"
```

### Hotfix Deployen
```bash
# Finish hotfix
./scripts/gitflow.sh hotfix finish 1.0.1

# Dit doet automatisch:
# 1. Merge naar main
# 2. Tag v1.0.1 aanmaken
# 3. Merge naar develop
# 4. Branches opruimen
```

## 🛠️ Makefile Commando's

```bash
# Gitflow status bekijken
make gitflow-status

# Gitflow initialiseren
make gitflow-init

# Opgeschoonde merged branches
make gitflow-cleanup

# Releases (werken met Gitflow)
make release-patch     # v1.0.0 → v1.0.1
make release-beta      # v1.0.1-beta.1
make release-rc        # v1.0.1-rc.1
```

## 📋 Voorbeelden van Complete Workflows

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

## 🎯 Best Practices

### Branches
- Gebruik beschrijvende namen: `feature/user-auth`, `hotfix/crash-fix`
- Commit regelmatig met duidelijke berichten
- Push feature branches naar remote voor backup

### Merges
- Altijd `--no-ff` merges gebruiken voor traceability
- Merge commits krijgen duidelijke berichten
- Delete merged branches om clean history te houden

### Releases
- Test releases grondig voordat finish
- Gebruik semantic versioning (major.minor.patch)
- Beta releases voor early testing
- RC (release candidate) voor final validation

### Hotfixes
- Alleen voor kritieke productie problemen
- Minimal changes - fix alleen het specifieke probleem
- Test grondig voordat deployen

## 🔧 Troubleshooting

### Branch Conflicten
```bash
# Bij merge conflicten:
git status                    # Bekijk conflicterende files
# Edit files om conflicten op te lossen
git add <resolved-files>
git commit                    # Gitflow script maakt automatisch merge commit
```

### Verkeerde Branch
```bash
# Check huidige branch
git branch

# Switch naar juiste branch
git checkout develop
```

### Remote Sync Problemen
```bash
# Force push als nodig (voorzichtig!)
git push origin feature/my-feature --force-with-lease

# Of rebase op remote
git fetch origin
git rebase origin/develop
```

## 📊 Gitflow Status

Bekijk altijd de status voor je begint:

```bash
./scripts/gitflow.sh status
```

Dit toont:
- Huidige branch
- Actieve feature/release/hotfix branches
- Recente commits

## 🎉 Voordelen van Gitflow

- **Georganiseerde development** - Duidelijke rollen per branch
- **Parallelle development** - Meerdere features tegelijk
- **Release stability** - Dedicated release preparation
- **Hotfix capability** - Snelle productie fixes
- **Clean history** - Traceerbare merges en tags
- **Team collaboration** - Duidelijke workflow voor iedereen

---

**Gitflow maakt professionele software development mogelijk!** 🚀✨