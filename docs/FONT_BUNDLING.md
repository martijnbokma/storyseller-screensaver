# Font Bundling Guide - Cera Pro

## Overzicht

De screensaver gebruikt nu **Cera Pro** als primair font. Dit document legt uit hoe je het font kunt bundelen zodat alle gebruikers het font hebben, zelfs als ze het niet geïnstalleerd hebben.

## ⚠️ Belangrijk: Font Licentie

**Cera Pro is een commercieel font.** Controleer je licentie voordat je het font bundelt:

- ✅ **Toegestaan**: Als je licentie redistributie toestaat (bijv. "App Embedding" licentie)
- ❌ **Niet toegestaan**: Als je licentie alleen persoonlijk gebruik toestaat

**Zonder bundeling**: Gebruikers moeten Cera Pro zelf installeren, anders valt de screensaver terug op Poppins → Avenir → Helvetica → System Font.

## Optie 1: Font Bundelen (Aanbevolen)

### Stap 1: Font Bestanden Kopiëren

Kopieer de benodigde Cera Pro font bestanden naar de `StorySellerSaver` folder:

```bash
cd /Users/macgyver/Dropbox/Code/work/cb/screensaver/storyseller-screensaver

# Kopieer de font bestanden (minimaal Regular en Bold)
cp ~/Library/Fonts/Cera\ Pro\ Regular.otf StorySellerSaver/
cp ~/Library/Fonts/Cera\ Pro\ Bold.otf StorySellerSaver/
cp ~/Library/Fonts/Cera\ Pro\ Medium.otf StorySellerSaver/
cp ~/Library/Fonts/Cera\ Pro\ Light.otf StorySellerSaver/
cp ~/Library/Fonts/Cera\ Pro\ Black.otf StorySellerSaver/
```

### Stap 2: Fonts Toevoegen aan Xcode Project

1. Open `StorysellerScreensaver.xcodeproj` in Xcode
2. Selecteer de `StorySellerSaver` folder in de Project Navigator
3. Klik rechts-klik → "Add Files to StorySellerSaver..."
4. Selecteer alle `.otf` bestanden die je gekopieerd hebt
5. Zorg dat "Copy items if needed" **aan** staat
6. Zorg dat "Add to targets: StorySellerSaver" **aan** staat
7. Klik "Add"

### Stap 3: Fonts Registreren in Info.plist

Voeg de font bestandsnamen toe aan `StorySellerSaver/Info.plist`:

```xml
<key>ATSApplicationFontsPath</key>
<string>.</string>
```

Of expliciet de fonts opgeven:

```xml
<key>UIAppFonts</key>
<array>
    <string>Cera Pro Regular.otf</string>
    <string>Cera Pro Bold.otf</string>
    <string>Cera Pro Medium.otf</string>
    <string>Cera Pro Light.otf</string>
    <string>Cera Pro Black.otf</string>
</array>
```

**Let op**: Voor macOS screensavers is `ATSApplicationFontsPath` meestal voldoende - macOS laadt automatisch alle `.otf` en `.ttf` bestanden in de bundle.

### Stap 4: Build en Test

```bash
make build
make install
```

Test of het font werkt door de screensaver te openen. Als het font gebundeld is, werkt het zelfs op een Mac zonder Cera Pro geïnstalleerd.

## Optie 2: Font Niet Bundelen

Als je het font **niet** bundelt:

- ✅ **Voordeel**: Geen licentie problemen, kleinere bundle size
- ❌ **Nadeel**: Gebruikers moeten Cera Pro zelf installeren

De screensaver valt automatisch terug op:
1. Cera Pro (als geïnstalleerd)
2. Poppins (als geïnstalleerd)
3. Avenir Next (systeem font)
4. Helvetica Neue (systeem font)
5. System Font (altijd beschikbaar)

## Font Namen in Code

De code probeert meerdere naamconventies:

- `"Cera Pro Regular"` (volledige naam)
- `"CeraPro-Regular"` (PostScript naam)
- `"Cera Pro"` (familie naam)

Als een naam niet werkt, probeert de code automatisch de volgende in de lijst.

## Testen

Om te testen of het font werkt:

1. **Met font geïnstalleerd**: Open de screensaver - je zou Cera Pro moeten zien
2. **Zonder font** (test op andere Mac):
   - Verwijder tijdelijk Cera Pro uit `~/Library/Fonts/`
   - Open de screensaver
   - Als gebundeld: Cera Pro werkt nog steeds
   - Als niet gebundeld: Fallback fonts worden gebruikt

## Troubleshooting

### Font wordt niet geladen

1. **Check Xcode**: Zorg dat fonts in "Copy Bundle Resources" staan
   - Project Settings → Build Phases → Copy Bundle Resources
2. **Check Info.plist**: Voeg `ATSApplicationFontsPath` toe
3. **Check font namen**: Gebruik Font Book om de exacte PostScript naam te vinden

### Font werkt lokaal maar niet na distributie

- Zorg dat fonts in de Release build zitten
- Check of fonts in de `.saver` bundle zitten:
  ```bash
  ls -la ~/Library/Screen\ Savers/StorySellerSaver.saver/Contents/Resources/*.otf
  ```

## Huidige Status

✅ **Code geüpdatet**: Cera Pro is nu het primaire font  
⏳ **Font bundeling**: Nog niet geconfigureerd (optioneel)  
✅ **Fallback systeem**: Werkt automatisch als font niet beschikbaar is
