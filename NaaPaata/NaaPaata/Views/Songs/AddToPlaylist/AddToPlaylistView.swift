//
//  AddToPlaylistView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 9/13/25.
//

import SwiftUI

struct AddToPlaylistView: View {
    let song: Song
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var musicManager: MusicPlayerManager
    @EnvironmentObject var playlistsViewModel: PlaylistsViewModel   // ✅ Injected

    @State private var playlists: [Playlist] = []
    @State private var selectedPlaylistIDs: Set<UUID> = []
    @State private var initialSelectedIDs: Set<UUID> = []
    @State private var showCreatePlaylist = false
    @State private var newPlaylistName = ""
    @State private var newPlaylistDescription = ""
    @State private var songArtwork: UIImage?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Header Card
                HStack(spacing: 12) {
                    if let artwork = songArtwork {
                        Image(uiImage: artwork)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 52, height: 52)
                            .cornerRadius(8)
                            .clipped()
                    } else {
                        Image(systemName: "music.note")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .padding(8)
                            .background(AppColors.primary.opacity(0.15))
                            .cornerRadius(8)
                            .foregroundColor(AppColors.primary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Adding to Playlist")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Text(song.title)
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                            .lineLimit(1)
                        Text(song.artist)
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.08))
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)

                // MARK: - Playlist List
                if playlists.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "music.note.list")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(AppColors.primary.opacity(0.6))
                        Text("No Playlists Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                        Text("Tap \"New Playlist\" below to get started")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else {
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
                    .scrollContentBackground(.hidden)
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        AppColors.background,
                        AppColors.background.opacity(0.9),
                        AppColors.primary.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Add to Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        commitSelections()
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.primary)
                }
                ToolbarItem(placement: .bottomBar) {
                    Button(action: { showCreatePlaylist = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text("New Playlist")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(AppColors.primary)
                    }
                }
            }
            .onAppear {
                loadPlaylists()
                loadArtwork()
            }
            .sheet(isPresented: $showCreatePlaylist) {
                CreatePlaylistSheet(
                    name: $newPlaylistName,
                    description: $newPlaylistDescription,
                    onCreate: { coverImage in
                        let trimmedName = newPlaylistName.trimmingCharacters(in: .whitespaces)
                        guard !trimmedName.isEmpty else { return }

                        // Use the view model to create the playlist
                        let existing = playlistsViewModel.getAllPlaylists()
                        var uniqueName = trimmedName
                        var counter = 1
                        while existing.contains(where: { $0.name == uniqueName }) {
                            uniqueName = "\(trimmedName) (\(counter))"
                            counter += 1
                        }

                        let newPlaylist = Playlist(
                            name: uniqueName,
                            coverImage: coverImage,
                            desc: newPlaylistDescription,
                            dateCreated: Date()
                        )
                        
                        playlistsViewModel.updatePlaylist(newPlaylist)
                        
                        if let created = playlistsViewModel.getPlaylist(id: newPlaylist.id) {
                            playlistsViewModel.addSongToPlaylist(song, to: created)
                        }

                        newPlaylistName = ""
                        newPlaylistDescription = ""
                        showCreatePlaylist = false
                        loadPlaylists()
                    }
                )
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Helpers

    private func loadPlaylists() {
        playlists = playlistsViewModel.getAllPlaylists()
        let preSelected = Set(
            playlists
                .filter { $0.songPaths.contains(song.relativePath) }
                .map { $0.id }
        )
        initialSelectedIDs = preSelected
        selectedPlaylistIDs = preSelected
    }

    private func commitSelections() {
        let toAdd = selectedPlaylistIDs.subtracting(initialSelectedIDs)
        let toRemove = initialSelectedIDs.subtracting(selectedPlaylistIDs)

        if !toAdd.isEmpty {
            let results = playlistsViewModel.addSongToPlaylists(song, playlistIDs: toAdd)
            let addedNames = playlists
                .filter { results[$0.id] == .added }
                .map { $0.name }
            if addedNames.count == 1 {
                ToastManager.shared.showToast(message: "Song added to \(addedNames[0]) playlist")
            } else if addedNames.count > 1 {
                ToastManager.shared.showToast(message: "Song added to \(addedNames.count) playlists")
            }
        }

        if !toRemove.isEmpty {
            playlistsViewModel.removeSongFromPlaylists(song, playlistIDs: toRemove)
        }
    }

    private func loadArtwork() {
        Task {
            let image = await musicManager.loadArtworkAsync(for: song)
            await MainActor.run {
                songArtwork = image
            }
        }
    }
}
