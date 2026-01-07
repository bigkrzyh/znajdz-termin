//
//  ServiceNamePickerView.swift
//  Znajdz Termin
//
//  Created by Krzysztof Kuźmicki on 29/12/2025.
//

import SwiftUI

struct ServiceNamePickerView: View {
    @Binding var selectedServiceName: String?
    let serviceNames: [String]
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    
    var filteredServiceNames: [String] {
        if searchText.isEmpty {
            return serviceNames
        }
        return serviceNames.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField(L10n.searchServiceName, text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
                .padding()
                
                List {
                    // "All" option
                    Button(action: {
                        selectedServiceName = nil
                        dismiss()
                    }) {
                        HStack {
                            Text(L10n.all)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedServiceName == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    ForEach(filteredServiceNames, id: \.self) { serviceName in
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
    ServiceNamePickerView(
        selectedServiceName: .constant(nil),
        serviceNames: ["Kardiologia", "Neurologia", "Ortopedia", "Okulistyka"]
    )
}
