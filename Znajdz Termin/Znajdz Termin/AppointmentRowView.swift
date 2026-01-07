//
//  AppointmentRowView.swift
//  Znajdz Termin
//
//  Created by Krzysztof Kuźmicki on 29/12/2025.
//

import SwiftUI

struct AppointmentRowView: View {
    let appointment: Appointment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Facility name
            Text(decodeHTMLEntities(appointment.facilityName))
                .font(.headline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Service name
            InfoRow(
                icon: "stethoscope",
                text: decodeHTMLEntities(appointment.serviceName),
                color: .secondary
            )
            
            // Location
            InfoRow(
                icon: "mappin.circle.fill",
                text: decodeHTMLEntities(appointment.location),
                color: .secondary
            )
            
            // First available date
            if let date = appointment.firstAvailableDate, !date.isEmpty {
                InfoRow(
                    icon: "calendar",
                    text: date,
                    color: .blue
                )
            }
            
            // Waiting time
            if let waiting = appointment.waitingTime, !waiting.isEmpty {
                InfoRow(
                    icon: "clock.fill",
                    text: waiting,
                    color: .orange
                )
            }
            
            // Number waiting
            if let number = appointment.numberOfWaiting, number > 0 {
                InfoRow(
                    icon: "person.2.fill",
                    text: L10n.waitingCount(number),
                    color: .red
                )
            }
            
            // Address
            if let address = appointment.address, !address.isEmpty {
                InfoRow(
                    icon: "building.2.fill",
                    text: decodeHTMLEntities(address),
                    color: .secondary
                )
            }
            
            HStack(spacing: 16) {
                // Phone (tappable)
                if let phone = appointment.phoneNumber, !phone.isEmpty {
                    phoneButton(phone: phone)
                }
                
                // Distance (tappable - opens Maps)
                if let distance = appointment.distance {
                    distanceButton(distance: distance)
                }
            }
        }
    }
    
    private func phoneButton(phone: String) -> some View {
        let cleanPhone = phone
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        
        return Group {
            if let phoneURL = URL(string: "tel:\(cleanPhone)") {
                Link(destination: phoneURL) {
                    HStack(spacing: 4) {
                        Image(systemName: "phone.fill")
                        Text(phone)
                    }
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private func distanceButton(distance: Double) -> some View {
        Button(action: {
            openMapsNavigation()
        }) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                Text(String(format: "%.1f km", distance))
            }
            .font(.subheadline)
            .foregroundColor(.blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private func openMapsNavigation() {
        // Build address for navigation
        var addressComponents: [String] = []
        
        if let address = appointment.address {
            addressComponents.append(decodeHTMLEntities(address))
        } else {
            addressComponents.append(decodeHTMLEntities(appointment.location))
        }
        
        let fullAddress = addressComponents.joined(separator: ", ")
        
        // Encode address for URL
        guard let encodedAddress = fullAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return
        }
        
        // Try Apple Maps first with navigation mode
        if let mapsURL = URL(string: "maps://?daddr=\(encodedAddress)&dirflg=d") {
            if UIApplication.shared.canOpenURL(mapsURL) {
                UIApplication.shared.open(mapsURL)
                return
            }
        }
        
        // Fallback to Google Maps if installed
        if let googleMapsURL = URL(string: "comgooglemaps://?daddr=\(encodedAddress)&directionsmode=driving") {
            if UIApplication.shared.canOpenURL(googleMapsURL) {
                UIApplication.shared.open(googleMapsURL)
                return
            }
        }
        
        // Final fallback to web maps
        if let webMapsURL = URL(string: "https://maps.apple.com/?daddr=\(encodedAddress)&dirflg=d") {
            UIApplication.shared.open(webMapsURL)
        }
    }
    
    /// Decode HTML entities in text
    private func decodeHTMLEntities(_ text: String) -> String {
        var result = text
        
        // Common HTML entities
        let entities: [String: String] = [
            "&quot;": "\"",
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&apos;": "'",
            "&nbsp;": " ",
            "&#x27;": "'",
            "&#39;": "'",
            "&#x22;": "\"",
            "&#34;": "\"",
            "&#x26;": "&",
            "&#38;": "&"
        ]
        
        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }
        
        return result
    }
}

/// Helper view for consistent info row alignment
struct InfoRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20, alignment: .center)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(color)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    AppointmentRowView(appointment: Appointment(
        voivodeship: "mazowieckie",
        facilityName: "Szpital Testowy &quot;Pod Lipą&quot;",
        serviceName: "Kardiologia",
        location: "Warszawa",
        firstAvailableDate: "2025-01-15",
        waitingTime: "30 dni",
        phoneNumber: "+48 123 456 789",
        address: "ul. Testowa 1, Warszawa",
        numberOfWaiting: 10,
        distance: 5.5
    ))
    .padding()
}
