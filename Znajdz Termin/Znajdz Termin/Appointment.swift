//
//  Appointment.swift
//  Znajdz Termin
//
//  Created by Krzysztof Kuźmicki on 29/12/2025.
//

import Foundation
import CoreLocation

/// Appointment model - simple class for iOS 15+ compatibility
class Appointment: Identifiable, Hashable {
    let id: UUID
    var apiId: String?  // ID from NFZ API for fetching details
    var voivodeship: String
    var facilityName: String
    var serviceName: String
    var location: String
    var firstAvailableDate: String?
    var waitingTime: String?
    var phoneNumber: String?
    var address: String?
    var numberOfWaiting: Int?
    var distance: Double?
    var lastUpdated: Date
    var dataPreparationDate: String?
    var medicalCategory: String?
    var caseType: Int?  // 1 = stable, 2 = urgent
    var latitude: Double?
    var longitude: Double?
    var placeName: String?  // Name of the department/place
    var averageWaitingDays: Int?
    
    /// Returns true if the case type indicates an urgent case
    var isUrgent: Bool {
        return caseType == 2
    }
    
    init(
        id: UUID = UUID(),
        apiId: String? = nil,
        voivodeship: String,
        facilityName: String,
        serviceName: String,
        location: String,
        firstAvailableDate: String? = nil,
        waitingTime: String? = nil,
        phoneNumber: String? = nil,
        address: String? = nil,
        numberOfWaiting: Int? = nil,
        distance: Double? = nil,
        lastUpdated: Date = Date(),
        dataPreparationDate: String? = nil,
        medicalCategory: String? = nil,
        caseType: Int? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        placeName: String? = nil,
        averageWaitingDays: Int? = nil
    ) {
        self.id = id
        self.apiId = apiId
        self.voivodeship = voivodeship
        self.facilityName = facilityName
        self.serviceName = serviceName
        self.location = location
        self.firstAvailableDate = firstAvailableDate
        self.waitingTime = waitingTime
        self.phoneNumber = phoneNumber
        self.address = address
        self.numberOfWaiting = numberOfWaiting
        self.distance = distance
        self.lastUpdated = lastUpdated
        self.dataPreparationDate = dataPreparationDate
        self.medicalCategory = medicalCategory
        self.caseType = caseType
        self.latitude = latitude
        self.longitude = longitude
        self.placeName = placeName
        self.averageWaitingDays = averageWaitingDays
    }
    
    /// Create Appointment from NFZ API Queue response
    static func from(queue: NFZQueue, voivodeship: String) -> Appointment? {
        guard let attributes = queue.attributes else { return nil }
        
        // Build waiting time string from average period
        var waitingTimeStr: String? = nil
        if let avgDays = attributes.statistics?.providerData?.averagePeriod {
            waitingTimeStr = "\(avgDays)"
        } else if let avgDays = attributes.statistics?.computedData?.averagePeriod {
            waitingTimeStr = "\(avgDays)"
        }
        
        // Format first available date
        var dateStr: String? = nil
        if let date = attributes.dates?.date {
            dateStr = date
        }
        
        // Get data situation date
        var dataSituationStr: String? = nil
        if let dateSituation = attributes.dates?.dateSituationAsAt {
            dataSituationStr = dateSituation
        }
        
        return Appointment(
            apiId: queue.id,
            voivodeship: voivodeship,
            facilityName: attributes.provider?.decodeHTMLEntities() ?? "Nieznana placówka",
            serviceName: attributes.benefit ?? "Nieznane świadczenie",
            location: attributes.locality ?? "",
            firstAvailableDate: dateStr,
            waitingTime: waitingTimeStr,
            phoneNumber: attributes.phone,
            address: attributes.address,
            numberOfWaiting: attributes.statistics?.providerData?.awaiting,
            lastUpdated: Date(),
            dataPreparationDate: dataSituationStr,
            caseType: attributes.case,
            latitude: attributes.latitude,
            longitude: attributes.longitude,
            placeName: attributes.place,
            averageWaitingDays: attributes.statistics?.providerData?.averagePeriod ?? attributes.statistics?.computedData?.averagePeriod
        )
    }
    
    /// Calculate distance from user's location using coordinates if available
    func calculateDistanceFromCoordinates(userLocation: CLLocation) -> Double? {
        guard let lat = latitude, let lon = longitude else { return nil }
        let appointmentLocation = CLLocation(latitude: lat, longitude: lon)
        return userLocation.distance(from: appointmentLocation) / 1000.0  // Convert to km
    }
    
    // Hashable conformance
    static func == (lhs: Appointment, rhs: Appointment) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum Voivodeship: String, CaseIterable, Identifiable {
    case dolnoslaskie = "dolnośląskie"
    case kujawskoPomorskie = "kujawsko-pomorskie"
    case lubelskie = "lubelskie"
    case lubuskie = "lubuskie"
    case lodzkie = "łódzkie"
    case malopolskie = "małopolskie"
    case mazowieckie = "mazowieckie"
    case opolskie = "opolskie"
    case podkarpackie = "podkarpackie"
    case podlaskie = "podlaskie"
    case pomorskie = "pomorskie"
    case slaskie = "śląskie"
    case swietokrzyskie = "świętokrzyskie"
    case warminskoMazurskie = "warmińsko-mazurskie"
    case wielkopolskie = "wielkopolskie"
    case zachodniopomorskie = "zachodniopomorskie"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .dolnoslaskie: return "Dolnośląskie"
        case .kujawskoPomorskie: return "Kujawsko-Pomorskie"
        case .lubelskie: return "Lubelskie"
        case .lubuskie: return "Lubuskie"
        case .lodzkie: return "Łódzkie"
        case .malopolskie: return "Małopolskie"
        case .mazowieckie: return "Mazowieckie"
        case .opolskie: return "Opolskie"
        case .podkarpackie: return "Podkarpackie"
        case .podlaskie: return "Podlaskie"
        case .pomorskie: return "Pomorskie"
        case .slaskie: return "Śląskie"
        case .swietokrzyskie: return "Świętokrzyskie"
        case .warminskoMazurskie: return "Warmińsko-Mazurskie"
        case .wielkopolskie: return "Wielkopolskie"
        case .zachodniopomorskie: return "Zachodniopomorskie"
        }
    }
    
    var fileID: String {
        switch self {
        case .dolnoslaskie: return "45fc4182-1dcd-25aa-e063-b4200a0a751b"
        case .kujawskoPomorskie: return "45fc5222-cd85-9739-e063-b4200a0a78c0"
        case .lubelskie: return "45fc5429-3ab0-ba1b-e063-b4200a0af4c4"
        case .lubuskie: return "45fc5429-3ab1-ba1b-e063-b4200a0af4c4"
        case .lodzkie: return "45fc5762-77c1-ce0c-e063-b4200a0a3c21"
        case .malopolskie: return "45fc59f2-b860-e575-e063-b4200a0a3730"
        case .mazowieckie: return "45fde959-0f4b-b7f7-e063-b4200a0af33c"
        case .opolskie: return "45fc5c60-251c-ee6b-e063-b4200a0a6c46"
        case .podkarpackie: return "45fc5e44-466e-06a1-e063-b4200a0af845"
        case .podlaskie: return "45fc607e-5c87-1b03-e063-b4200a0a2515"
        case .pomorskie: return "45fc630f-700a-27ff-e063-b4200a0a193b"
        case .slaskie: return "45fc6734-4428-4920-e063-b4200a0a8ca7"
        case .swietokrzyskie: return "45fc8269-3f4b-176c-e063-b4200a0a9b89"
        case .warminskoMazurskie: return "45fc8478-c807-3445-e063-b4200a0a64cb"
        case .wielkopolskie: return "45fc8478-c808-3445-e063-b4200a0a64cb"
        case .zachodniopomorskie: return "45fc8768-3a19-3c1a-e063-b4200a0aee51"
        }
    }
    
    var centerCoordinates: (lat: Double, lon: Double) {
        switch self {
        case .dolnoslaskie: return (51.1, 17.0)
        case .kujawskoPomorskie: return (53.0, 18.5)
        case .lubelskie: return (51.2, 22.6)
        case .lubuskie: return (52.0, 15.5)
        case .lodzkie: return (51.8, 19.5)
        case .malopolskie: return (50.1, 19.9)
        case .mazowieckie: return (52.2, 21.0)
        case .opolskie: return (50.7, 17.9)
        case .podkarpackie: return (50.0, 22.0)
        case .podlaskie: return (53.1, 23.2)
        case .pomorskie: return (54.4, 18.6)
        case .slaskie: return (50.3, 19.0)
        case .swietokrzyskie: return (50.9, 20.6)
        case .warminskoMazurskie: return (53.8, 20.5)
        case .wielkopolskie: return (52.4, 16.9)
        case .zachodniopomorskie: return (53.4, 14.6)
        }
    }
    
    static func from(latitude: Double, longitude: Double) -> Voivodeship {
        var closest: Voivodeship = .mazowieckie
        var minDistance: Double = Double.infinity
        
        for voivodeship in Voivodeship.allCases {
            let coords = voivodeship.centerCoordinates
            let distance = sqrt(pow(latitude - coords.lat, 2) + pow(longitude - coords.lon, 2))
            if distance < minDistance {
                minDistance = distance
                closest = voivodeship
            }
        }
        
        return closest
    }
}
