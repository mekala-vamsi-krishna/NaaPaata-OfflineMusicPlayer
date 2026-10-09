//
//  PlayListsView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 9/13/25.
//

import SwiftUI
import SwiftData

struct PlaylistsView: View {

    @EnvironmentObject private var libraryViewModel: MusicLibraryViewModel
    @EnvironmentObject private var folderService: DocumentFolderService
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Playlist.dateCreated, order: .reverse)
    private var playlists: [Playlist]

    @AppStorage("showSmartPlaylists") private var showSmartPlaylists = true

    @State private var showCreateSheet = false
    @State private var newPlaylistName = ""
    @State private var newPlaylistDescription = ""
    @State private var searchText = ""

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 20)
    ]

    // MARK: - Derived

    private var smartPlaylists: [SmartPlaylist] {
        let service = SmartPlaylistService(
            context: modelContext,
            folderService: folderService
        )
        return service.allSmartPlaylists(from: libraryViewModel.songs)
    }

    private var filteredPlaylists: [Playlist] {
        guard !searchText.isEmpty else { return playlists }
        return playlists.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredSmartPlaylists: [SmartPlaylist] {
        guard !searchText.isEmpty else { return smartPlaylists }
        return smartPlaylists.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {

                if showSmartPlaylists && !filteredSmartPlaylists.isEmpty {
                    smartSection
                }

                userSection
            }
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Playlists")
        .navigationBarTitleDisplayMode(.large)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search playlists"
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Toggle("Show Smart Playlists", isOn: $showSmartPlaylists)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 17, weight: .semibold))
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .semibold))
                }
                .accessibilityLabel("New Playlist")
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreatePlaylistSheet(
                name: $newPlaylistName,
                description: $newPlaylistDescription,
                onCreate: { coverImage in
                    createPlaylist(coverImage: coverImage)
                }
            )
        }
    }

    // MARK: - Smart section

    private var smartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Smart Playlists")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.horizontal, 20)

            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(filteredSmartPlaylists) { smart in
                    NavigationLink(value: SmartPlaylistRoute(kind: smart.kind)) {
                        SmartPlaylistCardView(playlist: smart)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - User section

    private var userSection: some View {
        VStack(alignment: .leading, spacing: 16) {

            Text("My Playlists")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.horizontal, 20)
            

            if filteredPlaylists.isEmpty {
                emptyUserState
            } else {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(filteredPlaylists) { playlist in
                        NavigationLink(value: playlist) {
                            PlaylistCard(playlist: playlist, cardHeight: 150)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                delete(playlist)
                            } label: {
                                Label("Delete Playlist", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private var emptyUserState: some View {
        VStack(spacing: 10) {
            Image(systemName: "music.note.list")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.tertiary)

            Text("No Playlists Yet")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)

            Text("Tap + to create one.")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - Actions

    private func createPlaylist(coverImage: UIImage?) {
        let trimmed = newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let coverData = coverImage?.jpegData(compressionQuality: 0.85)
        let service = PlaylistService(context: modelContext)

        do {
            try service.create(
                name: trimmed,
                description: newPlaylistDescription,
                coverImageData: coverData,
                songRelativePaths: []
            )
            
            newPlaylistName = ""
            newPlaylistDescription = ""
            showCreateSheet = false
            
        } catch {
            print("[PlaylistsView] Failed to create playlist:", error)
        }
    }

    private func delete(_ playlist: Playlist) {
        let service = PlaylistService(context: modelContext)
        try? service.delete(playlist)
    }
}
