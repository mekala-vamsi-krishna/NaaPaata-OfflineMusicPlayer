//
//  MP3FileCell.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 9/13/25.
//

import SwiftUI
import AVFoundation

struct MP3FileCell: View {
    let song: Song
    @EnvironmentObject var musicManager: MusicPlayerManager
    @EnvironmentObject var albumsViewModel: AlbumsViewModel

    @State private var showSongInfoSheet = false
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var showDeleteAlert = false
    @State private var showAddToPlaylist = false
    @State private var artwork: UIImage?
    @State private var navigateToAlbum = false
    @State private var albumForNavigation: (title: String, artwork: UIImage?, songs: [Song])?

    // Create Playlist
    @State private var newPlaylistName = ""
    @State private var newPlaylistDescription = ""

    var body: some View {
        HStack(spacing: 15) {
            // Artwork
            if let artwork = artwork {
                Image(uiImage: artwork)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .background(AppColors.background.opacity(0.2))
                    .cornerRadius(8)
            } else {
                Image(systemName: "music.note")
                    .resizable()
                    .scaledToFit()
                    .padding(10)
                    .frame(width: 50, height: 50)
                    .background(AppColors.background.opacity(0.2))
                    .cornerRadius(8)
                    .foregroundColor(AppColors.primary)
                    .task {
                        self.artwork = await musicManager.loadArtworkAsync(for: song)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)

                Text(song.artist)
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            if musicManager.currentSong == song {
                EqualizerBars(isPlaying: musicManager.isPlaying)
                    .frame(width: 20, height: 20)
            }

            Menu {
                Button {
                    musicManager.addToQueueNext(song)
                } label: {
                    Label("Play Next", systemImage: "text.insert")
                }

                Button {
                    showSongInfoSheet = true
                } label: {
                    Label("Info", systemImage: "info.circle")
                }

                Button {
                    let matched = albumsViewModel.albums.first(where: { $0.name == song.album })
                    albumForNavigation = (
                        title: matched?.name ?? song.album,
                        artwork: matched?.artworkImage ?? song.artworkImage,
                        songs: matched?.songs ?? [song]
                    )
                    navigateToAlbum = true
                } label: {
                    Label("Go to Album", systemImage: "square.stack")
                }

                Button {
                    if let shareURL = song.resolvedURL ?? song.url {
                        shareItems = [shareURL]
                        showShareSheet = true
                    }
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }

                Divider()

                Button {
                    showAddToPlaylist = true
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
                    .foregroundColor(.gray)
                    .padding(10)
                    .contentShape(Rectangle())
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showAddToPlaylist) {
            AddToPlaylistView(song: song)
                .environmentObject(musicManager)
        }
        .sheet(isPresented: $showSongInfoSheet) {
            NavigationStack {
                SongInfoView(song: song)
            }
            .presentationDetents([.fraction(0.7)])
            .presentationDragIndicator(.visible)
        }
        .navigationDestination(isPresented: $navigateToAlbum) {
            if let album = albumForNavigation {
                AlbumDetailsView(title: album.title, artwork: album.artwork, songs: album.songs)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityViewController(activityItems: shareItems)
                .presentationDetents([.fraction(0.4)])
        }
        .alert("Delete Song?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                musicManager.delete(song: song)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \"\(song.title)\" from your device?")
        }
    }
}

// EqualizerBars remains unchanged
struct EqualizerBars: View {
    @State private var heights: [CGFloat] = [5, 10, 7]
    @Environment(\.scenePhase) private var scenePhase
    @State private var isAnimating = false
    
    let isPlaying: Bool
    private let timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<heights.count, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.purple)
                    .frame(width: 3, height: heights[i])
            }
        }
        .onReceive(timer) { _ in
            guard isPlaying else { return }
            withAnimation(.linear(duration: 0.25)) {
                heights = heights.map { _ in CGFloat(Int.random(in: 5...15)) }
            }
        }
        .onChange(of: isPlaying) { newValue in
            if !newValue {
                withAnimation(.easeOut(duration: 0.3)) {
                    heights = [5, 5, 5]
                }
            }
        }
    }
}

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
                // MARK: - Header Card (Song being added) with Artwork
                HStack(spacing: 12) {
                    // Artwork
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
                .background(AppColors.cardBackground)
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)

                // MARK: - Playlist List (Custom ScrollView)
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
                                PlaylistCell(
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
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        commitSelections()
                        dismiss()
                    }
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

                        let currentPlaylists = PlaylistManager.shared.getAllPlaylists()
                        var uniqueName = trimmedName
                        var counter = 1
                        while currentPlaylists.contains(where: { $0.name == uniqueName }) {
                            uniqueName = "\(trimmedName) (\(counter))"
                            counter += 1
                        }

                        let newPlaylist = Playlist(
                            name: uniqueName,
                            coverImage: coverImage,
                            desc: newPlaylistDescription,
                            dateCreated: Date()
                        )
                        PlaylistManager.shared.savePlaylist(newPlaylist)

                        if let created = PlaylistManager.shared.loadPlaylist(name: uniqueName) {
                            let _ = PlaylistManager.shared.addSongToPlaylist(song, playlist: created)
                            ToastManager.shared.showToast(message: "Song added to \(created.name) playlist")
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

    private func loadPlaylists() {
        playlists = PlaylistManager.shared.getAllPlaylists()
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

        // Batch add — single context, single save
        if !toAdd.isEmpty {
            let results = PlaylistManager.shared.addSongToPlaylists(song, playlistIDs: toAdd)
            let addedNames = playlists
                .filter { results[$0.id] == .added }
                .map { $0.name }
            if addedNames.count == 1 {
                ToastManager.shared.showToast(message: "Song added to \(addedNames[0]) playlist")
            } else if addedNames.count > 1 {
                ToastManager.shared.showToast(message: "Song added to \(addedNames.count) playlists")
            }
        }

        // Batch remove — single context, single save
        if !toRemove.isEmpty {
            PlaylistManager.shared.removeSongFromPlaylists(song, playlistIDs: toRemove)
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

// MARK: - Custom Playlist Cell
struct PlaylistCell: View {
    let playlist: Playlist
    @Binding var isSelected: Bool

    var body: some View {
        HStack {
            // Cover
            if let cover = playlist.coverImage {
                Image(uiImage: cover)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .cornerRadius(8)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.primary.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "music.note.list")
                            .font(.title3)
                            .foregroundColor(AppColors.primary)
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(playlist.name)
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                Text("\(playlist.songPaths.count) songs")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.leading, 4)

            Spacer()

            // Selection button
            Button {
                isSelected.toggle()
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            } label: {
                ZStack {
                    Circle()
                        .stroke(AppColors.primary, lineWidth: 2)
                        .frame(width: 28, height: 28)
                    if isSelected {
                        Circle()
                            .fill(AppColors.primary)
                            .frame(width: 28, height: 28)
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.cardBackground)
                .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1)
        )
    }
}
