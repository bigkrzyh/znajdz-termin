//
//  ServiceNamePickerView.swift
//  Znajdz Termin
//
//  Created by Krzysztof Kuźmicki on 29/12/2025.
//

import SwiftUI

struct ServiceNamePickerView: View {
    @Binding var selectedServiceName: String?
    @ObservedObject var service: NFZService
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var isSearching = false
    
    var displayedNames: [String] {
        if searchText.isEmpty {
            return service.serviceNames
        }
        // Filter locally for better UX
        return service.serviceNames.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar with API search capability
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField(L10n.searchServiceName, text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .onChange(of: searchText) { newValue in
                                // Trigger API search after 3 characters
                                if newValue.count >= 3 {
                                    isSearching = true
                                    Task {
                                        await service.searchServiceNames(query: newValue)
                                        isSearching = false
                                    }
                                }
                            }
                        
                        if isSearching {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else if !searchText.isEmpty {
                            Button(action: { 
                                searchText = ""
                                // Reset to common benefits
                                Task {
                                    await service.searchServiceNames(query: "")
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                    
                    // Hint text
                    if searchText.isEmpty {
                        Text("Popularne świadczenia lub wpisz min. 3 znaki aby wyszukać")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if searchText.count < 3 {
                        Text("Wpisz jeszcze \(3 - searchText.count) znak(i) aby wyszukać w bazie NFZ")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                
                List {
                    // "All" option - search without service filter
                    Button(action: {
                        selectedServiceName = nil
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "list.bullet")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text(L10n.all)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedServiceName == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    // Custom search option - allows user to search with their typed text
                    if searchText.count >= 3 && !displayedNames.contains(where: { $0.localizedCaseInsensitiveCompare(searchText) == .orderedSame }) {
                        Button(action: {
                            selectedServiceName = searchText
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.orange)
                                    .frame(width: 24)
                                VStack(alignment: .leading) {
                                    Text("Szukaj: \"\(searchText)\"")
                                        .foregroundColor(.primary)
                                    Text("Użyj własnego wyszukiwania")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                        }
                    }
                    
                    // Service names list
                    ForEach(displayedNames, id: \.self) { serviceName in
                        Button(action: {
                            selectedServiceName = serviceName
                            dismiss()
                        }) {
                            HStack {
                                Text(serviceName)
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                Spacer()
                                if selectedServiceName == serviceName {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    
                    // Empty state
                    if displayedNames.isEmpty && searchText.count >= 3 && !isSearching {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                Text("Brak wyników dla \"\(searchText)\"")
                                    .foregroundColor(.secondary)
                                Text("Spróbuj innej nazwy świadczenia")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 40)
                            Spacer()
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle(L10n.serviceName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.cancel) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let locationManager = LocationManager()
    let service = NFZService(locationManager: locationManager)
    return ServiceNamePickerView(
        selectedServiceName: .constant(nil),
        service: service
    )
}
