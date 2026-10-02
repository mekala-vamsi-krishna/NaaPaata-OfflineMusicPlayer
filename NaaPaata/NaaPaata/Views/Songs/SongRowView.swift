//
//  MP3FileCell.swift
//  NaaPaata
//

import SwiftUI
import UIKit

struct SongRowView: View {

    let song: Song
    var isCurrentSong: Bool = false

    @EnvironmentObject private var libraryViewModel: MusicLibraryViewModel
    @EnvironmentObject private var router: AppRouter

    @State private var showSongInfoSheet = false
    @State private var showAddToPlaylistSheet = false
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var showDeleteAlert = false

    var body: some View {
        HStack(spacing: 12) {

            ArtworkView(data: song.artworkData, size: 48, cornerRadius: 6)

            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.body)
                    .foregroundStyle(isCurrentSong ? Color.accentColor : .primary)
                    .lineLimit(1)

                Text(song.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            if isCurrentSong {
                EqualizerBars(
                    isPlaying: libraryViewModel.isPlaying,
                    size: 18,
                    barCount: 3,
                    color: .accentColor
                )
            }

            Text(song.formattedDuration)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)

            ellipsisMenu
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .sheet(isPresented: $showSongInfoSheet) {
            NavigationStack {
                SongInfoView(song: song)
            }
            .presentationDetents([.fraction(0.7)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showAddToPlaylistSheet) {
            AddToPlaylistView(song: song)
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityViewController(activityItems: shareItems)
                .presentationDetents([.fraction(0.4)])
        }
        .alert("Delete Song?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                libraryViewModel.deleteSong(song)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \"\(song.title)\" from your device?")
        }
    }

    // MARK: - Menu

    private var ellipsisMenu: some View {
        Menu {
            Button {
                libraryViewModel.enqueueNext(song)
            } label: {
                Label("Play Next", systemImage: "text.insert")
            }

            Button {
                showSongInfoSheet = true
            } label: {
                Label("Info", systemImage: "info.circle")
            }

            Button {
                goToAlbum()
            } label: {
                Label("Go to Album", systemImage: "square.stack")
            }

            Button {
                shareItems = [song.url]
                showShareSheet = true
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }

            Divider()

            Button {
                showAddToPlaylistSheet = true
            } label: {
                Label("Add to Playlist", systemImage: "music.note.list")
            }

            Divider()

            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .rotationEffect(.degrees(90))
                .font(.system(size: 18))
                .foregroundStyle(.primary)
                .padding(10)
                .contentShape(Rectangle())
        }
    }

    // MARK: - Actions

    private func goToAlbum() {
        guard let album = libraryViewModel.albums.first(where: {
            $0.title == song.album
        }) else { return }

        router.push(album)
    }
}
