//
//  ResultsView.swift
//  Znajdz Termin
//
//  Created by Krzysztof Kuźmicki on 30/12/2025.
//

import SwiftUI

struct ResultsView: View {
    @ObservedObject var service: NFZService
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            dataInfoBar
            resultsList
            if service.hasMoreResults || service.isLoadingMore {
                loadingMoreIndicator
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    private var headerView: some View {
        HStack {
            Button(action: {
                service.goBackToSearch()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.medium))
                    Text(L10n.back)
                }
                .foregroundColor(.blue)
            }
            
            Spacer()
            
            Text(L10n.results)
                .font(.headline)
            
            Spacer()
            
            // Balance the layout
            Text(L10n.back)
                .opacity(0)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
    
    private var dataInfoBar: some View {
        VStack(spacing: 6) {
            // Voivodeship and count
            HStack {
                if let voivodeship = service.selectedVoivodeship {
                    Label(voivodeship.displayName, systemImage: "mappin.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text(L10n.resultsCount(service.displayedAppointments.count, service.totalResultsCount > 0 ? service.totalResultsCount : service.appointments.count))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Service name
            if let serviceName = service.selectedServiceName {
                HStack {
                    Text(serviceName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Spacer()
                }
            }
            
            // Data date from Excel
            if let dataDate = service.dataDateString {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text(L10n.dataCurrentAsOf(dataDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if service.displayedAppointments.isEmpty && !service.isSearching {
                    emptyResultsView
                } else {
                    ForEach(service.displayedAppointments) { appointment in
                        AppointmentRowView(appointment: appointment)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.systemBackground))
                            .onAppear {
                                service.loadMoreIfNeeded(currentItem: appointment)
                            }
                        
                        Divider()
                    }
                }
            }
        }
        .refreshable {
            await service.refreshData()
        }
    }
    
    private var loadingMoreIndicator: some View {
        HStack {
            if service.isLoadingMore {
                ProgressView()
                    .padding(.trailing, 8)
                Text(L10n.loadingMore)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if service.hasMoreResults {
                Text(L10n.scrollToLoadMore)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    private var emptyResultsView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(L10n.noResults)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(L10n.tryDifferentCriteria)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                service.goBackToSearch()
            }) {
                Text(L10n.changeCriteria)
                    .fontWeight(.medium)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 400)
    }
}

#Preview {
    let locationManager = LocationManager()
    let service = NFZService(locationManager: locationManager)
    return ResultsView(service: service)
}
