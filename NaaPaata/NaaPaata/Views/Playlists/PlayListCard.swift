//
//  PlayListCard.swift
//  NaaPaata
//

import SwiftUI
import UIKit

struct PlaylistCard: View {

    let playlist: Playlist
    let cardHeight: CGFloat

    private var coverImage: UIImage? {
        guard let data = playlist.coverImageData else { return nil }
        return UIImage(data: data)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            ZStack {
                // Glow
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        RadialGradient(
                            colors: [Color.accentColor.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 60,
                            endRadius: 90
                        )
                    )
                    .frame(height: cardHeight)
                    .blur(radius: 20)

                // Card
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .frame(height: cardHeight)
                    .overlay(
                        GeometryReader { geometry in
                            ZStack {
                                if let coverImage {
                                    Image(uiImage: coverImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(
                                            width: geometry.size.width,
                                            height: geometry.size.height
                                        )
                                        .clipped()
                                } else {
                                    Image(systemName: "music.note")
                                        .font(.system(size: 48))
                                        .foregroundStyle(Color.accentColor)
                                        .frame(
                                            width: geometry.size.width,
                                            height: geometry.size.height
                                        )
                                }
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.white.opacity(0.2), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(songCountLabel)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var songCountLabel: String {
        let count = playlist.songRelativePaths.count
        if count == 0 { return "Empty" }
        return "\(count) song\(count == 1 ? "" : "s")"
    }
}
