//
//  DownloadTester.swift
//  Znajdz Termin
//
//  Created by Krzysztof Kuźmicki on 29/12/2025.
//

import Foundation
import ZIPFoundation

class DownloadTester {
    static func testDownload(for voivodeship: Voivodeship) async {
        print("=== Download Tester ===")
        print("Testing download for: \(voivodeship.rawValue)")
        
        do {
            // Get download URL
            let downloadURL = try await DownloadPageScraper.getDownloadURL(for: voivodeship)
            print("Download URL: \(downloadURL)")
            
            guard let url = URL(string: downloadURL) else {
                print("ERROR: Invalid URL")
                return
            }
            
            // Download with detailed logging
            var request = URLRequest(url: url)
            request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            print("\n=== Response Details ===")
            if let httpResponse = response as? HTTPURLResponse {
                print("Status Code: \(httpResponse.statusCode)")
                print("Headers:")
                for (key, value) in httpResponse.allHeaderFields {
                    print("  \(key): \(value)")
                }
                
                if let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") {
                    print("\nContent-Type: \(contentType)")
                }
                
                if let contentDisposition = httpResponse.value(forHTTPHeaderField: "Content-Disposition") {
                    print("Content-Disposition: \(contentDisposition)")
                }
            }
            
            print("\n=== File Analysis ===")
            print("Data size: \(data.count) bytes")
            print("First 100 bytes (hex): \(data.prefix(100).map { String(format: "%02x", $0) }.joined(separator: " "))")
            
            // Check file signature
            let firstBytes = data.prefix(8)
            print("\nFile signature (first 8 bytes):")
            for byte in firstBytes {
                print(String(format: "%02x", byte), terminator: " ")
            }
            print()
            
            // Check if it's a ZIP file (Excel files are ZIP archives)
            // ZIP signature: 50 4B 03 04 (PK..)
            if data.count >= 4 {
                let zipSignature: [UInt8] = [0x50, 0x4B, 0x03, 0x04]
                let fileSignature = Array(data.prefix(4))
                
                if fileSignature == zipSignature {
                    print("✓ File is a ZIP archive (Excel format)")
                } else {
                    print("✗ File is NOT a ZIP archive")
                    print("Expected: 50 4B 03 04")
                    print("Got: \(fileSignature.map { String(format: "%02x", $0) }.joined(separator: " "))")
                }
            }
            
            // Check if it's HTML
            if let text = String(data: data.prefix(1000), encoding: .utf8) {
                if text.lowercased().contains("<!doctype") || text.lowercased().contains("<html") {
                    print("\n✗ File appears to be HTML (error page)")
                    print("First 500 characters:")
                    print(String(text.prefix(500)))
                } else {
                    print("\n✓ File does not appear to be HTML")
                }
            }
            
            // Try to parse as ZIP
            print("\n=== ZIP Parsing Test ===")
            do {
                let archive = try Archive(data: data, accessMode: .read)
                print("✓ Successfully opened as ZIP archive")
                print("Entries in archive:")
                var entryCount = 0
                for entry in archive {
                    entryCount += 1
                    if entryCount <= 10 {
                        print("  - \(entry.path) (\(entry.uncompressedSize) bytes)")
                    }
                }
                if entryCount > 10 {
                    print("  ... and \(entryCount - 10) more entries")
                }
            } catch {
                print("✗ Failed to parse as ZIP: \(error)")
            }
            
        } catch {
            print("ERROR: \(error)")
        }
        
        print("\n=== End Test ===\n")
    }
}

