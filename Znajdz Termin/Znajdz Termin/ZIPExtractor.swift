//
//  ZIPExtractor.swift
//  Znajdz Termin
//
//  Created by Krzysztof Kuźmicki on 29/12/2025.
//

import Foundation
import ZIPFoundation

struct ZIPExtractor {
    static func extractExcelFiles(from zipData: Data) throws -> (sharedStrings: Data?, sheet1: Data) {
        print("ZIPExtractor: Processing \(zipData.count) bytes")
        
        // Check if it looks like HTML (error page)
        if let text = String(data: zipData.prefix(100), encoding: .utf8),
           text.lowercased().contains("<!doctype") || text.lowercased().contains("<html") {
            print("ZIPExtractor: Data appears to be HTML")
            throw NSError(domain: "ZIPExtractor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Otrzymano stronę HTML zamiast pliku Excel"])
        }
        
        let archive = try Archive(data: zipData, accessMode: .read)
        
        var sharedStringsData: Data?
        var sheet1Data: Data?
        
        for entry in archive {
            print("ZIPExtractor: Found entry: \(entry.path)")
            
            if entry.path == "xl/sharedStrings.xml" || entry.path.hasSuffix("sharedStrings.xml") {
                var data = Data()
                _ = try archive.extract(entry) { chunk in
                    data.append(chunk)
                }
                sharedStringsData = data
                print("ZIPExtractor: Extracted sharedStrings.xml (\(data.count) bytes)")
            } else if entry.path == "xl/worksheets/sheet1.xml" || entry.path.hasSuffix("sheet1.xml") {
                var data = Data()
                _ = try archive.extract(entry) { chunk in
                    data.append(chunk)
                }
                sheet1Data = data
                print("ZIPExtractor: Extracted sheet1.xml (\(data.count) bytes)")
            }
        }
        
        guard let sheet1 = sheet1Data else {
            throw NSError(domain: "ZIPExtractor", code: 2, userInfo: [NSLocalizedDescriptionKey: "Nie znaleziono pliku sheet1.xml w archiwum"])
        }
        
        return (sharedStringsData, sheet1)
    }
}
