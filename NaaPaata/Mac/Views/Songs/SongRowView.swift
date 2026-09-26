//
//  SongRowView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/11/26.
//

import SwiftUI
import SwiftData

struct SongRowView: View {

    let song: Song
    var isCurrentSong: Bool = false
    var isPlaying: Bool = false
    var isFavourite: Bool = false
    var onSelect: (Song) -> Void = { _ in }
    var onDelete: (Song) -> Void = { _ in }
    var onPlayNext: (Song) -> Void = { _ in }
    var onGoToAlbum: (Song) -> Void = { _ in }

    @Environment(\.modelContext) private var modelContext

    @State private var isShowingInfo = false
    @State private var isConfirmingDelete = false
    @State private var addToPlaylistMode: AddToPlaylistMode?
    @State private var isHovering = false
    
    /// Horizontal inset applied inside the row so content lines up with the
    /// Songs header, while the hover background spans the full row width.
    private let contentInset: CGFloat = 16

    var body: some View {
        HStack(spacing: 12) {
            artworkWithHoverOverlay

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(song.title)
                        .font(.body)
                        .foregroundStyle(isCurrentSong ? AppColor.primary : AppColor.textPrimary)
                        .lineLimit(1)

                    if isFavourite {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(AppColor.primary)
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                Text(song.artist)
                    .font(.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isFavourite)

            Spacer(minLength: 16)

            Text(song.album)
                .font(.caption)
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(1)
                .frame(maxWidth: 220, alignment: .trailing)

            Text(song.formattedDuration)
                .font(.caption.monospacedDigit())
                .foregroundStyle(AppColor.textSecondary)
                .frame(width: 52, alignment: .trailing)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, contentInset)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            hoverBackground,
            in: RoundedRectangle(cornerRadius: 6, style: .continuous)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
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

    // MARK: - Artwork with hover overlay

    private var artworkWithHoverOverlay: some View {
        ZStack {
            if isCurrentSong {
                EqualizerBars(
                    isPlaying: isPlaying,
                    size: 36,
                    color: AppColor.primary
                )
                .padding(.horizontal, 6)
                .transition(.opacity)
            } else {
                ArtworkView(data: song.artworkData, size: 36, cornerRadius: 5)
                    .overlay {
                        if isHovering {
                            ZStack {
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(.black.opacity(0.45))

                                Image(systemName: "play.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .transition(.opacity)
                        }
                    }
                    .animation(.easeInOut(duration: 0.15), value: isHovering)
            }
        }
        .frame(width: 48, height: 36)
    }

    // MARK: - Context menu

    @ViewBuilder
    private var contextMenu: some View {
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
            isConfirmingDelete = true
        } label: {
            Label("Delete", systemImage: "trash")
                .foregroundStyle(AppColor.danger)
        }
    }
}

// MARK: - Add-to-playlist mode

enum AddToPlaylistMode: String, Identifiable {
    case new, existing
    var id: String { rawValue }
}
