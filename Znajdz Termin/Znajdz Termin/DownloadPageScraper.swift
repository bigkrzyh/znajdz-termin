//
//  DownloadPageScraper.swift
//  Znajdz Termin
//
//  Created by Krzysztof Kuźmicki on 29/12/2025.
//

import Foundation

class DownloadPageScraper {
    private static let baseURL = "https://terminyleczenia.nfz.gov.pl"
    private static let downloadPageURL = "\(baseURL)/Download"
    private static var cachedURLs: [String: String] = [:]
    
    // Current GUIDs from the NFZ website (as of December 2025)
    // These are extracted from the download page
    private static let voivodeshipGUIDs: [String: String] = [
        "dolnośląskie": "45fc4182-1dcd-25aa-e063-b4200a0a751b",
        "kujawsko-pomorskie": "45fc5222-cd85-9739-e063-b4200a0a78c0",
        "lubelskie": "45fc5429-3ab0-ba1b-e063-b4200a0af4c4",
        "lubuskie": "45fc5429-3ab1-ba1b-e063-b4200a0af4c4",
        "łódzkie": "45fc5762-77c1-ce0c-e063-b4200a0a3c21",
        "małopolskie": "45fc59f2-b860-e575-e063-b4200a0a3730",
        "mazowieckie": "45fde959-0f4b-b7f7-e063-b4200a0af33c",
        "opolskie": "45fc5c60-251c-ee6b-e063-b4200a0a6c46",
        "podkarpackie": "45fc5e44-466e-06a1-e063-b4200a0af845",
        "podlaskie": "45fc607e-5c87-1b03-e063-b4200a0a2515",
        "pomorskie": "45fc630f-700a-27ff-e063-b4200a0a193b",
        "śląskie": "45fc6734-4428-4920-e063-b4200a0a8ca7",
        "świętokrzyskie": "45fc8269-3f4b-176c-e063-b4200a0a9b89",
        "warmińsko-mazurskie": "45fc8478-c807-3445-e063-b4200a0a64cb",
        "wielkopolskie": "45fc8478-c808-3445-e063-b4200a0a64cb",
        "zachodniopomorskie": "45fc8768-3a19-3c1a-e063-b4200a0aee51"
    ]
    
    /// Build the download URL for a voivodeship using the known GUID
    static func getDownloadURL(for voivodeship: Voivodeship) async throws -> String {
        // First try to get fresh URL from scraping
        if let scrapedURL = try? await scrapeDownloadURL(for: voivodeship) {
            print("DownloadPageScraper: Using scraped URL for \(voivodeship.rawValue)")
            return scrapedURL
        }
        
        // Fallback to known GUIDs
        guard let guid = voivodeshipGUIDs[voivodeship.rawValue] else {
            throw NSError(domain: "DownloadPageScraper", code: 1, 
                userInfo: [NSLocalizedDescriptionKey: "Nieznane województwo: \(voivodeship.rawValue)"])
        }
        
        let mimeParam = "application%2Fvnd.openxmlformats-officedocument.spreadsheetml.sheet"
        let url = "\(baseURL)/DownloadFile/\(guid)?mime=\(mimeParam)"
        print("DownloadPageScraper: Using hardcoded GUID URL for \(voivodeship.rawValue): \(url)")
        return url
    }
    
    /// Scrape the download page to get fresh URLs (in case GUIDs change)
    private static func scrapeDownloadURL(for voivodeship: Voivodeship) async throws -> String? {
        // Check cache first
        if let cachedURL = cachedURLs[voivodeship.rawValue] {
            return cachedURL
        }
        
        // Only scrape once for all voivodeships
        if cachedURLs.isEmpty {
            try await scrapeAllDownloadURLs()
        }
        
        return cachedURLs[voivodeship.rawValue]
    }
    
    /// Scrape all download URLs from the download page
    private static func scrapeAllDownloadURLs() async throws {
        print("DownloadPageScraper: Scraping \(downloadPageURL)")
        
        guard let url = URL(string: downloadPageURL) else {
            throw NSError(domain: "DownloadPageScraper", code: 1, 
                userInfo: [NSLocalizedDescriptionKey: "Nieprawidłowy URL"])
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("DownloadPageScraper: Failed to fetch download page")
            return
        }
        
        guard let htmlString = String(data: data, encoding: .utf8) else {
            print("DownloadPageScraper: Could not decode HTML")
            return
        }
        
        print("DownloadPageScraper: Downloaded \(htmlString.count) characters")
        
        // Extract URLs using regex
        // Pattern: href="/DownloadFile/GUID?mime=..." followed by voivodeship name
        let pattern = #"<a[^>]*href="(/DownloadFile/[^"]+)"[^>]*>[\s\S]*?</span>([^<]+)</a>"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            print("DownloadPageScraper: Could not create regex")
            return
        }
        
        let range = NSRange(htmlString.startIndex..<htmlString.endIndex, in: htmlString)
        let matches = regex.matches(in: htmlString, options: [], range: range)
        
        for match in matches {
            guard let hrefRange = Range(match.range(at: 1), in: htmlString),
                  let textRange = Range(match.range(at: 2), in: htmlString) else {
                continue
            }
            
            let href = String(htmlString[hrefRange])
            let voivodeshipName = String(htmlString[textRange])
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            
            // Decode HTML entities
            let decodedName = decodeHTMLEntities(voivodeshipName)
            
            // Match to our Voivodeship enum
            for voivodeship in Voivodeship.allCases {
                if decodedName == voivodeship.rawValue.lowercased() {
                    let fullURL = baseURL + href
                    cachedURLs[voivodeship.rawValue] = fullURL
                    print("DownloadPageScraper: Matched \(voivodeship.rawValue) -> \(fullURL)")
                    break
                }
            }
        }
        
        print("DownloadPageScraper: Scraped \(cachedURLs.count) URLs")
    }
    
    /// Decode common HTML entities
    private static func decodeHTMLEntities(_ string: String) -> String {
        var result = string
        let entities = [
            "&#x15B;": "ś",
            "&#x105;": "ą",
            "&#x142;": "ł",
            "&#xF3;": "ó",
            "&#x119;": "ę",
            "&#x144;": "ń",
            "&#x17C;": "ż",
            "&#x17A;": "ź",
            "&#x107;": "ć",
            "&nbsp;": " ",
            "&amp;": "&"
        ]
        for (entity, char) in entities {
            result = result.replacingOccurrences(of: entity, with: char)
        }
        return result
    }
    
    /// Clear the cached URLs to force re-scraping
    static func clearCache() {
        cachedURLs.removeAll()
    }
}
