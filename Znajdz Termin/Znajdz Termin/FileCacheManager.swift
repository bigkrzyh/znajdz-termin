//
//  FileCacheManager.swift
//  Znajdz Termin
//
//  Created by Krzysztof Kuźmicki on 29/12/2025.
//

import Foundation

class FileCacheManager {
    static let shared = FileCacheManager()
    
    private let cacheDirectory: URL
    
    private init() {
        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDir.appendingPathComponent("NFZFiles", isDirectory: true)
        
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        print("FileCacheManager: Cache directory: \(cacheDirectory.path)")
    }
    
    func getCachedFileURL(for voivodeship: String) -> URL {
        return cacheDirectory.appendingPathComponent("\(voivodeship).xlsx")
    }
    
    func getMetadataURL(for voivodeship: String) -> URL {
        return cacheDirectory.appendingPathComponent("\(voivodeship).xlsx.metadata")
    }
    
    func fileExists(for voivodeship: String) -> Bool {
        let fileURL = getCachedFileURL(for: voivodeship)
        let exists = FileManager.default.fileExists(atPath: fileURL.path)
        print("FileCacheManager: File exists for \(voivodeship): \(exists)")
        return exists
    }
    
    func saveFile(data: Data, for voivodeship: String) throws {
        let fileURL = getCachedFileURL(for: voivodeship)
        try data.write(to: fileURL)
        print("FileCacheManager: Saved \(data.count) bytes for \(voivodeship)")
        
        let metadata: [String: Any] = ["lastUpdate": Date().timeIntervalSince1970]
        let metadataData = try JSONSerialization.data(withJSONObject: metadata)
        try metadataData.write(to: getMetadataURL(for: voivodeship))
    }
    
    func loadFile(for voivodeship: String) throws -> Data {
        let fileURL = getCachedFileURL(for: voivodeship)
        let data = try Data(contentsOf: fileURL)
        print("FileCacheManager: Loaded \(data.count) bytes for \(voivodeship)")
        return data
    }
    
    func getLastUpdateDate(for voivodeship: String) -> Date? {
        let metadataURL = getMetadataURL(for: voivodeship)
        guard let metadataData = try? Data(contentsOf: metadataURL),
              let json = try? JSONSerialization.jsonObject(with: metadataData) as? [String: Any],
              let timestamp = json["lastUpdate"] as? TimeInterval else {
            return nil
        }
        return Date(timeIntervalSince1970: timestamp)
    }
    
    func deleteFile(for voivodeship: String) throws {
        let fileURL = getCachedFileURL(for: voivodeship)
        let metadataURL = getMetadataURL(for: voivodeship)
        try? FileManager.default.removeItem(at: fileURL)
        try? FileManager.default.removeItem(at: metadataURL)
        print("FileCacheManager: Deleted cache for \(voivodeship)")
    }
    
    func clearAllCache() throws {
        let contents = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        for file in contents {
            try FileManager.default.removeItem(at: file)
        }
        print("FileCacheManager: Cleared all cache")
    }
}
