//
//  NFZAPIClient.swift
//  Znajdz Termin
//
//  Created by Krzysztof Kuźmicki on 07/01/2026.
//
//  API Client for NFZ Terminy Leczenia API
//  Documentation: https://api.nfz.gov.pl/app-itl-api/

import Foundation

// MARK: - API Response Models

/// Root response structure from NFZ API
struct NFZAPIResponse<T: Decodable>: Decodable {
    let meta: NFZMeta?
    let links: NFZLinks?
    let data: T
}

/// Metadata from API response
struct NFZMeta: Decodable {
    let context: String?
    let count: Int?
    let page: Int?
    let limit: Int?
    
    enum CodingKeys: String, CodingKey {
        case context = "@context"
        case count, page, limit
    }
}

/// Pagination links from API response
struct NFZLinks: Decodable {
    let first: String?
    let prev: String?
    let `self`: String?
    let next: String?
    let last: String?
}

/// Queue (appointment) data from API
struct NFZQueue: Decodable {
    let type: String?
    let id: String?
    let attributes: NFZQueueAttributes?
}

/// Queue attributes containing appointment details
struct NFZQueueAttributes: Decodable {
    let `case`: Int?
    let benefit: String?
    let manyPlaces: String?
    let provider: String?
    let providerCode: String?
    let regonProvider: String?
    let nipProvider: String?
    let terytProvider: String?
    let place: String?
    let address: String?
    let locality: String?
    let phone: String?
    let terytPlace: String?
    let registryNumber: String?
    let idResortPartVII: String?
    let idResortPartVIII: String?
    let benefitsForChildren: String?
    let covid19: String?
    let toilet: String?
    let ramp: String?
    let carPark: String?
    let elevator: String?
    let latitude: Double?
    let longitude: Double?
    let statistics: NFZStatistics?
    let dates: NFZDates?
    let benefitsProvided: String?
    
    enum CodingKeys: String, CodingKey {
        case `case`
        case benefit
        case manyPlaces = "many-places"
        case provider
        case providerCode = "provider-code"
        case regonProvider = "regon-provider"
        case nipProvider = "nip-provider"
        case terytProvider = "teryt-provider"
        case place
        case address
        case locality
        case phone
        case terytPlace = "teryt-place"
        case registryNumber = "registry-number"
        case idResortPartVII = "id-resort-part-VII"
        case idResortPartVIII = "id-resort-part-VIII"
        case benefitsForChildren = "benefits-for-children"
        case covid19 = "covid-19"
        case toilet
        case ramp
        case carPark = "car-park"
        case elevator
        case latitude
        case longitude
        case statistics
        case dates
        case benefitsProvided = "benefits-provided"
    }
}

/// Statistics about waiting patients
struct NFZStatistics: Decodable {
    let providerData: NFZProviderData?
    let computedData: NFZComputedData?
    
    enum CodingKeys: String, CodingKey {
        case providerData = "provider-data"
        case computedData = "computed-data"
    }
}

struct NFZProviderData: Decodable {
    let awaiting: Int?
    let removed: Int?
    let averagePeriod: Int?
    let update: String?
    
    enum CodingKeys: String, CodingKey {
        case awaiting
        case removed
        case averagePeriod = "average-period"
        case update
    }
}

struct NFZComputedData: Decodable {
    let averagePeriod: Int?
    
    enum CodingKeys: String, CodingKey {
        case averagePeriod = "average-period"
    }
}

/// Available dates information
struct NFZDates: Decodable {
    let applicable: Bool?
    let date: String?
    let dateSituationAsAt: String?
    
    enum CodingKeys: String, CodingKey {
        case applicable
        case date
        case dateSituationAsAt = "date-situation-as-at"
    }
}

// MARK: - API Client

/// Client for NFZ Terminy Leczenia API
final class NFZAPIClient: @unchecked Sendable {
    static let shared = NFZAPIClient()
    
    private let baseURL = "https://api.nfz.gov.pl/app-itl-api"
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Public Methods
    
    /// Fetch queues (appointments) with filtering
    /// - Parameters:
    ///   - province: Province code (01-16)
    ///   - caseType: Case type (1 = stable, 2 = urgent)
    ///   - benefit: Service name filter (optional)
    ///   - locality: City name filter (optional)
    ///   - page: Page number (starts at 1)
    ///   - limit: Results per page (max 25)
    /// - Returns: API response with queue data and metadata
    func fetchQueues(
        province: String,
        caseType: Int = 1,
        benefit: String? = nil,
        locality: String? = nil,
        page: Int = 1,
        limit: Int = 25
    ) async throws -> NFZAPIResponse<[NFZQueue]> {
        var components = URLComponents(string: "\(baseURL)/queues")!
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "province", value: province),
            URLQueryItem(name: "case", value: String(caseType)),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(min(limit, 25))),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "api-version", value: "1.3")
        ]
        
        if let benefit = benefit, !benefit.isEmpty {
            queryItems.append(URLQueryItem(name: "benefit", value: benefit))
        }
        
        if let locality = locality, !locality.isEmpty {
            queryItems.append(URLQueryItem(name: "locality", value: locality))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw NFZAPIError.invalidURL
        }
        
        print("NFZAPIClient: Fetching \(url.absoluteString)")
        
        let request = createRequest(url: url)
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response)
        
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(NFZAPIResponse<[NFZQueue]>.self, from: data)
        } catch {
            print("NFZAPIClient: Decoding error: \(error)")
            if let jsonString = String(data: data.prefix(1000), encoding: .utf8) {
                print("NFZAPIClient: Response preview: \(jsonString)")
            }
            throw NFZAPIError.decodingFailed(error)
        }
    }
    
    /// Fetch queue details by ID
    func fetchQueueDetails(id: String) async throws -> NFZAPIResponse<NFZQueue> {
        guard let url = URL(string: "\(baseURL)/queues/\(id)?format=json&api-version=1.3") else {
            throw NFZAPIError.invalidURL
        }
        
        let request = createRequest(url: url)
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response)
        
        let decoder = JSONDecoder()
        return try decoder.decode(NFZAPIResponse<NFZQueue>.self, from: data)
    }
    
    /// Fetch available benefits (service names) dictionary
    func fetchBenefits(name: String? = nil, page: Int = 1, limit: Int = 25) async throws -> NFZAPIResponse<[String]> {
        var components = URLComponents(string: "\(baseURL)/benefits")!
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(min(limit, 25))),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "api-version", value: "1.3")
        ]
        
        if let name = name, !name.isEmpty {
            queryItems.append(URLQueryItem(name: "name", value: name))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw NFZAPIError.invalidURL
        }
        
        let request = createRequest(url: url)
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response)
        
        let decoder = JSONDecoder()
        return try decoder.decode(NFZAPIResponse<[String]>.self, from: data)
    }
    
    /// Fetch all benefits with pagination
    func fetchAllBenefits() async throws -> [String] {
        var allBenefits: [String] = []
        var page = 1
        var hasMore = true
        
        while hasMore {
            let response = try await fetchBenefits(page: page, limit: 25)
            let data = response.data
            allBenefits.append(contentsOf: data)
            
            if let meta = response.meta, let count = meta.count {
                let currentCount = page * 25
                hasMore = currentCount < count
            } else {
                hasMore = response.links?.next != nil
            }
            
            page += 1
            
            // Safety limit
            if page > 100 { break }
        }
        
        return allBenefits.sorted()
    }
    
    /// Fetch localities dictionary
    func fetchLocalities(province: String? = nil, name: String? = nil, page: Int = 1, limit: Int = 25) async throws -> NFZAPIResponse<[String]> {
        var components = URLComponents(string: "\(baseURL)/localities")!
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(min(limit, 25))),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "api-version", value: "1.3")
        ]
        
        if let province = province, !province.isEmpty {
            queryItems.append(URLQueryItem(name: "province", value: province))
        }
        
        if let name = name, !name.isEmpty {
            queryItems.append(URLQueryItem(name: "name", value: name))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw NFZAPIError.invalidURL
        }
        
        let request = createRequest(url: url)
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response)
        
        let decoder = JSONDecoder()
        return try decoder.decode(NFZAPIResponse<[String]>.self, from: data)
    }
    
    // MARK: - Private Methods
    
    private func createRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Znajdz-Termin-iOS/1.0", forHTTPHeaderField: "User-Agent")
        return request
    }
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NFZAPIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 400:
            throw NFZAPIError.badRequest
        case 404:
            throw NFZAPIError.notFound
        case 429:
            throw NFZAPIError.rateLimited
        case 500...599:
            throw NFZAPIError.serverError(httpResponse.statusCode)
        default:
            throw NFZAPIError.httpError(httpResponse.statusCode)
        }
    }
}

// MARK: - API Errors

enum NFZAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case badRequest
    case notFound
    case rateLimited
    case serverError(Int)
    case httpError(Int)
    case decodingFailed(Error)
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Nieprawidłowy adres URL"
        case .invalidResponse:
            return "Nieprawidłowa odpowiedź serwera"
        case .badRequest:
            return "Nieprawidłowe zapytanie"
        case .notFound:
            return "Nie znaleziono danych"
        case .rateLimited:
            return "Zbyt wiele zapytań. Spróbuj ponownie za chwilę."
        case .serverError(let code):
            return "Błąd serwera (\(code)). Spróbuj ponownie później."
        case .httpError(let code):
            return "Błąd HTTP (\(code))"
        case .decodingFailed(let error):
            return "Błąd dekodowania danych: \(error.localizedDescription)"
        case .noData:
            return "Brak danych"
        }
    }
}

// MARK: - Province Code Extension

extension Voivodeship {
    /// Province code for NFZ API (01-16)
    var provinceCode: String {
        switch self {
        case .dolnoslaskie: return "01"
        case .kujawskoPomorskie: return "02"
        case .lubelskie: return "03"
        case .lubuskie: return "04"
        case .lodzkie: return "05"
        case .malopolskie: return "06"
        case .mazowieckie: return "07"
        case .opolskie: return "08"
        case .podkarpackie: return "09"
        case .podlaskie: return "10"
        case .pomorskie: return "11"
        case .slaskie: return "12"
        case .swietokrzyskie: return "13"
        case .warminskoMazurskie: return "14"
        case .wielkopolskie: return "15"
        case .zachodniopomorskie: return "16"
        }
    }
}

