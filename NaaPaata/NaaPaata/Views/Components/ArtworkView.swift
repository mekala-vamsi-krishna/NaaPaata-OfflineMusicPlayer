//
//  ArtworkView.swift
//  NaaPaata
//

import SwiftUI
import UIKit

struct ArtworkView: View {

    let data: Data?
    var size: CGFloat
    var cornerRadius: CGFloat = 6

    var body: some View {
        Group {
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fill)
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.accentColor.opacity(0.08))
        )
    }

    // MARK: - Placeholder

    private var placeholder: some View {
        ZStack {
            Color(uiColor: .secondarySystemFill)
            
            Image(systemName: "music.note")
                .font(.system(size: size * 0.42, weight: .medium))
                .foregroundStyle(Color.secondary)
        }
    }
}

// MARK: - Hex initializer

extension Color {
    /// Creates a color from a 24-bit RGB hex value.
    /// Example: `Color(hex: 0x9C1BA8)`.
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8)  & 0xFF) / 255,
            blue:  Double( hex        & 0xFF) / 255,
            opacity: opacity
        )
    }
}
