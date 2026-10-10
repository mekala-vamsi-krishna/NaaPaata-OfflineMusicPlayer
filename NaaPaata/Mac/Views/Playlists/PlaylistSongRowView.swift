//
//  PlaylistSongRowView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/16/26.
//

import SwiftUI

struct PlaylistSongRowView: View {

    let trackNumber: Int
    let song: Song
    var isCurrentSong: Bool = false
    var isPlaying: Bool = false
    var onSelect: (Song) -> Void = { _ in }
    var onPlayNext: (Song) -> Void = { _ in }
    var onGoToAlbum: (Song) -> Void = { _ in }
    var onRemoveFromPlaylist: (Song) -> Void = { _ in }

    @State private var isHovering = false
    @State private var isShowingInfo = false

    private let contentInset: CGFloat = 24

    var body: some View {
        HStack(spacing: 12) {
            leadingIndicator

            ArtworkView(data: song.artworkData, size: 40, cornerRadius: 6)

            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.body)
                    .foregroundStyle(isCurrentSong ? AppColor.primary : AppColor.textPrimary)
                    .lineLimit(1)

                Text(song.artist)
                    .font(.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 16)

            Text(song.formattedDuration)
                .font(.caption.monospacedDigit())
                .foregroundStyle(AppColor.textSecondary)
                .frame(width: 52, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, contentInset)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(hoverBackground)
                .animation(.easeInOut(duration: 0.15), value: isHovering)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture { onSelect(song) }
        .contextMenu { contextMenu }
        .sheet(isPresented: $isShowingInfo) {
            SongInfoView(song: song)
        }
    }

    // MARK: - Hover background

    private var hoverBackground: Color {
        isHovering ? Color.primary.opacity(0.08) : Color.clear
    }

    // MARK: - Leading indicator

    private var leadingIndicator: some View {
        ZStack {
            numberOrPlayIndicator
                .opacity(isCurrentSong ? 0 : 1)

            EqualizerBars(
                isPlaying: isPlaying && isCurrentSong,
                size: 22,
                barCount: 3,
                color: AppColor.primary
            )
            .opacity(isCurrentSong ? 1 : 0)
            .transaction { $0.animation = nil }
            .allowsHitTesting(false)
        }
        .frame(width: 24, height: 24)
    }

    @ViewBuilder
    private var numberOrPlayIndicator: some View {
        Group {
            if isHovering {
                Image(systemName: "play.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppColor.textPrimary)
                    .transition(.opacity.combined(with: .scale(scale: 0.85)))
            } else {
                Text("\(trackNumber)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(AppColor.textSecondary)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isHovering)
    }

    // MARK: - Context menu

    @ViewBuilder
    private var contextMenu: some View {
        Button {
            onPlayNext(song)
        } label: {
            Label("Play Next", systemImage: "text.line.first.and.arrowtriangle.forward")
        }

        Divider()

        Button {
            onGoToAlbum(song)
        } label: {
            Label("Go to Album", systemImage: "square.stack")
        }

        Button {
            NSWorkspace.shared.activateFileViewerSelecting([song.url])
        } label: {
            Label("Show in Finder", systemImage: "finder")
        }

        Button {
            isShowingInfo = true
        } label: {
            Label("Song Info", systemImage: "info.circle")
        }

        Divider()

        Button(role: .destructive) {
            onRemoveFromPlaylist(song)
        } label: {
            Label("Remove from Playlist", systemImage: "minus.circle")
        }
    }
}
