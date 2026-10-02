//
//  PlaylistDetailsView.swift
//  NaaPaata
//

import SwiftUI
import SwiftData

struct PlaylistDetailsView: View {

    let playlist: Playlist

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var libraryViewModel: MusicLibraryViewModel
    @EnvironmentObject private var folderService: DocumentFolderService

    @State private var showEditPlaylist = false
    @State private var showDeleteConfirmation = false
    @State private var selectedSongForRemoval: Song?
    @State private var currentSortOption: SortOption = .dateAddedNewest
    @State private var searchText = ""

    // MARK: - Sort

    enum SortOption: String, CaseIterable {
        case dateAddedNewest   = "Date Added (Newest)"
        case dateAddedOldest   = "Date Added (Oldest)"
        case titleAscending    = "Title (A–Z)"
        case titleDescending   = "Title (Z–A)"
        case artistAscending   = "Artist (A–Z)"
        case artistDescending  = "Artist (Z–A)"
        case durationShortest  = "Duration (Shortest)"
        case durationLongest   = "Duration (Longest)"
    }

    // MARK: - Derived data

    private var resolvedSongs: [Song] {
        libraryViewModel.songs(
            forRelativePaths: playlist.songRelativePaths,
            folderService: folderService
        )
    }

    private var sortedSongs: [Song] {
        var songs = resolvedSongs

        switch currentSortOption {
        case .dateAddedNewest:
            songs.sort { $0.dateAdded > $1.dateAdded }
        case .dateAddedOldest:
            songs.sort { $0.dateAdded < $1.dateAdded }
        case .titleAscending:
            songs.sort { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        case .titleDescending:
            songs.sort { $0.title.localizedStandardCompare($1.title) == .orderedDescending }
        case .artistAscending:
            songs.sort { $0.artist.localizedStandardCompare($1.artist) == .orderedAscending }
        case .artistDescending:
            songs.sort { $0.artist.localizedStandardCompare($1.artist) == .orderedDescending }
        case .durationShortest:
            songs.sort { ($0.duration ?? 0) < ($1.duration ?? 0) }
        case .durationLongest:
            songs.sort { ($0.duration ?? 0) > ($1.duration ?? 0) }
        }

        if !searchText.isEmpty {
            songs = songs.filter { song in
                song.title.localizedCaseInsensitiveContains(searchText) ||
                song.artist.localizedCaseInsensitiveContains(searchText)
            }
        }

        return songs
    }

    private var totalDuration: String {
        let total = resolvedSongs.compactMap(\.duration).reduce(0, +)
        let hours = Int(total) / 3600
        let minutes = (Int(total) % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }

    private var service: PlaylistService {
        PlaylistService(context: modelContext)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemBackground).opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    playlistHeader

                    actionButtons
                        .padding(.vertical, 24)

                    searchAndSortBar
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)

                    songsListSection
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showEditPlaylist) {
            EditPlaylistView(playlist: playlist)
        }
        .alert(
            "Remove Song",
            isPresented: Binding(
                get: { selectedSongForRemoval != nil },
                set: { if !$0 { selectedSongForRemoval = nil } }
            ),
            presenting: selectedSongForRemoval
        ) { song in
            Button("Cancel", role: .cancel) { selectedSongForRemoval = nil }
            Button("Remove", role: .destructive) {
                removeFromPlaylist(song)
                selectedSongForRemoval = nil
            }
        } message: { song in
            Text("Are you sure you want to remove '\(song.title)' from this playlist?")
        }
        .alert("Delete Playlist", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                try? service.delete(playlist)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete '\(playlist.name)'? This action cannot be undone.")
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Menu {
                Button {
                    showEditPlaylist = true
                } label: {
                    Label("Edit Playlist", systemImage: "pencil")
                }

                Divider()

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete Playlist", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
        }
    }

    // MARK: - Header

    private var playlistHeader: some View {
        HStack(spacing: 20) {
            coverImage

            VStack(alignment: .leading, spacing: 8) {
                Text(playlist.name)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if !playlist.desc.isEmpty {
                    Text(playlist.desc)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 12) {
                    Label(
                        "\(playlist.songRelativePaths.count) songs",
                        systemImage: "music.note.list"
                    )
                    .font(.system(size: 12, weight: .medium))

                    if !playlist.songRelativePaths.isEmpty {
                        Text("•")
                            .font(.system(size: 12))

                        Label(totalDuration, systemImage: "clock")
                            .font(.system(size: 12, weight: .medium))
                    }
                }
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    @ViewBuilder
    private var coverImage: some View {
        if let data = playlist.coverImageData, let image = UIImage(data: data) {
            ArtworkView(
                    data: playlist.coverImageData,
                    size: 120,
                    cornerRadius: 16
                )
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [Color.accentColor.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .blur(radius: 16)

                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 44))
                            .foregroundStyle(Color.accentColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.white.opacity(0.2), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            }
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        }
    }

    // MARK: - Action buttons

    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button {
                libraryViewModel.playAll(sortedSongs)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 18, weight: .bold))
                    Text("Play All")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(
                    LinearGradient(
                        colors: [
                            Color.accentColor,
                            Color.accentColor.opacity(0.8)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }
            .disabled(playlist.songRelativePaths.isEmpty)
            .opacity(playlist.songRelativePaths.isEmpty ? 0.5 : 1.0)

            Button {
                libraryViewModel.shuffleAll(sortedSongs)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "shuffle")
                        .font(.system(size: 18, weight: .bold))
                    Text("Shuffle")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundStyle(Color.accentColor)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Color.black.opacity(0.1))
                .clipShape(Capsule())
                .overlay(
                    Capsule().strokeBorder(
                        Color.accentColor.opacity(0.3),
                        lineWidth: 1.5
                    )
                )
            }
            .disabled(playlist.songRelativePaths.isEmpty)
            .opacity(playlist.songRelativePaths.isEmpty ? 0.5 : 1.0)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Search & sort

    private var searchAndSortBar: some View {
        VStack(spacing: 12) {
            if !playlist.songRelativePaths.isEmpty {
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)

                        TextField("Search songs…", text: $searchText)
                            .foregroundStyle(.primary)

                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())

                    Menu {
                        Picker("Sort By", selection: $currentSortOption) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.inline)
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }

    // MARK: - Songs list

    private var songsListSection: some View {
        VStack(spacing: 0) {
            if sortedSongs.isEmpty && playlist.songRelativePaths.isEmpty {
                emptyStateView
            } else if sortedSongs.isEmpty && !searchText.isEmpty {
                noSearchResultsView
            } else {
                ForEach(sortedSongs) { song in
                    PlaylistSongRowView(
                        song: song,
                        onPlay: {
                            libraryViewModel.play(song, in: sortedSongs)
                        },
                        onDelete: {
                            selectedSongForRemoval = song
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(.bottom, 85)
    }

    // MARK: - Empty states

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundStyle(.secondary.opacity(0.5))

            Text("No songs yet")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.primary)

            Text("Add songs to start building your playlist")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var noSearchResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.secondary.opacity(0.5))

            Text("No results found")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.primary)

            Text("Try searching with different keywords")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Actions

    private func removeFromPlaylist(_ song: Song) {
        guard let relativePath = folderService.relativePath(for: song.url) else {
            return
        }
        try? service.removeSong(relativePath: relativePath, from: playlist)
    }
}
