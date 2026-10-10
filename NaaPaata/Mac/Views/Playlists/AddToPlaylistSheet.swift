//
//  AddToPlaylistSheet.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/16/26.
//

import SwiftUI
import SwiftData
import AppKit

struct AddToPlaylistSheet: View {

    let song: Song

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Playlist.createdAt, order: .reverse)
    private var playlists: [Playlist]

    @State private var selectedIDs: Set<PersistentIdentifier> = []
    @State private var didInitialize = false
    @State private var isCreatingNew = false

    private var selectionCount: Int { selectedIDs.count }
    private var canConfirm: Bool { selectionCount > 0 }

    var body: some View {
        VStack(spacing: 0) {
            songHeader
            Divider()

            if playlists.isEmpty {
                emptyState
            } else {
                playlistPicker
            }

            Divider()
            footer
        }
        .frame(width: 440, height: 520)
        .onAppear(perform: initializeSelection)
        .sheet(isPresented: $isCreatingNew) {
            CreatePlaylistSheet(initialSongURLs: [song.url]) { name, description, artworkData, songURLs in
                _ = try? PlaylistService(context: modelContext).createPlaylist(
                    name: name,
                    description: description,
                    artworkData: artworkData,
                    songURLs: songURLs
                )
            }
        }
    }

    // MARK: - Song header

    private var songHeader: some View {
        HStack(spacing: 14) {
            ArtworkView(data: song.artworkData, size: 56, cornerRadius: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.headline)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)

                Text(song.artist)
                    .font(.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)

                Text(song.album)
                    .font(.caption2)
                    .foregroundStyle(AppColor.textTertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - Playlist picker

    private var playlistPicker: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(playlists) { playlist in
                    playlistRow(playlist)
                    if playlist.id != playlists.last?.id {
                        Divider().padding(.leading, 76)
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    private func playlistRow(_ playlist: Playlist) -> some View {
        let isSelected = selectedIDs.contains(playlist.persistentModelID)

        return Button {
            toggle(playlist)
        } label: {
            HStack(spacing: 12) {
                artworkThumbnail(for: playlist)

                VStack(alignment: .leading, spacing: 2) {
                    Text(playlist.name)
                        .font(.body)
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(1)

                    Text(playlist.subtitle)
                        .font(.caption)
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(
                        isSelected ? AppColor.primary : AppColor.textTertiary
                    )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func artworkThumbnail(for playlist: Playlist) -> some View {
        ZStack {
            if let data = playlist.artworkData,
               let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    AppColor.brandGradient
                    Image(systemName: "music.note.list")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.list")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(AppColor.textTertiary)

            Text("No Playlists Yet")
                .font(.headline)
                .foregroundStyle(AppColor.textPrimary)

            Text("Create your first playlist to add this song.")
                .font(.caption)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                isCreatingNew = true
            } label: {
                Label("New Playlist", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(30)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 10) {
            Button {
                isCreatingNew = true
            } label: {
                Label("New Playlist", systemImage: "plus")
            }
            .buttonStyle(.bordered)

            Spacer()

            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)

            Button(addButtonTitle) {
                confirm()
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
            .disabled(!canConfirm)
        }
        .padding(16)
    }

    private var addButtonTitle: String {
        switch selectionCount {
        case 0: return "Add"
        case 1: return "Add to 1 Playlist"
        default: return "Add to \(selectionCount) Playlists"
        }
    }

    // MARK: - Actions

    private func initializeSelection() {
        guard !didInitialize else { return }
        selectedIDs = Set(
            playlists
                .filter { $0.contains(song.url) }
                .map(\.persistentModelID)
        )
        didInitialize = true
    }

    private func toggle(_ playlist: Playlist) {
        let id = playlist.persistentModelID
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    private func confirm() {
        let targets = playlists.filter {
            selectedIDs.contains($0.persistentModelID)
        }
        try? PlaylistService(context: modelContext).addSongs([song.url], to: targets)
        dismiss()
    }
}
