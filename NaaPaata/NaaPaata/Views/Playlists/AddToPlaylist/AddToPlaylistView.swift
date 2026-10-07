//
//  AddToPlaylistView.swift
//  NaaPaata
//

import SwiftUI
import SwiftData

struct AddToPlaylistView: View {

    let song: Song

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var folderService: DocumentFolderService

    @Query(sort: \Playlist.dateCreated, order: .reverse)
    private var playlists: [Playlist]

    @State private var selectedPlaylistIDs: Set<UUID> = []
    @State private var initialSelectedIDs: Set<UUID> = []
    @State private var showCreatePlaylist = false
    @State private var newPlaylistName = ""
    @State private var newPlaylistDescription = ""

    private var songArtwork: UIImage? {
        guard let data = song.artworkData else { return nil }
        return UIImage(data: data)
    }

    private var relativePath: String? {
        folderService.relativePath(for: song.url)
    }

    private var service: PlaylistService {
        PlaylistService(context: modelContext)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerCard

                if playlists.isEmpty {
                    emptyState
                } else {
                    playlistList
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("Add to Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .onAppear(perform: loadSelection)
            .onChange(of: playlists) { _, _ in loadSelection() }
            .sheet(isPresented: $showCreatePlaylist) {
                CreatePlaylistSheet(
                    name: $newPlaylistName,
                    description: $newPlaylistDescription,
                    onCreate: { coverImage in
                        createPlaylist(coverImage: coverImage)
                    }
                )
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header

    private var headerCard: some View {
        HStack(spacing: 12) {
            if let songArtwork {
                Image(uiImage: songArtwork)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 52, height: 52)
                    .cornerRadius(8)
                    .clipped()
            } else {
                Image(systemName: "music.note")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .padding(13)
                    .background(Color.accentColor.opacity(0.15))
                    .cornerRadius(8)
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Adding to Playlist")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(song.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(song.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.08))
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "music.note.list")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(Color.accentColor.opacity(0.6))
            Text("No Playlists Yet")
                .font(.title2.weight(.semibold))
            Text("Tap \"New Playlist\" below to get started")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }

    // MARK: - List

    private var playlistList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(playlists) { playlist in
                    AddToPlaylistCell(
                        playlist: playlist,
                        isSelected: Binding(
                            get: { selectedPlaylistIDs.contains(playlist.id) },
                            set: { newValue in
                                if newValue {
                                    selectedPlaylistIDs.insert(playlist.id)
                                } else {
                                    selectedPlaylistIDs.remove(playlist.id)
                                }
                            }
                        )
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
        }

        ToolbarItem(placement: .confirmationAction) {
            Button("Done") {
                commitSelections()
                dismiss()
            }
            .font(.system(size: 16, weight: .semibold))
        }

        ToolbarItem(placement: .bottomBar) {
            Button {
                showCreatePlaylist = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("New Playlist")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(Color.accentColor)
            }
        }
    }

    // MARK: - Selection

    private func loadSelection() {
        guard let relativePath else {
            selectedPlaylistIDs = []
            initialSelectedIDs = []
            return
        }

        let preSelected = Set(
            playlists
                .filter { $0.songRelativePaths.contains(relativePath) }
                .map(\.id)
        )
        initialSelectedIDs = preSelected
        selectedPlaylistIDs = preSelected
    }

    private func commitSelections() {
        guard let relativePath else { return }

        let toAdd = selectedPlaylistIDs.subtracting(initialSelectedIDs)
        let toRemove = initialSelectedIDs.subtracting(selectedPlaylistIDs)

        let targets = playlists

        if !toAdd.isEmpty {
            let selected = targets.filter { toAdd.contains($0.id) }
            _ = try? service.addSong(relativePath: relativePath, to: selected)
        }

        if !toRemove.isEmpty {
            let deselected = targets.filter { toRemove.contains($0.id) }
            for playlist in deselected {
                try? service.removeSong(relativePath: relativePath, from: playlist)
            }
        }
    }

    // MARK: - Create

    private func createPlaylist(coverImage: UIImage?) {
        let trimmed = newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let coverData = coverImage?.jpegData(compressionQuality: 0.85)

        // Deduplicate names.
        let existingNames = Set(playlists.map(\.name))
        var uniqueName = trimmed
        var counter = 1
        while existingNames.contains(uniqueName) {
            uniqueName = "\(trimmed) (\(counter))"
            counter += 1
        }

        guard let created = try? service.create(
            name: uniqueName,
            description: newPlaylistDescription,
            coverImageData: coverData,
            songRelativePaths: relativePath.map { [$0] } ?? []
        ) else { return }

        // Ensure the newly created playlist is selected so the user
        // sees it as part of the commit.
        selectedPlaylistIDs.insert(created.id)
        initialSelectedIDs.insert(created.id)

        newPlaylistName = ""
        newPlaylistDescription = ""
        showCreatePlaylist = false
    }
}
