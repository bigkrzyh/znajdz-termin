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
    @State private var searchHistory: [String] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Wpisz nazwę świadczenia...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: searchText) { newValue in
                                // Trigger API search after 2 characters
                                if newValue.count >= 2 {
                                    isSearching = true
                                    Task {
                                        await service.searchServiceNames(query: newValue)
                                        isSearching = false
                                    }
                                } else {
                                    service.serviceNames = []
                                }
                            }
                        
                        if isSearching {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else if !searchText.isEmpty {
                            Button(action: { 
                                searchText = ""
                                service.serviceNames = []
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
                        Text("Wpisz min. 2 znaki aby wyszukać w bazie NFZ")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if searchText.count < 2 {
                        Text("Wpisz jeszcze \(2 - searchText.count) znak(i) aby wyszukać")
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
                    
                    // Show search results if searching
                    if !searchText.isEmpty && searchText.count >= 2 {
                        // Custom search option
                        if !service.serviceNames.contains(where: { $0.localizedCaseInsensitiveCompare(searchText) == .orderedSame }) {
                            Button(action: {
                                selectServiceName(searchText.uppercased())
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
                        
                        // API search results
                        if !service.serviceNames.isEmpty {
                            Section(header: Text("Wyniki wyszukiwania").font(.caption)) {
                                ForEach(service.serviceNames, id: \.self) { serviceName in
                                    Button(action: {
                                        selectServiceName(serviceName)
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
                            }
                        } else if !isSearching {
                            // No results state
                            HStack {
                                Spacer()
                                VStack(spacing: 8) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.title)
                                        .foregroundColor(.secondary)
                                    Text("Brak wyników dla \"\(searchText)\"")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 20)
                                Spacer()
                            }
                        }
                    } else {
                        // Show history when not searching
                        if !searchHistory.isEmpty {
                            Section(header: 
                                HStack {
                                    Text("Historia wyszukiwania")
                                        .font(.caption)
                                    Spacer()
                                    Button(action: {
                                        service.clearSearchHistory()
                                        searchHistory = []
                                    }) {
                                        Text("Wyczyść")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                            ) {
                                ForEach(searchHistory, id: \.self) { historyItem in
                                    HStack {
                                        Button(action: {
                                            selectServiceName(historyItem)
                                        }) {
                                            HStack {
                                                Image(systemName: "clock.arrow.circlepath")
                                                    .foregroundColor(.secondary)
                                                    .frame(width: 24)
                                                Text(historyItem)
                                                    .foregroundColor(.primary)
                                                    .lineLimit(2)
                                                Spacer()
                                                if selectedServiceName == historyItem {
                                                    Image(systemName: "checkmark")
                                                        .foregroundColor(.blue)
                                                }
                                            }
                                        }
                                        
                                        // Delete button
                                        Button(action: {
                                            withAnimation {
                                                service.removeFromSearchHistory(historyItem)
                                                searchHistory = service.getSearchHistory()
                                            }
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.gray)
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                    }
                                }
                            }
                        } else {
                            // Empty state - no history
                            HStack {
                                Spacer()
                                VStack(spacing: 12) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary)
                                    Text("Wyszukaj świadczenie")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    Text("Wpisz nazwę świadczenia powyżej\nnp. \"kardiolog\", \"ortopeda\", \"rezonans\"")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.vertical, 40)
                                Spacer()
                            }
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
            .onAppear {
                searchHistory = service.getSearchHistory()
            }
        }
    }
    
    private func selectServiceName(_ name: String) {
        selectedServiceName = name
        service.addToSearchHistory(name)
        dismiss()
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
