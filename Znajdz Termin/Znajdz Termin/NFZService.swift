//
//  NFZService.swift
//  Znajdz Termin
//
//  Created by Krzysztof Kuźmicki on 29/12/2025.
//
//  Refactored to use NFZ API instead of Excel files
//

import Foundation
import Combine
import CoreLocation

@MainActor
class NFZService: ObservableObject {
    // MARK: - Published Properties
    @Published var appointments: [Appointment] = []
    @Published var displayedAppointments: [Appointment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedVoivodeship: Voivodeship?
    @Published var selectedServiceName: String?
    @Published var locationFilter: String = ""
    @Published var serviceNames: [String] = []
    @Published var lastUpdateDate: Date?
    @Published var isSearching = false
    @Published var hasSearched = false
    @Published var isLoadingServiceNames = false
    @Published var isServiceNamesReady = false
    @Published var dataDateString: String?
    @Published var showResults = false
    @Published var isLoadingMore = false
    @Published var hasMoreResults = false
    @Published var showUrgentOnly = false  // "Pilne" filter - default unchecked (stable cases)
    
    // MARK: - API Pagination
    @Published var totalResultsCount: Int = 0
    private var currentAPIPage = 1
    private let apiPageSize = 25  // Max allowed by API
    
    // MARK: - Display Pagination
    private let displayPageSize = 20
    private var currentDisplayPage = 0
    
    // MARK: - Private Properties
    private let locationManager: LocationManager
    
    // MARK: - Initialization
    init(locationManager: LocationManager) {
        self.locationManager = locationManager
    }
    
    // MARK: - Voivodeship Selection
    func selectVoivodeship(_ voivodeship: Voivodeship) async {
        // Reset state when changing voivodeship
        selectedServiceName = nil
        selectedVoivodeship = voivodeship
        isServiceNamesReady = false
        isLoadingServiceNames = true
        errorMessage = nil
        hasSearched = false
        appointments = []
        displayedAppointments = []
        dataDateString = nil
        currentAPIPage = 1
        currentDisplayPage = 0
        
        // Load common benefits as default list
        // The NFZ API requires search term for /benefits, so we use predefined common ones
        serviceNames = NFZAPIClient.commonBenefits
        print("NFZService: Loaded \(serviceNames.count) common benefits")
        
        isServiceNamesReady = true
        isLoadingServiceNames = false
    }
    
    // MARK: - Search Benefits (Service Names)
    /// Search for service names matching the query (requires at least 3 characters)
    func searchServiceNames(query: String) async {
        guard query.count >= 3 else {
            // Show common benefits if query is too short
            serviceNames = NFZAPIClient.commonBenefits
            return
        }
        
        do {
            print("NFZService: Searching benefits for '\(query)'...")
            let response = try await NFZAPIClient.shared.searchBenefits(name: query)
            
            if response.data.isEmpty {
                // Keep showing common benefits if no results
                print("NFZService: No benefits found for '\(query)', showing common benefits")
            } else {
                serviceNames = response.data
                print("NFZService: Found \(response.data.count) benefits matching '\(query)'")
            }
        } catch {
            print("NFZService: Error searching benefits: \(error)")
            // Keep current list on error
        }
    }
    
    // MARK: - Search
    func search() async {
        guard let voivodeship = selectedVoivodeship else {
            errorMessage = L10n.errorSelectVoivodeship
            return
        }
        
        isSearching = true
        errorMessage = nil
        hasSearched = true
        currentAPIPage = 1
        currentDisplayPage = 0
        appointments = []
        displayedAppointments = []
        
        defer { isSearching = false }
        
        do {
            // Fetch first page from API
            let response = try await fetchAppointments(page: 1)
            
            if let count = response.meta?.count {
                totalResultsCount = count
                print("NFZService: Total results available: \(count)")
            }
            
            // Convert to appointments
            let newAppointments = response.data.compactMap { 
                Appointment.from(queue: $0, voivodeship: voivodeship.rawValue) 
            }
            
            print("NFZService: Fetched \(newAppointments.count) appointments")
            
            // Calculate distances using coordinates
            await calculateDistancesFromCoordinates(for: newAppointments)
            
            // Sort by distance if available
            let sortedAppointments = newAppointments.sorted { a, b in
                if let distA = a.distance, let distB = b.distance {
                    return distA < distB
                }
                if a.distance != nil { return true }
                if b.distance != nil { return false }
                // Sort by first available date if no distance
                if let dateA = a.firstAvailableDate, let dateB = b.firstAvailableDate {
                    return dateA < dateB
                }
                return a.facilityName < b.facilityName
            }
            
            appointments = sortedAppointments
            
            // Show first display page
            loadDisplayPage(0)
            
            // Check if more results available from API
            hasMoreResults = response.links?.next != nil || appointments.count < totalResultsCount
            
            showResults = true
            lastUpdateDate = Date()
            
        } catch {
            print("NFZService: Search error: \(error)")
            errorMessage = L10n.errorFetchingData(error.localizedDescription)
        }
    }
    
    // MARK: - Fetch Appointments from API
    private func fetchAppointments(page: Int) async throws -> NFZAPIResponse<[NFZQueue]> {
        guard let voivodeship = selectedVoivodeship else {
            throw NFZAPIError.badRequest
        }
        
        let caseType = showUrgentOnly ? 2 : 1  // 1 = stable, 2 = urgent
        
        return try await NFZAPIClient.shared.fetchQueues(
            province: voivodeship.provinceCode,
            caseType: caseType,
            benefit: selectedServiceName,
            locality: locationFilter.isEmpty ? nil : locationFilter,
            page: page,
            limit: apiPageSize
        )
    }
    
    // MARK: - Display Pagination
    private func loadDisplayPage(_ page: Int) {
        let startIndex = page * displayPageSize
        let endIndex = min(startIndex + displayPageSize, appointments.count)
        
        guard startIndex < appointments.count else {
            return
        }
        
        if page == 0 {
            displayedAppointments = Array(appointments[startIndex..<endIndex])
        } else {
            displayedAppointments.append(contentsOf: appointments[startIndex..<endIndex])
        }
        
        currentDisplayPage = page
    }
    
    // MARK: - Load More Results
    func loadMoreIfNeeded(currentItem: Appointment) {
        guard hasMoreResults, !isLoadingMore else { return }
        
        // Check if we're near the end of displayed results
        let thresholdIndex = displayedAppointments.count - 5
        guard let itemIndex = displayedAppointments.firstIndex(where: { $0.id == currentItem.id }),
              itemIndex >= thresholdIndex else { return }
        
        isLoadingMore = true
        
        Task {
            // First, check if we have more local appointments to show
            let nextDisplayStart = (currentDisplayPage + 1) * displayPageSize
            
            if nextDisplayStart < appointments.count {
                // We have more locally, just display them
                await calculateDistancesFromCoordinates(for: Array(appointments[nextDisplayStart..<min(nextDisplayStart + displayPageSize, appointments.count)]))
                loadDisplayPage(currentDisplayPage + 1)
            } else {
                // Need to fetch more from API
                do {
                    currentAPIPage += 1
                    let response = try await fetchAppointments(page: currentAPIPage)
                    
                    guard let voivodeship = selectedVoivodeship else { return }
                    
                    let newAppointments = response.data.compactMap {
                        Appointment.from(queue: $0, voivodeship: voivodeship.rawValue)
                    }
                    
                    await calculateDistancesFromCoordinates(for: newAppointments)
                    
                    // Sort new appointments by distance
                    let sortedNew = newAppointments.sorted { a, b in
                        if let distA = a.distance, let distB = b.distance {
                            return distA < distB
                        }
                        if a.distance != nil { return true }
                        if b.distance != nil { return false }
                        return a.facilityName < b.facilityName
                    }
                    
                    appointments.append(contentsOf: sortedNew)
                    loadDisplayPage(currentDisplayPage + 1)
                    
                    hasMoreResults = response.links?.next != nil
                    
                } catch {
                    print("NFZService: Error loading more: \(error)")
                    errorMessage = L10n.errorFetchingData(error.localizedDescription)
                }
            }
            
            isLoadingMore = false
        }
    }
    
    // MARK: - Distance Calculation
    private func calculateDistancesFromCoordinates(for appointmentsList: [Appointment]) async {
        guard let userLocation = locationManager.userLocation else {
            // Fall back to geocoding if no user location
            for appointment in appointmentsList {
                let address = appointment.address ?? appointment.location
                if let distance = await locationManager.calculateDistance(to: address, location: appointment.location) {
                    appointment.distance = distance
                }
            }
            return
        }
        
        for appointment in appointmentsList {
            // First try using coordinates from API (faster)
            if let distance = appointment.calculateDistanceFromCoordinates(userLocation: userLocation) {
                appointment.distance = distance
            } else {
                // Fall back to geocoding
                let address = appointment.address ?? appointment.location
                if let distance = await locationManager.calculateDistance(to: address, location: appointment.location) {
                    appointment.distance = distance
                }
            }
        }
    }
    
    // MARK: - Refresh
    func refreshData() async {
        guard selectedVoivodeship != nil else { return }
        
        // Clear cached data
        appointments = []
        displayedAppointments = []
        currentAPIPage = 1
        currentDisplayPage = 0
        
        // Re-run search
        await search()
    }
    
    // MARK: - Statistics
    func getStatistics() -> Int? {
        guard selectedVoivodeship != nil else { return nil }
        return appointments.compactMap { $0.numberOfWaiting }.reduce(0, +)
    }
    
    // MARK: - Navigation
    func goBackToSearch() {
        showResults = false
    }
    
    func resetSelection() {
        selectedVoivodeship = nil
        selectedServiceName = nil
        locationFilter = ""
        showUrgentOnly = false
        serviceNames = []
        appointments = []
        displayedAppointments = []
        isServiceNamesReady = false
        hasSearched = false
        errorMessage = nil
        dataDateString = nil
        showResults = false
        currentAPIPage = 1
        currentDisplayPage = 0
        totalResultsCount = 0
    }
}
