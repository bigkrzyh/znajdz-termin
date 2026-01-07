//
//  ResultsView.swift
//  Znajdz Termin
//
//  Created by Krzysztof Kuźmicki on 30/12/2025.
//

import SwiftUI

struct ResultsView: View {
    @ObservedObject var service: NFZService
    @State private var showSortOptions = false
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            sortingBar
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
            
            VStack(spacing: 2) {
                Text(L10n.results)
                    .font(.headline)
                Text(L10n.resultsCount(service.displayedAppointments.count, service.totalResultsCount > 0 ? service.totalResultsCount : service.appointments.count))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Sort button
            Button(action: { showSortOptions = true }) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.body.weight(.medium))
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .actionSheet(isPresented: $showSortOptions) {
            ActionSheet(
                title: Text("Sortuj według"),
                buttons: SortOption.allCases.map { option in
                    .default(Text(sortOptionLabel(option))) {
                        service.changeSortOption(option)
                    }
                } + [.cancel(Text(L10n.cancel))]
            )
        }
    }
    
    private func sortOptionLabel(_ option: SortOption) -> String {
        let checkmark = service.sortOption == option ? " ✓" : ""
        return option.rawValue + checkmark
    }
    
    private var sortingBar: some View {
        VStack(spacing: 6) {
            // Voivodeship and service info
            HStack {
                if let voivodeship = service.selectedVoivodeship {
                    Label(voivodeship.displayName, systemImage: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                // Current sort indicator
                HStack(spacing: 4) {
                    Image(systemName: service.sortOption.icon)
                        .font(.caption)
                    Text(service.sortOption.rawValue)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            // Service name if selected
            if let serviceName = service.selectedServiceName {
                HStack {
                    Text(serviceName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
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
