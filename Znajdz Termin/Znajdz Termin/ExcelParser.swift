//
//  ExcelParser.swift
//  Znajdz Termin
//
//  Created by Krzysztof Kuźmicki on 29/12/2025.
//

import Foundation

/// Result of parsing an Excel file
struct ParseResult {
    let appointments: [Appointment]
    let dataYear: String?
    let dataMonth: String?
    
    /// Formatted data date string
    var dataDateString: String? {
        guard let year = dataYear, let month = dataMonth else { return nil }
        
        let monthNames = [
            "1": "styczeń", "2": "luty", "3": "marzec", "4": "kwiecień",
            "5": "maj", "6": "czerwiec", "7": "lipiec", "8": "sierpień",
            "9": "wrzesień", "10": "październik", "11": "listopad", "12": "grudzień"
        ]
        
        let monthName = monthNames[month] ?? month
        return "\(monthName) \(year)"
    }
}

struct ExcelParser {
    
    static func parse(sharedStringsData: Data?, sheet1Data: Data, voivodeship: String) throws -> ParseResult {
        print("ExcelParser: Starting parse for \(voivodeship)")
        
        // Parse shared strings if available
        var sharedStrings: [String] = []
        if let sharedStringsData = sharedStringsData,
           let xmlString = String(data: sharedStringsData, encoding: .utf8) {
            sharedStrings = parseSharedStrings(xmlString)
            print("ExcelParser: Parsed \(sharedStrings.count) shared strings")
        }
        
        // Parse sheet1
        guard let sheet1String = String(data: sheet1Data, encoding: .utf8) else {
            throw NSError(domain: "ExcelParser", code: 1, userInfo: [NSLocalizedDescriptionKey: "Nie można odczytać pliku sheet1.xml"])
        }
        
        // Debug: Show first few shared strings
        if sharedStrings.count > 0 {
            print("ExcelParser: First 10 shared strings:")
            for i in 0..<min(10, sharedStrings.count) {
                print("  [\(i)] \(sharedStrings[i])")
            }
        }
        
        let rows = parseRows(from: sheet1String, sharedStrings: sharedStrings)
        print("ExcelParser: Parsed \(rows.count) rows")
        
        // Debug: Show first 3 rows
        print("ExcelParser: First 3 rows content:")
        for i in 0..<min(3, rows.count) {
            print("  Row \(i): \(rows[i].prefix(10))...")
        }
        
        guard rows.count > 0 else {
            throw NSError(domain: "ExcelParser", code: 2, userInfo: [NSLocalizedDescriptionKey: "Brak danych w pliku Excel"])
        }
        
        // Find header row - look for "Rok" in first column
        var headerRowIndex: Int?
        let rowsToCheck = min(5, rows.count)
        
        for i in 0..<rowsToCheck {
            let row = rows[i]
            if let firstValue = row.first, firstValue.lowercased().contains("rok") {
                headerRowIndex = i
                print("ExcelParser: Found header row at index \(i)")
                print("ExcelParser: Headers: \(row)")
                break
            }
        }
        
        // Try to find any row with expected headers if not already found
        if headerRowIndex == nil {
            for i in 0..<rowsToCheck {
                let row = rows[i]
                let rowText = row.joined(separator: " ").lowercased()
                if rowText.contains("nazwa świadczenia") || rowText.contains("nazwa placówki") {
                    headerRowIndex = i
                    print("ExcelParser: Found header row at index \(i) using alternative detection")
                    break
                }
            }
        }
        
        guard let headerIndex = headerRowIndex else {
            print("ExcelParser: Could not find header row. First 3 rows:")
            for i in 0..<min(3, rows.count) {
                print("Row \(i): \(rows[i])")
            }
            throw NSError(domain: "ExcelParser", code: 3, userInfo: [NSLocalizedDescriptionKey: "Nie znaleziono wiersza nagłówka"])
        }
        
        let finalHeaderIndex = headerIndex
        let headerRow = rows[finalHeaderIndex]
        
        // Map columns
        let columnMap = mapColumns(headerRow)
        print("ExcelParser: Column map: \(columnMap)")
        
        // Validate required columns
        guard let serviceNameCol = columnMap["serviceName"],
              let facilityNameCol = columnMap["facilityName"],
              let locationCol = columnMap["location"] else {
            let foundColumns = columnMap.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            print("ExcelParser: Missing required columns. Found: \(foundColumns)")
            throw NSError(domain: "ExcelParser", code: 4, userInfo: [NSLocalizedDescriptionKey: "Brakuje wymaganych kolumn. Znalezione: \(foundColumns)"])
        }
        
        // Extract data year and month from first data row
        var dataYear: String?
        var dataMonth: String?
        
        if rows.count > finalHeaderIndex + 1 {
            let firstDataRow = rows[finalHeaderIndex + 1]
            // Column 0 should be "Rok" (Year), Column 1 should be "Miesiąc" (Month)
            if let yearCol = columnMap["year"], yearCol < firstDataRow.count {
                dataYear = firstDataRow[yearCol].trimmingCharacters(in: .whitespacesAndNewlines)
            } else if firstDataRow.count > 0 {
                // Fallback: assume first column is year
                let value = firstDataRow[0].trimmingCharacters(in: .whitespacesAndNewlines)
                if value.count == 4, Int(value) != nil {
                    dataYear = value
                }
            }
            
            if let monthCol = columnMap["month"], monthCol < firstDataRow.count {
                dataMonth = firstDataRow[monthCol].trimmingCharacters(in: .whitespacesAndNewlines)
            } else if firstDataRow.count > 1 {
                // Fallback: assume second column is month
                let value = firstDataRow[1].trimmingCharacters(in: .whitespacesAndNewlines)
                if let monthNum = Int(value), monthNum >= 1 && monthNum <= 12 {
                    dataMonth = value
                }
            }
            
            print("ExcelParser: Data date - Year: \(dataYear ?? "unknown"), Month: \(dataMonth ?? "unknown")")
        }
        
        // Parse data rows
        var appointments: [Appointment] = []
        
        for i in (finalHeaderIndex + 1)..<rows.count {
            let row = rows[i]
            
            guard row.count > max(serviceNameCol, facilityNameCol, locationCol) else {
                continue
            }
            
            let serviceName = row[serviceNameCol].trimmingCharacters(in: .whitespacesAndNewlines)
            let facilityName = row[facilityNameCol].trimmingCharacters(in: .whitespacesAndNewlines)
            let cellAddressRaw = row[locationCol].trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty rows
            guard !serviceName.isEmpty, !facilityName.isEmpty, !cellAddressRaw.isEmpty else {
                continue
            }
            
            // Parse address field: "CITY;STREET;PHONE" or "CITY-DISTRICT;STREET;PHONE"
            let addressParts = cellAddressRaw.components(separatedBy: ";")
            let location = addressParts.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? cellAddressRaw
            
            // Extract full address and phone
            var phoneNumber: String?
            var address: String?
            if addressParts.count >= 2 {
                // Street is the second part
                let street = addressParts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                address = "\(location), \(street)"
            } else {
                address = location
            }
            if addressParts.count >= 3 {
                // Phone is the third part
                phoneNumber = addressParts[2].trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            // Get first available date
            var firstAvailableDate: String?
            if let col = columnMap["date"], col < row.count {
                let value = row[col].trimmingCharacters(in: .whitespacesAndNewlines)
                if !value.isEmpty { firstAvailableDate = value }
            }
            
            // Get waiting time
            var waitingTime: String?
            if let col = columnMap["waiting"], col < row.count {
                let value = row[col].trimmingCharacters(in: .whitespacesAndNewlines)
                if !value.isEmpty { waitingTime = "\(value) dni" }
            }
            
            // Get number waiting
            var numberOfWaiting: Int?
            if let col = columnMap["numberWaiting"], col < row.count {
                let value = row[col].trimmingCharacters(in: .whitespacesAndNewlines)
                numberOfWaiting = Int(value)
            }
            
            // Get medical category
            var medicalCategory: String?
            if let col = columnMap["category"], col < row.count {
                let value = row[col].trimmingCharacters(in: .whitespacesAndNewlines)
                if !value.isEmpty { medicalCategory = value }
            }
            
            let appointment = Appointment(
                voivodeship: voivodeship,
                facilityName: facilityName,
                serviceName: serviceName,
                location: location,
                firstAvailableDate: firstAvailableDate,
                waitingTime: waitingTime,
                phoneNumber: phoneNumber,
                address: address,
                numberOfWaiting: numberOfWaiting,
                medicalCategory: medicalCategory
            )
            appointments.append(appointment)
        }
        
        print("ExcelParser: Created \(appointments.count) appointments")
        return ParseResult(appointments: appointments, dataYear: dataYear, dataMonth: dataMonth)
    }
    
    private static func parseSharedStrings(_ xmlString: String) -> [String] {
        var strings: [String] = []
        
        // Match <si>...<t>text</t>...</si> or just <t>text</t>
        let siPattern = #"<si[^>]*>.*?<t[^>]*>([^<]*)</t>.*?</si>"#
        let tPattern = #"<t[^>]*>([^<]*)</t>"#
        
        // Try si pattern first
        if let regex = try? NSRegularExpression(pattern: siPattern, options: [.dotMatchesLineSeparators]) {
            let range = NSRange(xmlString.startIndex..<xmlString.endIndex, in: xmlString)
            regex.enumerateMatches(in: xmlString, options: [], range: range) { match, _, _ in
                if let match = match, let textRange = Range(match.range(at: 1), in: xmlString) {
                    strings.append(String(xmlString[textRange]))
                }
            }
        }
        
        // If no matches, try just t pattern
        if strings.isEmpty {
            if let regex = try? NSRegularExpression(pattern: tPattern, options: []) {
                let range = NSRange(xmlString.startIndex..<xmlString.endIndex, in: xmlString)
                regex.enumerateMatches(in: xmlString, options: [], range: range) { match, _, _ in
                    if let match = match, let textRange = Range(match.range(at: 1), in: xmlString) {
                        strings.append(String(xmlString[textRange]))
                    }
                }
            }
        }
        
        return strings
    }
    
    private static func parseRows(from xmlString: String, sharedStrings: [String]) -> [[String]] {
        var rows: [[String]] = []
        
        // Find all <row> elements
        let rowPattern = #"<row[^>]*>(.*?)</row>"#
        guard let rowRegex = try? NSRegularExpression(pattern: rowPattern, options: [.dotMatchesLineSeparators]) else {
            return rows
        }
        
        let range = NSRange(xmlString.startIndex..<xmlString.endIndex, in: xmlString)
        rowRegex.enumerateMatches(in: xmlString, options: [], range: range) { match, _, _ in
            guard let match = match, let rowRange = Range(match.range(at: 1), in: xmlString) else { return }
            let rowContent = String(xmlString[rowRange])
            let cells = parseCells(from: rowContent, sharedStrings: sharedStrings)
            if !cells.isEmpty {
                rows.append(cells)
            }
        }
        
        return rows
    }
    
    private static func parseCells(from rowContent: String, sharedStrings: [String]) -> [String] {
        var cellDict: [Int: String] = [:]
        var maxIndex = 0
        
        // Match entire <c>...</c> elements
        let cellPattern = #"<c\s+([^>]*)>(.*?)</c>"#
        guard let cellRegex = try? NSRegularExpression(pattern: cellPattern, options: [.dotMatchesLineSeparators]) else {
            return []
        }
        
        let range = NSRange(rowContent.startIndex..<rowContent.endIndex, in: rowContent)
        cellRegex.enumerateMatches(in: rowContent, options: [], range: range) { match, _, _ in
            guard let match = match,
                  let attrsRange = Range(match.range(at: 1), in: rowContent),
                  let contentRange = Range(match.range(at: 2), in: rowContent) else { return }
            
            let attrs = String(rowContent[attrsRange])
            let content = String(rowContent[contentRange])
            
            // Extract column reference from r="X1" attribute
            guard let rMatch = attrs.range(of: #"r="([A-Z]+)\d+""#, options: .regularExpression),
                  let colMatch = attrs[rMatch].range(of: #"[A-Z]+"#, options: .regularExpression) else { return }
            
            let column = String(attrs[colMatch])
            let colIndex = columnLetterToIndex(column)
            maxIndex = max(maxIndex, colIndex)
            
            // Extract type from t="X" attribute
            var cellType = ""
            if let tMatch = attrs.range(of: #"t="([^"]*)""#, options: .regularExpression) {
                let tAttr = String(attrs[tMatch])
                if let typeStart = tAttr.range(of: "\""),
                   let typeEnd = tAttr.range(of: "\"", range: tAttr.index(after: typeStart.lowerBound)..<tAttr.endIndex) {
                    cellType = String(tAttr[typeStart.upperBound..<typeEnd.lowerBound])
                }
            }
            
            let value = extractCellValue(content: content, type: cellType, sharedStrings: sharedStrings)
            cellDict[colIndex] = value
        }
        
        // Convert to array
        var cells: [String] = []
        if maxIndex >= 0 {
            for i in 0...maxIndex {
                cells.append(cellDict[i] ?? "")
            }
        }
        
        return cells
    }
    
    private static func extractCellValue(content: String, type: String, sharedStrings: [String]) -> String {
        // Try to find <v> value
        let vPattern = #"<v>([^<]*)</v>"#
        if let vRegex = try? NSRegularExpression(pattern: vPattern, options: []),
           let match = vRegex.firstMatch(in: content, range: NSRange(content.startIndex..<content.endIndex, in: content)),
           let valueRange = Range(match.range(at: 1), in: content) {
            let value = String(content[valueRange])
            
            // If type is "s", it's a shared string index
            if type == "s", let index = Int(value), index < sharedStrings.count {
                return sharedStrings[index]
            }
            return value
        }
        
        // Try to find inline string <is><t>value</t></is>
        let isPattern = #"<is>.*?<t[^>]*>([^<]*)</t>.*?</is>"#
        if let isRegex = try? NSRegularExpression(pattern: isPattern, options: [.dotMatchesLineSeparators]),
           let match = isRegex.firstMatch(in: content, range: NSRange(content.startIndex..<content.endIndex, in: content)),
           let valueRange = Range(match.range(at: 1), in: content) {
            return String(content[valueRange])
        }
        
        // Try <t> directly
        let tPattern = #"<t[^>]*>([^<]*)</t>"#
        if let tRegex = try? NSRegularExpression(pattern: tPattern, options: []),
           let match = tRegex.firstMatch(in: content, range: NSRange(content.startIndex..<content.endIndex, in: content)),
           let valueRange = Range(match.range(at: 1), in: content) {
            return String(content[valueRange])
        }
        
        return ""
    }
    
    private static func columnLetterToIndex(_ letter: String) -> Int {
        var index = 0
        for char in letter.uppercased() {
            guard let asciiValue = char.asciiValue else { continue }
            index = index * 26 + (Int(asciiValue) - Int(Character("A").asciiValue!) + 1)
        }
        return index - 1
    }
    
    private static func mapColumns(_ headerRow: [String]) -> [String: Int] {
        var columnMap: [String: Int] = [:]
        
        print("ExcelParser: Mapping columns from headers:")
        for (index, header) in headerRow.enumerated() {
            let normalized = header.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            print("  [\(index)] \(header)")
            
            // Year: "Rok"
            if normalized == "rok" {
                columnMap["year"] = index
            }
            // Month: "Miesiąc"
            else if normalized == "miesiąc" || normalized == "miesiac" {
                columnMap["month"] = index
            }
            // Service name: "Nazwa świadczenia"
            else if normalized.contains("nazwa świadczenia") && !normalized.contains("kod") {
                columnMap["serviceName"] = index
            }
            // Facility name: "Nazwa świadczeniodawcy"  
            else if normalized.contains("nazwa świadczeniodawcy") {
                columnMap["facilityName"] = index
            }
            // Department name: "Nazwa komórki"
            else if normalized.contains("nazwa komórki") {
                columnMap["departmentName"] = index
            }
            // Address with phone: "Adres komórki" - format: "CITY;STREET;PHONE"
            else if normalized.contains("adres komórki") {
                columnMap["cellAddress"] = index
                // Use this as location source too since it contains city
                columnMap["location"] = index
            }
            // Number waiting: "Liczba oczekujących"
            else if normalized.contains("liczba oczekujących") {
                columnMap["numberWaiting"] = index
            }
            // First available date: "Pierwszy wolny termin"
            else if normalized.contains("pierwszy wolny termin") {
                columnMap["date"] = index
            }
            // Average waiting time: "Średni czas oczekiwania"
            else if normalized.contains("średni czas oczekiwania") {
                columnMap["waiting"] = index
            }
            // Medical category: "Kategoria medyczna"
            else if normalized.contains("kategoria medyczna") {
                columnMap["category"] = index
            }
        }
        
        print("ExcelParser: Final column map: \(columnMap)")
        return columnMap
    }
    
    private static func extractPhoneAndAddress(from cellAddress: String) -> (phone: String?, address: String?) {
        var phone: String?
        var address = cellAddress
        
        let patterns = [
            #"\+?48[\s\-]?[\d\s\-\(\)]{9,}"#,
            #"\(\d{2,3}\)[\s\-]?\d{3}[\s\-]?\d{2,3}[\s\-]?\d{2,3}"#,
            #"\d{3}[\s\-]?\d{3}[\s\-]?\d{3}"#,
            #"\d{2}[\s\-]?\d{3}[\s\-]?\d{2}[\s\-]?\d{2}"#,
            #"\d{9,}"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: cellAddress, range: NSRange(cellAddress.startIndex..<cellAddress.endIndex, in: cellAddress)),
               let phoneRange = Range(match.range, in: cellAddress) {
                phone = String(cellAddress[phoneRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                address = cellAddress.replacingCharacters(in: phoneRange, with: "")
                break
            }
        }
        
        address = address.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return (phone: phone?.isEmpty == true ? nil : phone, address: address.isEmpty ? nil : address)
    }
}
