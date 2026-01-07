//
//  LocationManager.swift
//  Znajdz Termin
//
//  Created by Krzysztof Kuźmicki on 29/12/2025.
//

import Foundation
import CoreLocation
import Combine

@MainActor
class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var lastKnownLocation: CLLocation?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        authorizationStatus = locationManager.authorizationStatus
        lastKnownLocation = loadLastKnownLocation()
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return
        }
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            if let location = locations.last {
                currentLocation = location
                lastKnownLocation = location
                saveLastKnownLocation(location)
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
                startUpdatingLocation()
            }
        }
    }
    
    func getLocationForDistanceCalculation() -> CLLocation? {
        return currentLocation ?? lastKnownLocation
    }
    
    /// Returns user's current location (or last known) for distance calculations
    var userLocation: CLLocation? {
        return currentLocation ?? lastKnownLocation
    }
    
    private func saveLastKnownLocation(_ location: CLLocation) {
        UserDefaults.standard.set(location.coordinate.latitude, forKey: "lastKnownLatitude")
        UserDefaults.standard.set(location.coordinate.longitude, forKey: "lastKnownLongitude")
    }
    
    private func loadLastKnownLocation() -> CLLocation? {
        let lat = UserDefaults.standard.double(forKey: "lastKnownLatitude")
        let lon = UserDefaults.standard.double(forKey: "lastKnownLongitude")
        if lat != 0 && lon != 0 {
            return CLLocation(latitude: lat, longitude: lon)
        }
        return nil
    }
    
    func calculateDistance(to address: String, location: String) async -> Double? {
        guard let userLocation = getLocationForDistanceCalculation() else {
            return nil
        }
        
        let geocoder = CLGeocoder()
        
        // Try full address first
        let fullAddress = "\(address), \(location), Polska"
        if let placemarks = try? await geocoder.geocodeAddressString(fullAddress),
           let placemark = placemarks.first,
           let targetLocation = placemark.location {
            return userLocation.distance(from: targetLocation) / 1000.0
        }
        
        // Fallback to location only
        let locationAddress = "\(location), Polska"
        if let placemarks = try? await geocoder.geocodeAddressString(locationAddress),
           let placemark = placemarks.first,
           let targetLocation = placemark.location {
            return userLocation.distance(from: targetLocation) / 1000.0
        }
        
        return nil
    }
}

extension LocationManager: CLLocationManagerDelegate {}
