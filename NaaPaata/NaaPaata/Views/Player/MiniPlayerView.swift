//
//  MiniPlayerView.swift
//  NaaPaata
//

import SwiftUI
import UIKit

struct MiniPlayerView: View {

    @EnvironmentObject private var libraryViewModel: MusicLibraryViewModel
    @EnvironmentObject private var progressStore: PlaybackProgressStore
    
    var namespace: Namespace.ID

    private var song: Song? { libraryViewModel.currentSong }

    private var artworkImage: UIImage? {
        guard let data = song?.artworkData else { return nil }
        return UIImage(data: data)
    }

    private var isPlaying: Bool { libraryViewModel.isPlaying }

    private let artworkSize: CGFloat = 38
    
    private var progress: Double {
        guard let song = song, let duration = song.duration, duration > 0 else { return 0 }
        return min(max(progressStore.elapsed / duration, 0), 1)
    }

    var body: some View {
        if song == nil {
            emptyState
        } else {
            activePlayer
        }
    }

    // MARK: - Active Player

    private var activePlayer: some View {
        HStack(spacing: 12) {

            artworkView
                .frame(width: artworkSize, height: artworkSize)
                .aspectRatio(contentMode: .fill)
                .clipShape(.rect(cornerRadius: 5))
                .matchedGeometryEffect(id: "artwork", in: namespace)

            VStack(alignment: .leading, spacing: 2) {
                Text(song?.title ?? "Unknown Title")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .matchedGeometryEffect(id: "title", in: namespace)

                Text(song?.artist ?? "Unknown Artist")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .matchedGeometryEffect(id: "artist", in: namespace)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            playbackButton(
                systemName: isPlaying ? "pause.fill" : "play.fill",
                size: 22,
                accessibilityLabel: isPlaying ? "Pause" : "Play"
            ) {
                HapticManager.shared.light()
                libraryViewModel.togglePlayPause()
            }
            .matchedGeometryEffect(id: "playButton", in: namespace)

            playbackButton(
                systemName: "forward.fill",
                size: 20,
                accessibilityLabel: "Next Track"
            ) {
                HapticManager.shared.light()
                libraryViewModel.playNext()
            }
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Swipe left/right to change the track
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    let horizontal = value.translation.width
                    let vertical = value.translation.height

                    // if the swipe is mostly horizontal then swipe it or else return
                    guard abs(horizontal) > abs(vertical) else { return }

                    if horizontal < -50 {
                        HapticManager.shared.light()
                        libraryViewModel.playNext()
                    } else if horizontal > 50 {
                        HapticManager.shared.light()
                        libraryViewModel.playPrevious()
                    }
                }
        )
        .overlay(alignment: .bottom) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Color.appAccent.opacity(0.15)
                    Color.appAccent
                        .frame(width: geo.size.width * progress)
                }
                .clipShape(
                    .rect(
                        topLeadingRadius: 2,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 2
                    )
                )
            }
            .frame(height: 3)
            .allowsHitTesting(false)
            .animation(.linear(duration: 0.25), value: progress)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        HStack(spacing: 12) {

            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.secondary.opacity(0.15))
                Image(systemName: "music.note")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            .frame(width: artworkSize, height: artworkSize)

            VStack(alignment: .leading, spacing: 2) {
                Text("Nothing Playing")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("Pick a song to start")
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "play.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.tertiary)
                .frame(width: 48, height: 48)
                .opacity(0.5)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Artwork

    @ViewBuilder
    private var artworkView: some View {
        Group {
            if let artworkImage {
                Image(uiImage: artworkImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: artworkSize, height: artworkSize)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.secondary.opacity(0.16))
                    Image(systemName: "music.note")
                        .font(.system(size: 19, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(width: artworkSize, height: artworkSize)
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: - Playback Button

    private func playbackButton(
        systemName: String,
        size: CGFloat,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(.primary)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 48, height: 48)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}
