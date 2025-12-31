# Znajdź Termin - Support Website

Support website for the Znajdź Termin iOS app, designed for Apple App Store review.

## Structure

```
znajdz-termin-support/
├── index.html          # English (default)
├── privacy.html        # Privacy Policy (English)
├── pl/
│   ├── index.html      # Polish
│   └── privacy.html    # Privacy Policy (Polish)
├── style.css           # Shared styles
└── README.md           # This file
```

## Setup for GitHub Pages

1. **Create a new GitHub repository** named `znajdz-termin-support`

2. **Push this folder to GitHub**:
   ```bash
   cd znajdz-termin-support
   git init
   git add .
   git commit -m "Initial commit - support site"
   git branch -M main
   git remote add origin https://github.com/YOUR_USERNAME/znajdz-termin-support.git
   git push -u origin main
   ```

3. **Enable GitHub Pages**:
   - Go to repository Settings → Pages
   - Under "Source", select `main` branch
   - Click Save
   - Your site will be available at: `https://YOUR_USERNAME.github.io/znajdz-termin-support/`

## URLs for App Store Connect

After setting up GitHub Pages, use these URLs in App Store Connect:

- **Support URL**: `https://YOUR_USERNAME.github.io/znajdz-termin-support/`
- **Privacy Policy URL**: `https://YOUR_USERNAME.github.io/znajdz-termin-support/privacy.html`

## Customization

Before publishing, update the following:

1. **Email address**: Replace `support@example.com` with your actual email in all HTML files
2. **Copyright**: Update year if needed in footer sections

## Features

- 🌐 Bilingual (English & Polish)
- 📱 Mobile responsive design
- 🎨 iOS-style design language
- 📋 FAQ section
- 🔒 Privacy Policy
- ♿ Accessible

## License

© 2025 Znajdź Termin. All rights reserved.

