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

    private let artworkSize: CGFloat = 34
    
    private let buttonSize: CGFloat = 40

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
        HStack(spacing: 8) {

            artworkView
                .frame(width: artworkSize, height: artworkSize)
                .aspectRatio(contentMode: .fill)
                .clipShape(.rect(cornerRadius: 5))
                .matchedGeometryEffect(id: "artwork", in: namespace)

            VStack(alignment: .leading, spacing: 1) {
                Text(song?.title ?? "Unknown Title")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .matchedGeometryEffect(id: "title", in: namespace)

                Text(song?.artist ?? "Unknown Artist")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .matchedGeometryEffect(id: "artist", in: namespace)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

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
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    let horizontal = value.translation.width
                    let vertical = value.translation.height
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
                    Color.accentColor.opacity(0.15)
                    Color.accentColor
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
        HStack(spacing: 8) {

            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.secondary.opacity(0.15))
                Image(systemName: "music.note")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            .frame(width: artworkSize, height: artworkSize)

            VStack(alignment: .leading, spacing: 1) {
                Text("Nothing Playing")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text("Pick a song to start")
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            Image(systemName: "play.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.tertiary)
                .frame(width: buttonSize, height: buttonSize)
                .opacity(0.5)
        }
        .padding(.horizontal, 10)
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
                        .font(.system(size: 18, weight: .medium))
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
                .frame(width: buttonSize, height: buttonSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}
