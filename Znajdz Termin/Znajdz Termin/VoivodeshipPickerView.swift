//
//  VoivodeshipPickerView.swift
//  Znajdz Termin
//
//  Created by Krzysztof Kuźmicki on 29/12/2025.
//

import SwiftUI

struct VoivodeshipPickerView: View {
    @Binding var selectedVoivodeship: Voivodeship?
    var onSelect: ((Voivodeship) -> Void)?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Voivodeship.allCases) { voivodeship in
                    Button(action: {
                        selectedVoivodeship = voivodeship
                        onSelect?(voivodeship)
                        dismiss()
                    }) {
                        HStack {
                            Text(voivodeship.displayName)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedVoivodeship == voivodeship {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle(L10n.voivodeship)
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
    VoivodeshipPickerView(selectedVoivodeship: .constant(.mazowieckie))
}
