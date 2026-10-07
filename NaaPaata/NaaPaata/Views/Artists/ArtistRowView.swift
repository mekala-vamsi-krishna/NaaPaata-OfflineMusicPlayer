//
//  ArtistRowView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/7/26.
//

import SwiftUI
import UIKit

struct ArtistRowView: View {

    let artist: Artist

    var body: some View {
        HStack(spacing: 14) {

            artwork

            VStack(alignment: .leading, spacing: 3) {
                Text(artist.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    // MARK: - Artwork

    @ViewBuilder
    private var artwork: some View {
        Group {
            if let image = artist.artworkImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.35),
                            Color.accentColor.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Image(systemName: "music.mic")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
        }
        .frame(width: 52, height: 52)
        .clipShape(Circle())
        .overlay(
            Circle().strokeBorder(.white.opacity(0.08), lineWidth: 0.5)
        )
    }

    // MARK: - Subtitle

    private var subtitle: String {
        let count = artist.songs.count
        let countText = count == 1 ? "1 song" : "\(count) songs"

        // If total duration is available, show it as a secondary hint.
        if artist.totalDuration > 0 {
            return "\(countText) · \(artist.formattedTotalDuration)"
        }
        return countText
    }
}
