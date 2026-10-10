//
//  ArtistRowView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/26/26.
//

import SwiftUI
import AppKit

struct ArtistRowView: View {

    let artist: Artist

    var body: some View {
        HStack(spacing: 12) {
            artwork

            VStack(alignment: .leading, spacing: 2) {
                Text(artist.name)
                    .font(.body)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)

                Text(artist.subtitle)
                    .font(.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 16)

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    /// Circular artwork — the standard visual cue for "artist" versus
    /// "album" in music apps.
    private var artwork: some View {
        ZStack {
            if let data = artist.artworkData,
               let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    AppColor.brandGradient
                    Image(systemName: "music.mic")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
        .overlay(
            Circle().strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
    }
}
