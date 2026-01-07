# NFZ Znajdz - Complete Project Specification

## PROJECT OVERVIEW
iOS app to search Polish National Health Fund (NFZ) doctor appointments. The app scrapes download links from the NFZ website, downloads Excel files per voivodeship, parses them, and provides a user-friendly search interface with GPS-based distance calculations.

**Goal**: Create a friendly UI app to search appointments and provide users with all useful information about available appointments and contact info for selected facilities with distance in km from current user location or last known position.

## TECHNICAL STACK

### Requirements
- **Platform:** iOS 16.0+
- **Language:** Swift 5.9+
- **IDE:** Xcode 15.0+
- **Frameworks:** SwiftUI, SwiftData, CoreLocation, Combine
- **Dependencies:** ZIPFoundation (Swift Package) - https://github.com/weichsel/ZIPFoundation, min version 0.9.20

### Build Configuration
- **Bundle ID:** `AJWA.NFZ-Znajdz`
- **Info.plist:** Auto-generated (`GENERATE_INFOPLIST_FILE = YES`)
- **Location Permission:** `INFOPLIST_KEY_NSLocationWhenInUseUsageDescription = "This app needs your location to determine your voivodeship and calculate distances to medical facilities."`

## DATA SOURCE & DOWNLOAD STRATEGY

### Website Scraping
- **Download Page URL:** `https://terminyleczenia.nfz.gov.pl/Download`
- **Strategy:** Scrape the download page HTML to extract actual download links for each voivodeship
- **Method:** Parse HTML to find links near voivodeship names (e.g., "Plik danych dla województwa: mazowieckie")
- **Fallback:** If scraping fails, use hardcoded file IDs (see below)

### Download Links Extraction
The `/Download` page contains hyperlinks to Excel files for each voivodeship. The scraper should:
1. Download the HTML page
2. Find all `<a>` tags with `href` attributes
3. Match links to voivodeships by:
   - Proximity to voivodeship name in HTML (within 500 characters)
   - Link text containing voivodeship name
   - URL containing "DownloadFile" or ".xlsx"
4. Make relative URLs absolute by prepending base URL: `https://terminyleczenia.nfz.gov.pl`
5. Cache extracted URLs for future use (avoid re-scraping on every download)

### Base URL
- **Base URL:** `https://terminyleczenia.nfz.gov.pl`
- **File Format:** Excel .xlsx (ZIP archive containing XML)
- **Update Frequency:** Monthly (files represent state at end of month)

### Fallback File IDs (if scraping fails)
```
"dolnośląskie": "45fc5762-77c1-ce0c-e063-b4200a0a3c21"
"kujawsko-pomorskie": "45fc5762-77c2-ce0c-e063-b4200a0a3c21"
"lubelskie": "45fc5762-77c3-ce0c-e063-b4200a0a3c21"
"lubuskie": "45fc5762-77c4-ce0c-e063-b4200a0a3c21"
"łódzkie": "45fc5762-77c5-ce0c-e063-b4200a0a3c21"
"małopolskie": "45fc5762-77c6-ce0c-e063-b4200a0a3c21"
"mazowieckie": "45fc5762-77c7-ce0c-e063-b4200a0a3c21"
"opolskie": "45fc5762-77c8-ce0c-e063-b4200a0a3c21"
"podkarpackie": "45fc5762-77c9-ce0c-e063-b4200a0a3c21"
"podlaskie": "45fc5762-77ca-ce0c-e063-b4200a0a3c21"
"pomorskie": "45fc5762-77cb-ce0c-e063-b4200a0a3c21"
"śląskie": "45fc5762-77cc-ce0c-e063-b4200a0a3c21"
"świętokrzyskie": "45fc5762-77cd-ce0c-e063-b4200a0a3c21"
"warmińsko-mazurskie": "45fc5762-77ce-ce0c-e063-b4200a0a3c21"
"wielkopolskie": "45fc5762-77cf-ce0c-e063-b4200a0a3c21"
"zachodniopomorskie": "45fc5762-77d0-ce0c-e063-b4200a0a3c21"
```

## DATA MODELS

### Appointment (SwiftData Model)
```swift
@Model
final class Appointment {
    var voivodeship: String
    var facilityName: String
    var serviceName: String  // "Nazwa świadczenia"
    var location: String
    var firstAvailableDate: String?
    var waitingTime: String?
    var phoneNumber: String?  // Extracted from "Adres komórki"
    var address: String?      // Extracted from "Adres komórki"
    var numberOfWaiting: Int? // "Liczba oczekujących"
    var distance: Double?     // km from user (if GPS available)
    var lastUpdated: Date
}
```

### Voivodeship Enum
16 Polish voivodeships with:
- `rawValue`: lowercase Polish name
- `displayName`: capitalized
- `id`: String (for Identifiable)
- `fileID`: String (for fallback downloads)
- `centerCoordinates`: (lat: Double, lon: Double)
- Static method: `from(latitude:longitude:)` to detect voivodeship from GPS

**Cases:** dolnoslaskie, kujawskoPomorskie, lubelskie, lubuskie, lodzkie, malopolskie, mazowieckie, opolskie, podkarpackie, podlaskie, pomorskie, slaskie, swietokrzyskie, warminskoMazurskie, wielkopolskie, zachodniopomorskie

## EXCEL PARSING SPECIFICATIONS

### File Structure
- **Headers:** Row 3 (index 2) - Polish column names (but check row 2/index 1 as well)
- **First Column:** "Rok" (Year) - use this to identify header row
- **Last Column:** "Data przygotowania informacji o pierwszym wolnym terminie"
- **Data Start:** Row 4 (index 3) or after detected header row
- **Format:** .xlsx (ZIP archive containing XML files)

### Required XML Files
- `xl/sharedStrings.xml` (optional - some files use inline values)
- `xl/worksheets/sheet1.xml` (required)

### Column Identification (Polish Headers)
The parser must be flexible and handle variations:
- **"Nazwa świadczenia"** → serviceName (REQUIRED)
- **"Nazwa placówki"** or **"Nazwa jednostki"** → facilityName (REQUIRED)
- **"Miejscowość"** or **"Miasto"** → location (REQUIRED)
- **"Adres komórki"** → cellAddress (contains phone + address)
- **"Liczba oczekujących"** → numberWaiting
- **"Data"** or **"Termin"** → date (but NOT "Data przygotowania informacji...")
- **"Czas"** or **"Oczekiwania"** → waiting

### Header Detection Strategy
1. Check row 2 (index 1) first - look for "Rok" as first column
2. If not found, check row 3 (index 2)
3. If still not found, check row 1 (index 0)
4. Use the row that contains "Rok" as first column
5. Start parsing data from the row after the header row
6. Log all headers found for debugging

### Excel Cell Structure
- Excel uses cell references with `r` attribute: `<c r="A1">`, `<c r="B1">`, etc.
- Parse cells by column letter (A=0, B=1, ..., Z=25, AA=26, etc.)
- Map cells to column indices using `columnLetterToIndex()` function
- Handle both shared strings and inline text values
- Fallback to sequential parsing if cell references aren't found

### Phone/Address Extraction Algorithm
Parse "Adres komórki" string:
1. Find phone using regex patterns (try in order):
   - `\+?48\s?[\d\s\-\(\)]{9,}` (Polish +48 format)
   - `\(\d{2,3}\)\s?\d{3}[\s\-]?\d{3}[\s\-]?\d{3}`
   - `\d{3}[\s\-]?\d{3}[\s\-]?\d{3}`
   - `\d{9,}` (9+ digits)
2. Extract address as remaining text (before/after phone)
3. Clean address: normalize whitespace, remove phone number

### Column Letter to Index Conversion
```swift
func columnLetterToIndex(_ letter: String) -> Int {
    var index = 0
    for char in letter.uppercased() {
        index = index * 26 + (Int(char.asciiValue! - Character("A").asciiValue!) + 1)
    }
    return index - 1
}
```

## ZIP EXTRACTION (ZipFoundation)

### API Usage
```swift
// Create archive (throwing initializer)
let archive = try Archive(data: zipData, accessMode: .read)

// Extract file (closure-based)
var data = Data()
try archive.extract(entry) { chunk in
    data.append(chunk)
}
```

### Files to Extract
- `xl/sharedStrings.xml` (optional)
- `xl/worksheets/sheet1.xml` (required)

### Validation Strategy
**CRITICAL:** Don't validate ZIP signature first. Instead:
1. Try to parse the file directly
2. If parsing succeeds, the file is valid (regardless of ZIP signature)
3. Only check ZIP signature if parsing fails (for debugging)
4. Check for HTML responses (error pages) before attempting to parse
5. Log first bytes of invalid data for debugging

## CORE FEATURES & BEHAVIOR

### App Launch
1. **First Run:**
   - Request location permission
   - Wait 2 seconds for GPS
   - Determine voivodeship from GPS or default to `mazowieckie`
   - Always download mazowieckie file if not present
   - Download file in background (no UI loading indicator)
   - Don't show search results on launch
   - Populate service name combo box with data from mazowieckie

2. **Subsequent Runs:**
   - Restore last used voivodeship
   - Check cache for data
   - Don't auto-update files (only when user requests)
   - Don't show search results on launch

### Data Download & Caching
- **Download Strategy:**
  1. First, scrape `/Download` page to get actual download URLs
  2. Cache extracted URLs for future use
  3. Use scraped URLs to download Excel files
  4. Fallback to hardcoded file IDs if scraping fails
  
- **Cache Management:**
  - Cache directory: `~/Library/Caches/NFZFiles/`
  - File naming: `{voivodeship}.xlsx`
  - Metadata: `{voivodeship}.xlsx.metadata` (JSON with lastUpdate date)
  - Check cache before download (unless forceRefresh)
  - Validate cached files by attempting to parse them
  - Only download when:
    - File doesn't exist in cache
    - User explicitly requests refresh (pull-to-refresh or refresh button)
    - Data is missing from database

### Pull-to-Refresh
- **Implementation:** Use SwiftUI's `.refreshable` modifier on ScrollView
- **Behavior:**
  - User drags down on results list to refresh
  - Show native iOS refresh indicator
  - Re-scrape download page to get latest URLs
  - Download and update all cached files (force refresh)
  - Re-parse and update database
  - Update UI with fresh data
  - Hide refresh indicator when complete
- **Trigger:** Only when user explicitly pulls down (not automatic)

### Search Functionality
- **Required:** Voivodeship selection
- **Optional:** Service name (combo box with search), Location (text field)
- **Results Display:** Only after "Szukaj" button clicked
- **Distance Calculation:** 
  - If GPS available, geocode addresses and calculate distances
  - Use last known location if current location unavailable
  - Calculate in background (non-blocking) to avoid UI freezing
  - Update UI when distances are ready
  - Sort results by distance (closest first) when available
- **Statistics:** Sum of "Liczba oczekujących" only when voivodeship + service name selected
- **Filtering:**
  - Service name: case-insensitive contains search
  - Location: case-insensitive contains search
  - Show all results for voivodeship when no filters applied

## UI COMPONENTS

### Main Screen Layout
1. **Header:**
   - Logo (Esculapius club/rod of Asclepius) + Title "Wyszukiwarka Terminów NFZ"
   - Refresh button (manual refresh)
   
2. **Filters:**
   - Voivodeship picker (button → sheet with list)
   - Service name picker (button → sheet with searchable combo box)
   - Location text field (with placeholder "Miejscowość (opcjonalnie)")
   
3. **Search Button:**
   - Blue when enabled (voivodeship selected)
   - Gray when disabled
   - Shows loading indicator when searching
   - Text: "Szukaj"
   
4. **Results Area (with Pull-to-Refresh):**
   - Welcome message when no search performed: "Wybierz województwo i kliknij Szukaj"
   - Results list (after search) with pull-to-refresh
   - Error states with helpful messages and retry option
   - Empty states with suggestions
   - Loading states with progress indicator
   
5. **Bottom Info Bar:**
   - Current date (formatted in Polish): "Dzisiaj: [date]"
   - Last update date (when data was downloaded): "Dane zaktualizowane: [date]"
   - Statistics (when filters applied): "Liczba oczekujących: X"

### Result Row Display
Each appointment row shows (in order):
- **Facility name** (headline, bold)
- **Service name** (subheadline, stethoscope icon 🩺)
- **Location** (subheadline, map pin icon 📍)
- **First available date** (if available, blue, calendar icon 📅)
- **Waiting time** (if available, orange, clock icon ⏰)
- **Number waiting** (if available, red, people icon 👥, format: "Liczba oczekujących: X")
- **Address** (if available, blue, house icon 🏠)
- **Phone** (if available, green, phone icon 📞, tappable to call)
- **Distance** (if GPS available, purple, location icon 📍, format: "Odległość: X.X km")

### Logo Component
- **App Icon:** Esculapius club (Rod of Asclepius) - single snake wrapped around a staff
  - Should be professional and recognizable
  - Recommended: 1024x1024 PNG
  - Colors: Blue/teal with white, or red with white
- **In-App Logo:** Red circle with white cross (medical symbol)
  - Circle: `Color.red`, size configurable
  - Cross: Two white rounded rectangles (horizontal + vertical)

### Error Display
- Show error icon (⚠️)
- Display user-friendly Polish error message
- Provide helpful suggestions (e.g., "Sprawdź połączenie internetowe i spróbuj ponownie")
- Allow retry action when appropriate

## GPS & LOCATION

### Voivodeship Detection
Approximate center coordinates (lat, lon):
- dolnośląskie: (51.1, 17.0)
- kujawsko-pomorskie: (53.0, 18.5)
- lubelskie: (51.2, 22.6)
- lubuskie: (52.0, 15.5)
- łódzkie: (51.8, 19.5)
- małopolskie: (50.1, 19.9)
- mazowieckie: (52.2, 21.0)
- opolskie: (50.7, 17.9)
- podkarpackie: (50.0, 22.0)
- podlaskie: (53.1, 23.2)
- pomorskie: (54.4, 18.6)
- śląskie: (50.3, 19.0)
- świętokrzyskie: (50.9, 20.6)
- warmińsko-mazurskie: (53.8, 20.5)
- wielkopolskie: (52.4, 16.9)
- zachodniopomorskie: (53.4, 14.6)

**Algorithm:** Calculate Euclidean distance to find closest voivodeship center.

### Distance Calculation
1. Use current location if available
2. Fallback to last known location if current unavailable
3. Geocode full address using `CLGeocoder.geocodeAddressString()` with format: "{address}, {location}, Polska"
4. If fails, geocode location name only: "{location}, Polska"
5. Use `CLLocation.distance(from:)` and convert meters to kilometers
6. Calculate in background (non-blocking) to avoid UI freezing
7. Update UI when distances are ready
8. Sort results by distance (closest first) when available

## FILE STRUCTURE (13 Swift Files)

1. **Znajdz_TerminApp.swift** - App entry, SwiftData setup
2. **ContentView.swift** - Main UI with pull-to-refresh
3. **Appointment.swift** - Data model + Voivodeship enum
4. **NFZService.swift** - Business logic (@MainActor ObservableObject)
5. **ExcelParser.swift** - Excel parsing logic
6. **ZIPExtractor.swift** - ZIP extraction wrapper
7. **FileCacheManager.swift** - Local file caching (singleton)
8. **LocationManager.swift** - GPS handling (@MainActor, CLLocationManagerDelegate)
9. **DownloadPageScraper.swift** - HTML scraping for download URLs
10. **AppointmentRowView.swift** - Result row component
11. **VoivodeshipPickerView.swift** - Voivodeship selection sheet
12. **ServiceNamePickerView.swift** - Service name selection sheet with search
13. **LogoView.swift** - Medical logo component

## KEY IMPLEMENTATION DETAILS

### Download Flow
1. Check cache for file existence
2. If cached, validate by attempting to parse
3. If valid cached file exists, use it
4. Otherwise, scrape `/Download` page for URLs (if not already cached)
5. Extract download URL for requested voivodeship
6. Download file using extracted URL
7. Check Content-Type header - if HTML, it's an error
8. Validate by attempting to parse (not by ZIP signature)
9. Save to cache if parsing succeeds
10. Parse and store in database

### Excel Parsing Flow
1. Extract XML files using ZipFoundation (don't validate signature first)
2. Parse sharedStrings.xml (optional) - extract all `<t>` text values
3. Parse sheet1.xml rows using regex patterns:
   - Find all `<row>` elements
   - For each row, find all `<c>` cells with `r` attribute
   - Map cells by column letter to index
   - Extract values from shared strings or inline text
4. Find header row (look for "Rok" in first column, check rows 1, 2, 3)
5. Identify columns from header row (flexible matching, case-insensitive)
6. Parse data rows starting after header row
7. Extract phone/address from "Adres komórki" column using regex
8. Create Appointment objects
9. Return array of appointments

### Error Handling
- **Network errors:** User-friendly Polish messages
- **Parse errors:** Detailed error with column information
- **Cache errors:** Silent fallback to download
- **HTML responses:** Detect and show appropriate error
- **Missing columns:** Log which columns were found vs required
- **Empty results:** Show helpful message, not error

### Date Formatting
- Locale: `pl_PL`
- Style: `.medium` date, `.short` time
- Format: "Dzisiaj: [formatted date]"
- Format: "Dane zaktualizowane: [formatted date]"

## UI TEXT (All Polish)
- "Wyszukiwarka Terminów NFZ"
- "Województwo"
- "Nazwa świadczenia (opcjonalnie)"
- "Miejscowość (opcjonalnie)"
- "Szukaj"
- "Wybierz województwo i kliknij Szukaj"
- "Brak wyników"
- "Znaleziono: X"
- "Liczba oczekujących: X"
- "Dzisiaj: [date]"
- "Dane zaktualizowane: [date]"
- "Odległość: X.X km"
- "Wyszukiwanie..."
- "Błąd pobierania danych: [error]"
- "Sprawdź połączenie internetowe i spróbuj ponownie."
- "Spróbuj zmienić kryteria wyszukiwania"

## APP ICON

### Esculapius Club (Rod of Asclepius)
- **Symbol:** Single snake wrapped around a staff/rod
- **Design Requirements:**
  - Medical symbol representing healing and medicine
  - Should be recognizable and professional
  - Can be minimalist or detailed
  - Recommended colors: Blue/teal with white, or red with white
  - Size: 1024x1024 PNG for AppIcon
  - Xcode will auto-generate all required sizes from 1024x1024

### Alternative: Use SF Symbols
- Can use medical symbols from SF Symbols in Xcode
- Or create custom vector/SVG icon

## PULL-TO-REFRESH IMPLEMENTATION

### SwiftUI Implementation
```swift
ScrollView {
    // Results content
}
.refreshable {
    await refreshData()
}
```

### Refresh Behavior
1. User drags down on results list
2. Show native iOS refresh indicator
3. Re-scrape download page to get latest URLs
4. Download all cached files (force refresh)
5. Re-parse and update database
6. Refresh UI with new data
7. Hide refresh indicator when complete
8. Show error if refresh fails

## BEST PRACTICES FOR AI AGENTS

### When Building This App:

1. **Download Strategy:**
   - Always scrape the `/Download` page first to get actual URLs
   - Don't rely on hardcoded file IDs (they may change)
   - Cache extracted URLs to avoid re-scraping on every download
   - Validate files by parsing, not by ZIP signature
   - Check Content-Type header to detect HTML error pages

2. **Parsing Strategy:**
   - Be flexible with header row detection (check multiple rows)
   - Look for "Rok" as first column to identify header row
   - Handle variations in column names (case-insensitive, partial matches)
   - Use flexible string matching
   - Log extensively for debugging (headers found, columns mapped, rows parsed)
   - Don't fail on missing optional columns
   - Handle both shared strings and inline text values

3. **Error Handling:**
   - Always show user-friendly messages in Polish
   - Provide actionable suggestions
   - Log detailed errors to console for debugging
   - Don't block UI on network operations
   - Show specific errors (network, parsing, missing data)

4. **Performance:**
   - Calculate distances in background (non-blocking)
   - Show results immediately, update with distances later
   - Cache aggressively to reduce network calls
   - Only download when necessary (missing file or user requests)
   - Use async/await properly to avoid blocking

5. **UI/UX:**
   - Show loading states clearly
   - Provide helpful empty states
   - Make phone numbers tappable (use `tel:` URL scheme)
   - Sort by distance when available
   - Use pull-to-refresh for manual updates
   - Don't show results on launch (wait for user search)
   - Populate service name combo box on start with mazowieckie data

6. **Caching:**
   - Use SwiftData for appointment data (persistent storage)
   - Use file system cache for Excel files
   - Validate cached files before using
   - Only update when user requests or data is missing
   - Cache download URLs from scraping

7. **Location:**
   - Request permission on first launch
   - Use last known location if current unavailable
   - Calculate distances asynchronously
   - Don't block search results on distance calculation
   - Sort by distance after calculation completes

8. **Testing:**
   - Test with actual Excel files from NFZ website
   - Verify parsing works with different voivodeships
   - Test with and without GPS
   - Test pull-to-refresh functionality
   - Test error scenarios (no internet, invalid files, HTML responses)
   - Test cache validation
   - Test service name combo box population

## TESTING CHECKLIST
- [ ] First run downloads correct voivodeship
- [ ] Scraping extracts correct download URLs
- [ ] Pull-to-refresh works correctly
- [ ] Background cache validation works
- [ ] Search results display all fields
- [ ] Distance calculation with GPS
- [ ] Distance calculation with last known location
- [ ] Phone/address extraction
- [ ] Statistics calculation
- [ ] No results on launch
- [ ] Excel parsing (flexible header detection)
- [ ] ZIP extraction works
- [ ] Cache persists
- [ ] Service name combo box populates on start
- [ ] Mazowieckie always downloads on first run
- [ ] Phone numbers are tappable
- [ ] Error messages are user-friendly
- [ ] Refresh button works
- [ ] Files only download when needed or requested

## NOTES
- All UI text in Polish
- Date formatting uses Polish locale
- Download URLs should be scraped from website (may change)
- App icon should be Esculapius club (Rod of Asclepius)
- Background downloads don't show loading indicators (except pull-to-refresh)
- Use local storage (SwiftData) for appointments cache
- Use file system cache for Excel files
- Update files only when user requests or data is missing
- Always show results immediately, update distances asynchronously
- Validate files by parsing, not by format checks
- Be flexible with Excel structure (headers may vary)
- Log extensively for debugging
- Handle HTML error pages gracefully

## IMPLEMENTATION PRIORITIES

1. **Critical (Must Have):**
   - Scrape download page for URLs
   - Download and parse Excel files
   - Search functionality
   - Display results with all information
   - Cache management

2. **Important (Should Have):**
   - Pull-to-refresh
   - Distance calculation
   - Phone number extraction
   - Service name combo box
   - Error handling

3. **Nice to Have:**
   - Statistics calculation
   - GPS voivodeship detection
   - Last known location fallback
   - Advanced filtering

## COMMON PITFALLS TO AVOID

1. **Don't validate ZIP signature first** - parse the file instead
2. **Don't assume header row is always row 3** - check multiple rows
3. **Don't block UI on network operations** - use async/await
4. **Don't download automatically** - only when user requests or data missing
5. **Don't fail on missing optional columns** - only require essential ones
6. **Don't show results on launch** - wait for user search
7. **Don't hardcode file IDs** - scrape from website
8. **Don't block on distance calculation** - do it in background
9. **Don't assume Excel structure is consistent** - be flexible
10. **Don't ignore HTML error pages** - check Content-Type header
