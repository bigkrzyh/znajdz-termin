//
//  Localization.swift
//  Znajdz Termin
//
//  Created by Krzysztof Kuźmicki on 31/12/2025.
//

import Foundation

/// Helper for localized strings
extension String {
    /// Returns a localized version of the string
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
    
    /// Returns a localized string with format arguments
    func localized(_ args: CVarArg...) -> String {
        String(format: NSLocalizedString(self, comment: ""), arguments: args)
    }
    
    /// Decodes HTML entities in a string
    func decodeHTMLEntities() -> String {
        var result = self
        let entities: [(String, String)] = [
            ("&quot;", "\""),
            ("&amp;", "&"),
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&nbsp;", " "),
            ("&apos;", "'"),
            ("&#39;", "'"),
            ("&#34;", "\""),
            ("&ndash;", "–"),
            ("&mdash;", "—"),
            ("&hellip;", "…"),
            ("&copy;", "©"),
            ("&reg;", "®"),
            ("&trade;", "™"),
            ("&euro;", "€"),
            ("&pound;", "£"),
            ("&yen;", "¥"),
            ("&cent;", "¢"),
            ("&deg;", "°"),
            ("&plusmn;", "±"),
            ("&times;", "×"),
            ("&divide;", "÷"),
            ("&frac12;", "½"),
            ("&frac14;", "¼"),
            ("&frac34;", "¾"),
        ]
        
        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }
        
        // Handle numeric entities like &#123;
        let numericPattern = "&#(\\d+);"
        if let regex = try? NSRegularExpression(pattern: numericPattern, options: []) {
            let range = NSRange(result.startIndex..., in: result)
            let matches = regex.matches(in: result, options: [], range: range)
            
            for match in matches.reversed() {
                if let swiftRange = Range(match.range, in: result),
                   let numberRange = Range(match.range(at: 1), in: result),
                   let codePoint = Int(result[numberRange]),
                   let scalar = Unicode.Scalar(codePoint) {
                    result.replaceSubrange(swiftRange, with: String(Character(scalar)))
                }
            }
        }
        
        return result
    }
}

/// Localization keys
enum L10n {
    // App
    static var appName: String { "app_name".localized }
    static var appSubtitle: String { "app_subtitle".localized }
    
    // Search Screen
    static var selectVoivodeshipHint: String { "select_voivodeship_hint".localized }
    static var selectVoivodeship: String { "select_voivodeship".localized }
    static var serviceNameOptional: String { "service_name_optional".localized }
    static var loadingServices: String { "loading_services".localized }
    static var selectVoivodeshipFirst: String { "select_voivodeship_first".localized }
    static var locationOptional: String { "location_optional".localized }
    static var urgentCases: String { "urgent_cases".localized }
    static var searchButton: String { "search_button".localized }
    
    // Results Screen
    static var back: String { "back".localized }
    static var results: String { "results".localized }
    static func resultsCount(_ displayed: Int, _ total: Int) -> String {
        "results_count".localized(displayed, total)
    }
    static func dataCurrentAsOf(_ date: String) -> String {
        "data_current_as_of".localized(date)
    }
    static var loadingMore: String { "loading_more".localized }
    static var scrollToLoadMore: String { "scroll_to_load_more".localized }
    static var noResults: String { "no_results".localized }
    static var tryDifferentCriteria: String { "try_different_criteria".localized }
    static var changeCriteria: String { "change_criteria".localized }
    
    // Appointment Row
    static func waitingCount(_ count: Int) -> String {
        "waiting_count".localized(count)
    }
    
    // Voivodeship Picker
    static var voivodeship: String { "voivodeship".localized }
    static var cancel: String { "cancel".localized }
    
    // Service Name Picker
    static var serviceName: String { "service_name".localized }
    static var searchServiceName: String { "search_service_name".localized }
    static var all: String { "all".localized }
    
    // Errors
    static var errorSelectVoivodeship: String { "error_select_voivodeship".localized }
    static func errorLoadingData(_ error: String) -> String {
        "error_loading_data".localized(error)
    }
    static func errorFetchingData(_ error: String) -> String {
        "error_fetching_data".localized(error)
    }
    static func errorRefreshing(_ error: String) -> String {
        "error_refreshing".localized(error)
    }
    
    // Date
    static func dataLabel(_ date: String) -> String {
        "data_label".localized(date)
    }
}

