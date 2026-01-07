# Znajdź Termin - Support Website

Support website for the Znajdź Termin iOS app, designed for Apple App Store review.

## Languages Supported

- 🇬🇧 English (default)
- 🇵🇱 Polish (Polski)
- 🇺🇦 Ukrainian (Українська)
- 🇷🇺 Russian (Русский)

## Structure

```
znajdz-termin/
├── index.html          # English (default)
├── privacy.html        # Privacy Policy (English)
├── terms.html          # Terms of Service (English)
├── app-ads.txt         # AdMob app-ads.txt (IAB Tech Lab spec)
├── style.css           # Shared styles
├── pl/
│   ├── index.html      # Polish
│   ├── privacy.html    # Privacy Policy (Polish)
│   └── terms.html      # Terms of Service (Polish)
├── uk/
│   ├── index.html      # Ukrainian
│   ├── privacy.html    # Privacy Policy (Ukrainian)
│   └── terms.html      # Terms of Service (Ukrainian)
├── ru/
│   ├── index.html      # Russian
│   ├── privacy.html    # Privacy Policy (Russian)
│   └── terms.html      # Terms of Service (Russian)
└── README.md           # This file
```

## Setup for GitHub Pages

1. **Create a new GitHub repository** named `znajdz-termin`

2. **Push this folder to GitHub**:
   ```bash
   cd znajdz-termin
   git init
   git add .
   git commit -m "Initial commit - support site"
   git branch -M main
   git remote add origin https://github.com/bigkrzyh/znajdz-termin.git
   git push -u origin main
   ```

3. **Enable GitHub Pages**:
   - Go to repository Settings → Pages
   - Under "Source", select `main` branch
   - Click Save
   - Your site will be available at: `https://bigkrzyh.github.io/znajdz-termin/`

## URLs for App Store Connect

After setting up GitHub Pages, use these URLs in App Store Connect:

- **Support URL**: `https://bigkrzyh.github.io/znajdz-termin/`
- **Privacy Policy URL**: `https://bigkrzyh.github.io/znajdz-termin/privacy.html`
- **Terms of Service URL**: `https://bigkrzyh.github.io/znajdz-termin/terms.html`
- **app-ads.txt URL**: `https://bigkrzyh.github.io/znajdz-termin/app-ads.txt`

## App Store Privacy Labels

When submitting to App Store, use this information for Privacy Labels:

| Data Type | Collected | Purpose | Linked to User | Tracking |
|-----------|-----------|---------|----------------|----------|
| Coarse Location | Yes | App Functionality | No | No |
| Device ID | Yes (via AdMob) | Advertising | No | Yes |
| Usage Data | Yes (via AdMob) | Advertising | No | Yes |

## App-ads.txt (Google AdMob)

The `app-ads.txt` file is required by Google AdMob for authorized sellers verification. This file follows the IAB Tech Lab specification.

### Contents
```
google.com, pub-2092028258025749, DIRECT, f08c47fec0942fa0
```

### Setup Instructions (Polish/Polski)

1. **Upewnij się, że plik app-ads.txt został utworzony na podstawie specyfikacji podanej przez IAB Tech Lab.**
   - Plik jest już utworzony w tym repozytorium.

2. **Opublikuj plik app-ads.txt w domenie głównej swojej witryny, do której masz uprawnienia dewelopera.**
   - Po wdrożeniu GitHub Pages plik będzie dostępny pod adresem:
   - `https://bigkrzyh.github.io/znajdz-termin/app-ads.txt`

3. **Zindeksuj plik app-ads.txt, aby umożliwić weryfikację aplikacji.**
   - Google automatycznie zindeksuje plik.
   - Przeprowadzi kilka testów, aby upewnić się, że plik app-ads.txt można znaleźć i że jest prawidłowo sformatowany.
   - Zwykle zajmuje to chwilę, ale w niektórych przypadkach może potrwać dłużej.

### Verification URL
After GitHub Pages deployment:
- **app-ads.txt URL**: `https://bigkrzyh.github.io/znajdz-termin/app-ads.txt`

## App Tracking Transparency (ATT)

The app implements Apple's App Tracking Transparency framework:

1. **Permission Request**: The ATT permission dialog appears when the app becomes active for the first time
2. **Timing**: Request is shown after a 1-second delay to ensure proper display
3. **Ad Loading**: Ads are only loaded AFTER the user responds to the ATT prompt
4. **Non-personalized Ads**: If user denies tracking, non-personalized ads are shown

### ATT Implementation Details
- Framework: `AppTrackingTransparency`
- Permission Key: `NSUserTrackingUsageDescription`
- Message (Polish): "Ta aplikacja używa identyfikatora reklamowego do wyświetlania spersonalizowanych reklam."

## Customization

Before publishing, update the following:

1. **Email address**: Currently set to `bigkrzyh@gmail.com`
2. **Copyright**: Update year if needed in footer sections

## Features

- 🌐 Multilingual (English, Polish, Ukrainian, Russian)
- 📱 Mobile responsive design
- 🎨 iOS-style design language
- 📋 FAQ section
- 🔒 Privacy Policy (includes advertising disclosure)
- ♿ Accessible
- 📢 Ad-supported (Google AdMob)

## License

© 2025 Znajdź Termin. All rights reserved.

