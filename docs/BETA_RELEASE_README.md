# StorySeller Screensaver - Beta Release Guide

## 🚀 Een Beta Release Maken

Volg deze stappen om automatisch een beta release te maken die GitHub Actions triggert:

### 📋 Vereisten

1. **GitHub Repository**: Maak eerst een repository aan op GitHub
2. **Remote Configureren**: Voeg de GitHub remote toe aan je lokale repository

### ⚙️ Setup (Eenmalig)

```bash
# 1. Maak een nieuwe repository aan op GitHub
#    Ga naar https://github.com/new en maak een repository aan

# 2. Voeg GitHub remote toe aan je lokale repository
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git

# 3. Push je main branch naar GitHub
git push -u origin main
```

### 🎯 Beta Release Maken

```bash
# Eenvoudigste manier - auto-generate versie
./scripts/create-beta-release.sh

# Of specificeer een versie
./scripts/create-beta-release.sh 1.1.0
```

### 🔄 Wat Gebeurt Er Automatisch?

1. **Lokale Tag**: Script maakt een `v1.x.x-beta.x` tag aan
2. **Push naar GitHub**: Tag wordt gepusht naar GitHub
3. **GitHub Actions**: Triggerd automatisch de release workflow
4. **Build & Package**: Actions bouwt de screensaver in Release mode
5. **GitHub Release**: Creëert automatisch een release met het zip bestand
6. **Pre-Release Markering**: Wordt gemarkeerd als pre-release

### 📊 Release Process

```
Je Terminal Command → Git Tag → GitHub Push → Actions Trigger → Build → Package → Release
```

### 🎉 Resultaat

Na een paar minuten verschijnt er automatisch een nieuwe release op GitHub met:
- ✅ `StorySellerSaver-v1.x.x-beta.x.zip` bestand
- ✅ Gedetailleerde release notes
- ✅ Pre-release markering
- ✅ Download link voor testers

### 🧩 Installatie (voor testers)

1. Download het zip-bestand uit de GitHub Release
2. Pak het zip-bestand uit
3. Dubbelklik `StorySellerSaver.saver` om te installeren
4. Open System Settings → Screen Saver
5. Als macOS de screensaver blokkeert, voer dit uit:

```bash
xattr -dr com.apple.quarantine ~/Library/Screen\ Savers/StorySellerSaver.saver
```

### 🐛 Troubleshooting

**"No GitHub remote configured!"**
```bash
# Voeg remote toe
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
git push -u origin main
```

**"Must be on main branch"**
```bash
git checkout main
```

**"Main branch has uncommitted changes"**
```bash
git status
git add .
git commit -m "Your commit message"
```

### 📝 Voorbeeld Output

```
ℹ️   Creating beta release: v1.0.0-beta.2
ℹ️   Pushing beta tag to GitHub...
✅  Beta release v1.0.0-beta.2 pushed to GitHub!
ℹ️   GitHub Actions will automatically:
     - Build the screensaver in Release configuration
     - Package it as StorySellerSaver-v1.0.0-beta.2.zip
     - Create a GitHub release with the package
     - Mark it as a pre-release
✅  Beta release v1.0.0-beta.2 is being processed by GitHub Actions!
ℹ️   Check your repository's Actions tab for progress
```

---

**🎊 Klaar! Met één command maak je professionele beta releases!**
