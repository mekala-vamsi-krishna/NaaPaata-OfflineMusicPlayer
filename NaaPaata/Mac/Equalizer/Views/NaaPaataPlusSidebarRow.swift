//
//  NaaPaataPlusSidebarRow.swift
//  Mac
//
//  Created by Mekala Vamsi Krishna on 10/5/26.
//

import SwiftUI

struct NaaPaataPlusSidebarRow: View {

    let isSelected: Bool
    let isSubscribed: Bool

    var body: some View {
        HStack(spacing: 10) {

            // Sparkle badge — the visual identity of Naa Paata +
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: isSubscribed
                                ? [.green, .green.opacity(0.75)]
                                : [Color.accentColor, Color.accentColor.opacity(0.75)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 20, height: 20)

                Image(systemName: isSubscribed ? "checkmark.seal.fill" : "sparkles")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text("Naa Paata +")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Preview

#Preview {
    List {
        NaaPaataPlusSidebarRow(isSelected: false, isSubscribed: false)
        NaaPaataPlusSidebarRow(isSelected: true,  isSubscribed: false)
        NaaPaataPlusSidebarRow(isSelected: false, isSubscribed: true)
    }
    .listStyle(.sidebar)
    .frame(width: 240, height: 200)
}
