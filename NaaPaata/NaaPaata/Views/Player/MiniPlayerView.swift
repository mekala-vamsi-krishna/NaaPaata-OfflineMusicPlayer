//
//  MiniPlayerView.swift
//  NaaPaata
//

import SwiftUI
import UIKit

enum MiniPlayerStyle {
    case accessoryExpanded
    case accessoryInline
    case legacy
}

struct MiniPlayerView: View {

    @EnvironmentObject private var libraryViewModel: MusicLibraryViewModel

    let style: MiniPlayerStyle
    let onOpen: () -> Void

    private var isInline: Bool {
        style == .accessoryInline
    }

    private var artworkSize: CGFloat {
        isInline ? 26 : 38
    }

    private var song: Song? {
        libraryViewModel.currentSong
    }

    private var artworkImage: UIImage? {
        guard let data = song?.artworkData else { return nil }
        return UIImage(data: data)
    }

    private var isPlaying: Bool {
        libraryViewModel.isPlaying
    }

    // MARK: - Body

    var body: some View {
        if song == nil {
            emptyState
        } else {
            activePlayer
        }
    }

    // MARK: - Active player

    private var activePlayer: some View {
        HStack(spacing: isInline ? 6 : 12) {

            Button(action: onOpen) {
                HStack(spacing: isInline ? 6 : 12) {
                    artworkView
                    songInformation
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open Now Playing")

            playbackButton(
                systemName: isPlaying ? "pause.fill" : "play.fill",
                size: isInline ? 13 : 18,
                accessibilityLabel: isPlaying ? "Pause" : "Play"
            ) {
                HapticManager.shared.light()
                libraryViewModel.togglePlayPause()
            }

            if !isInline {
                playbackButton(
                    systemName: "forward.fill",
                    size: 16,
                    accessibilityLabel: "Next Track"
                ) {
                    HapticManager.shared.light()
                    libraryViewModel.playNext()
                }
            }
        }
        .padding(.horizontal, isInline ? 4 : 12)
        .frame(maxWidth: .infinity)
        .frame(height: isInline ? 38 : 64)
        .background(activeBackground)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: "Open Now Playing", onOpen)
    }

    // MARK: - Empty state (nothing playing)

    private var emptyState: some View {
        HStack(spacing: isInline ? 6 : 12) {

            // Placeholder artwork
            ZStack {
                RoundedRectangle(cornerRadius: isInline ? 5 : 8, style: .continuous)
                    .fill(Color.secondary.opacity(0.15))

                Image(systemName: "music.note")
                    .font(.system(size: isInline ? 11 : 17, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            .frame(width: artworkSize, height: artworkSize)

            VStack(alignment: .leading, spacing: 2) {
                Text("Nothing Playing")
                    .font(.system(size: isInline ? 12 : 15, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if !isInline {
                    Text("Pick a song to start")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Disabled play button — greyed out
            Image(systemName: "play.fill")
                .font(.system(size: isInline ? 13 : 18, weight: .semibold))
                .foregroundStyle(.tertiary)
                .frame(
                    width: isInline ? 28 : 40,
                    height: isInline ? 28 : 40
                )
                .opacity(0.5)

            if !isInline {
                Image(systemName: "forward.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .frame(width: 40, height: 40)
                    .opacity(0.5)
            }
        }
        .padding(.horizontal, isInline ? 4 : 12)
        .frame(maxWidth: .infinity)
        .frame(height: isInline ? 38 : 64)
        .background(emptyBackground)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Nothing playing")
    }

    // MARK: - Artwork

    @ViewBuilder
    private var artworkView: some View {
        if let artworkImage {
            Image(uiImage: artworkImage)
                .resizable()
                .scaledToFill()
                .frame(width: artworkSize, height: artworkSize)
                .clipShape(
                    RoundedRectangle(cornerRadius: isInline ? 5 : 8, style: .continuous)
                )
                .accessibilityHidden(true)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: isInline ? 5 : 8, style: .continuous)
                    .fill(Color.secondary.opacity(0.16))

                Image(systemName: "music.note")
                    .font(.system(size: isInline ? 11 : 19, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(width: artworkSize, height: artworkSize)
            .accessibilityHidden(true)
        }
    }

    // MARK: - Song info

    @ViewBuilder
    private var songInformation: some View {
        if isInline {
            Text(song?.title ?? "Unknown Title")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .allowsTightening(true)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 2) {
                Text(song?.title ?? "Unknown Title")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(song?.artist ?? "Unknown Artist")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
    }

    // MARK: - Backgrounds

    @ViewBuilder
    private var activeBackground: some View {
        switch style {
        case .legacy:
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(.white.opacity(0.12), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.18), radius: 12, y: 5)
        case .accessoryExpanded, .accessoryInline:
            Color.clear
        }
    }

    @ViewBuilder
    private var emptyBackground: some View {
        switch style {
        case .legacy:
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.6)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 0.5)
                }
        case .accessoryExpanded, .accessoryInline:
            Color.clear
        }
    }

    // MARK: - Button builder

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
                .frame(
                    width: isInline ? 28 : 40,
                    height: isInline ? 28 : 40
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - iOS 26 tab accessory wrapper

@available(iOS 26.0, *)
struct IOS26MiniPlayerAccessory: View {

    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    let onOpen: () -> Void

    private var style: MiniPlayerStyle {
        placement == .inline ? .accessoryInline : .accessoryExpanded
    }

    var body: some View {
        MiniPlayerView(style: style, onOpen: onOpen)
    }
}
