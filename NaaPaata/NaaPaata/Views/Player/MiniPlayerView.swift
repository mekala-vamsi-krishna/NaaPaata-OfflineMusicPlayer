//
//  MiniPlayerView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 9/21/25.
//

import SwiftUI

struct MiniPlayerView: View {
    @EnvironmentObject var musicPlayerManager: MusicPlayerManager
    let namespace: Namespace.ID

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let artwork = musicPlayerManager.artworkImage {
                    Image(uiImage: artwork)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        Color(.systemGray5)
                        Image(systemName: "music.note")
                            .resizable()
                            .scaledToFit()
                            .padding(12)
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(Circle())
            .matchedGeometryEffect(id: "albumArt", in: namespace, isSource: true)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

            // Song Info
            VStack(alignment: .leading, spacing: 2) {
                Text(musicPlayerManager.currentSong?.title ?? "Unknown Song")
                    .foregroundStyle(.primary)
                    .font(.subheadline)
                    .lineLimit(1)

                Text(musicPlayerManager.currentSong?.artist ?? "Unknown Artist")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            // Playback Controls
            HStack(spacing: 16) {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        musicPlayerManager.togglePlayPause()
                    }
                } label: {
                    Image(systemName: musicPlayerManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .contentTransition(.symbolEffect(.replace))
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)

                Button {
                    musicPlayerManager.playNext()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title3)
                        .foregroundStyle(.primary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: -2)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.3),
                            .white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: musicPlayerManager.isPlaying)
    }
}

#Preview {
    @Namespace var animation
    MiniPlayerView(namespace: animation)
        .environmentObject(MusicPlayerManager.shared)
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color(.systemBackground))
}
