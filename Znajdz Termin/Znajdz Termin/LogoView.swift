//
//  LogoView.swift
//  Znajdz Termin
//
//  Created by Krzysztof Kuźmicki on 29/12/2025.
//

import SwiftUI

struct LogoView: View {
    var size: CGFloat = 40
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.red)
                .frame(width: size, height: size)
            
            // White cross
            Rectangle()
                .fill(Color.white)
                .frame(width: size * 0.5, height: size * 0.15)
                .cornerRadius(2)
            
            Rectangle()
                .fill(Color.white)
                .frame(width: size * 0.15, height: size * 0.5)
                .cornerRadius(2)
        }
    }
}

#Preview {
    LogoView(size: 60)
}
