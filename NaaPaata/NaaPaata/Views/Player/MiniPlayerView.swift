//
//  MiniPlayerView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 9/21/25.
//

import SwiftUI

enum MiniPlayerStyle {
    case accessoryExpanded
    case accessoryInline
    case legacy
}

struct MiniPlayerView: View {
    @EnvironmentObject private var musicPlayerManager: MusicPlayerManager

    let style: MiniPlayerStyle
    let onOpen: () -> Void

    private var isInline: Bool {
        style == .accessoryInline
    }

    private var artworkSize: CGFloat {
        isInline ? 26 : 38
    }

    var body: some View {
        HStack(spacing: isInline ? 6 : 12) {
            Button(action: onOpen) {
                HStack(spacing: isInline ? 6 : 12) {
                    artwork
                    songInformation
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open Now Playing")

            playbackButton(
                systemName: musicPlayerManager.isPlaying ? "pause.fill" : "play.fill",
                size: isInline ? 13 : 18,
                accessibilityLabel: musicPlayerManager.isPlaying ? "Pause" : "Play"
            ) {
                HapticManager.shared.light()
                musicPlayerManager.togglePlayPause()
            }

            if !isInline {
                playbackButton(
                    systemName: "forward.fill",
                    size: 16,
                    accessibilityLabel: "Next Track"
                ) {
                    HapticManager.shared.light()
                    musicPlayerManager.playNext()
                }
            }
        }
        .padding(.horizontal, isInline ? 4 : 12)
        .frame(maxWidth: .infinity)
        .frame(height: isInline ? 38 : 64)
        .background(background)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: "Open Now Playing", onOpen)
    }

    @ViewBuilder
    private var artwork: some View {
        if let artwork = musicPlayerManager.artworkImage {
            Image(uiImage: artwork)
                .resizable()
                .scaledToFill()
                .frame(width: artworkSize, height: artworkSize)
                .clipShape(RoundedRectangle(cornerRadius: isInline ? 5 : 8, style: .continuous))
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

    @ViewBuilder
    private var songInformation: some View {
        if isInline {
            Text(musicPlayerManager.currentSong?.title ?? "Unknown Title")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .allowsTightening(true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel(
                    "\(musicPlayerManager.currentSong?.title ?? "Unknown Title"), \(musicPlayerManager.currentSong?.artist ?? "Unknown Artist")"
                )
        } else {
            VStack(alignment: .leading, spacing: 2) {
                Text(musicPlayerManager.currentSong?.title ?? "Unknown Title")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(musicPlayerManager.currentSong?.artist ?? "Unknown Artist")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder
    private var background: some View {
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
                .frame(width: isInline ? 28 : 40, height: isInline ? 28 : 40)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

@available(iOS 26.0, *)
struct IOS26MiniPlayerAccessory: View {
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    let onOpen: () -> Void

    private var style: MiniPlayerStyle {
        placement == .inline ? .accessoryInline : .accessoryExpanded
    }

    var body: some View {
        MiniPlayerView(
            style: style,
            onOpen: onOpen
        )
    }
}
