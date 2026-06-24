//
//  CircularAlbumArtwork.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 6/24/26.
//

import SwiftUI

struct CircularAlbumArtwork: View {
    let artwork: UIImage?
    let size: CGFloat
    let isPlaying: Bool
    let colorScheme: ColorScheme

    var body: some View {
        Circle()
            .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.3))
            .frame(width: size, height: size)
            .overlay(
                Group {
                    if let artwork = artwork {
                        Image(uiImage: artwork)
                            .resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: size * 0.3, weight: .thin))
                                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.5))
                            )
                    }
                }
            )
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.15),
                                colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: .black.opacity(0.4), radius: 15, x: 0, y: 8)
    }
}
