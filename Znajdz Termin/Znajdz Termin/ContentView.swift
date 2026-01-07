//
//  ContentView.swift
//  Znajdz Termin
//
//  Created by Krzysztof Kuźmicki on 29/12/2025.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var service: NFZService
    
    @State private var showVoivodeshipPicker = false
    @State private var showServiceNamePicker = false
    
    init() {
        let locationMgr = LocationManager()
        _locationManager = StateObject(wrappedValue: locationMgr)
        _service = StateObject(wrappedValue: NFZService(locationManager: locationMgr))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            NavigationView {
                ZStack {
                    // Search screen
                    if !service.showResults {
                        SearchView(
                            service: service,
                            locationManager: locationManager,
                            showVoivodeshipPicker: $showVoivodeshipPicker,
                            showServiceNamePicker: $showServiceNamePicker
                        )
                        .transition(.opacity)
                    }
                    
                    // Results screen
                    if service.showResults {
                        ResultsView(service: service)
                            .transition(.move(edge: .trailing))
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: service.showResults)
                .navigationBarHidden(true)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            
            // Ad Banner at bottom
            AdBannerContainerView()
        }
        .edgesIgnoringSafeArea(.bottom)
        .sheet(isPresented: $showVoivodeshipPicker) {
            VoivodeshipPickerView(
                selectedVoivodeship: $service.selectedVoivodeship,
                onSelect: { voivodeship in
                    Task {
                        await service.selectVoivodeship(voivodeship)
                    }
                }
            )
        }
        .sheet(isPresented: $showServiceNamePicker) {
            ServiceNamePickerView(
                selectedServiceName: $service.selectedServiceName,
                serviceNames: service.serviceNames
            )
        }
        .onAppear {
            locationManager.requestPermission()
        }
    }
}

struct SearchView: View {
    @ObservedObject var service: NFZService
    @ObservedObject var locationManager: LocationManager
    @Binding var showVoivodeshipPicker: Bool
    @Binding var showServiceNamePicker: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            ScrollView {
                VStack(spacing: 16) {
                    instructionText
                    filtersView
                    searchButton
                }
                .padding(.top)
            }
            
            Spacer(minLength: 0)
            bottomInfoBar
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    private var headerView: some View {
        HStack(spacing: 12) {
            LogoView(size: 44)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.appName)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(L10n.appSubtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
    
    private var instructionText: some View {
        Group {
            if service.selectedVoivodeship == nil {
                HStack {
                    Image(systemName: "hand.point.up.left.fill")
                        .foregroundColor(.blue)
                    Text(L10n.selectVoivodeshipHint)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            }
        }
    }
    
    private var filtersView: some View {
        VStack(spacing: 12) {
            // Voivodeship picker
            Button(action: { showVoivodeshipPicker = true }) {
                HStack {
                    Image(systemName: "map.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text(service.selectedVoivodeship?.displayName ?? L10n.selectVoivodeship)
                        .foregroundColor(service.selectedVoivodeship != nil ? .primary : .secondary)
                    
                    Spacer()
                    
                    if service.isLoadingServiceNames {
                        ProgressView()
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(10)
            }
            .disabled(service.isLoadingServiceNames)
            
            // Service name picker
            Button(action: { 
                if service.isServiceNamesReady {
                    showServiceNamePicker = true 
                }
            }) {
                HStack {
                    Image(systemName: "stethoscope")
                        .foregroundColor(service.isServiceNamesReady ? .green : .gray)
                        .frame(width: 24)
                    
                    Group {
                        if service.isLoadingServiceNames {
                            Text(L10n.loadingServices)
                        } else if !service.isServiceNamesReady {
                            Text(L10n.selectVoivodeshipFirst)
                        } else {
                            Text(service.selectedServiceName ?? L10n.serviceNameOptional)
                        }
                    }
                    .foregroundColor(service.isServiceNamesReady && service.selectedServiceName != nil ? .primary : .secondary)
                    .lineLimit(1)
                    
                    Spacer()
                    
                    if service.isLoadingServiceNames {
                        ProgressView()
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(service.isServiceNamesReady ? .secondary : .clear)
                    }
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(10)
                .opacity(service.isServiceNamesReady ? 1.0 : 0.6)
            }
            .disabled(!service.isServiceNamesReady)
            
            // Location filter
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.orange)
                    .frame(width: 24)
                
                TextField(L10n.locationOptional, text: $service.locationFilter)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(10)
            
            // Urgent cases toggle (Pilne)
            HStack {
                Image(systemName: service.showUrgentOnly ? "exclamationmark.circle.fill" : "exclamationmark.circle")
                    .foregroundColor(service.showUrgentOnly ? .red : .gray)
                    .frame(width: 24)
                
                Toggle(isOn: $service.showUrgentOnly) {
                    Text(L10n.urgentCases)
                        .foregroundColor(.primary)
                }
                .tint(.red)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(10)
        }
        .padding(.horizontal)
    }
    
    private var searchButton: some View {
        Button(action: {
            Task {
                await service.search()
            }
        }) {
            HStack(spacing: 8) {
                if service.isSearching {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "magnifyingglass")
                    Text(L10n.searchButton)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(service.isServiceNamesReady ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!service.isServiceNamesReady || service.isSearching)
        .padding(.horizontal)
    }
    
    private var bottomInfoBar: some View {
        VStack(spacing: 8) {
            if let error = service.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                }
            }
            
            HStack {
                Text(formatDate(Date()))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let lastUpdate = service.lastUpdateDate {
                    Text(L10n.dataLabel(formatDate(lastUpdate)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pl_PL")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    ContentView()
}
