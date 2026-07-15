//
//  MiniPlayerView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 9/21/25.
//

import SwiftUI

struct MiniPlayerView: View {
    @EnvironmentObject var musicPlayerManager: MusicPlayerManager
    var namespace: Namespace.ID

    var body: some View {
        if #available(iOS 26.0, *) {
            HStack(spacing: 12) {
                // Artwork
                if let artwork = musicPlayerManager.artworkImage {
                    Image(uiImage: artwork)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .matchedGeometryEffect(id: "artwork", in: namespace)
                } else {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 48, height: 48)
                        .matchedGeometryEffect(id: "artwork", in: namespace)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(musicPlayerManager.currentSong?.title ?? "Unknown")
                        .font(.system(.headline, design: .rounded))
                        .lineLimit(1)
                        .foregroundColor(.primary)
                        .matchedGeometryEffect(id: "title", in: namespace)

                    Text(musicPlayerManager.currentSong?.artist ?? "Artist")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .matchedGeometryEffect(id: "artist", in: namespace)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                // Play/Pause
                Button {
                    musicPlayerManager.togglePlayPause()
                } label: {
                    Image(systemName: musicPlayerManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 36, height: 36)
                        .matchedGeometryEffect(id: "playButton", in: namespace)
                }
                .buttonStyle(.plain)

                // Next
                Button {
                    musicPlayerManager.playNext()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 36, height: 36)
                        .matchedGeometryEffect(id: "nextButton", in: namespace)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .glassEffect()
            .contentShape(Rectangle())
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
        } else {
            HStack(spacing: 12) {
                // Artwork
                if let artwork = musicPlayerManager.artworkImage {
                    Image(uiImage: artwork)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .matchedGeometryEffect(id: "artwork", in: namespace)
                } else {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 48, height: 48)
                        .matchedGeometryEffect(id: "artwork", in: namespace)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(musicPlayerManager.currentSong?.title ?? "Unknown")
                        .font(.system(.headline, design: .rounded))
                        .lineLimit(1)
                        .foregroundColor(.primary)
                        .matchedGeometryEffect(id: "title", in: namespace)
                    
                    Text(musicPlayerManager.currentSong?.artist ?? "Artist")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .matchedGeometryEffect(id: "artist", in: namespace)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Play/Pause
                Button {
                    musicPlayerManager.togglePlayPause()
                } label: {
                    Image(systemName: musicPlayerManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 36, height: 36)
                        .matchedGeometryEffect(id: "playButton", in: namespace)
                }
                .buttonStyle(.plain)
                
                // Next
                Button {
                    musicPlayerManager.playNext()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 36, height: 36)
                        .matchedGeometryEffect(id: "nextButton", in: namespace)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
                    .matchedGeometryEffect(id: "playerBackground", in: namespace)
            )
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
        }
    }
}
