//
//  AlbumTrackRowView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/11/26.
//

import SwiftUI
import SwiftData

struct AlbumTrackRowView: View {

    let trackNumber: Int
    let song: Song
    var isCurrentSong: Bool = false
    var isPlaying: Bool = false
    var onSelect: (Song) -> Void = { _ in }
    var onPlayNext: (Song) -> Void = { _ in }
    var onDelete: (Song) -> Void = { _ in }

    @Environment(\.modelContext) private var modelContext

    @State private var isHovering = false
    @State private var isShowingInfo = false
    @State private var isConfirmingDelete = false
    @State private var addToPlaylistMode: AddToPlaylistMode?

    private let contentInset: CGFloat = 24

    var body: some View {
        HStack(spacing: 12) {
            leadingIndicator

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
        .sheet(item: $addToPlaylistMode) { mode in
            switch mode {
            case .new:
                CreatePlaylistSheet(initialSongURLs: [song.url]) { name, description, artworkData, songURLs in
                    _ = try? PlaylistService(context: modelContext).createPlaylist(
                        name: name,
                        description: description,
                        artworkData: artworkData,
                        songURLs: songURLs
                    )
                }
            case .existing:
                AddToPlaylistSheet(song: song)
            }
        }
        .confirmationDialog(
            "Delete “\(song.title)”?",
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    onDelete(song)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The file will be moved to Trash. You can restore it from Finder.")
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
                size: 16,
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

        Menu {
            Button("New Playlist") {
                addToPlaylistMode = .new
            }
            Button("Existing Playlist") {
                addToPlaylistMode = .existing
            }
        } label: {
            Label("Add to Playlist", systemImage: "text.badge.plus")
        }

        Divider()

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
            isConfirmingDelete = true
        } label: {
            Label("Delete Song", systemImage: "trash")
                .foregroundStyle(AppColor.danger)
        }
    }
}
