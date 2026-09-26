//
//  FolderSetupView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/11/26.
//
//
//  FolderSetupView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/11/26.
//

import SwiftUI
import SwiftData

struct HomeView: View {

    // Song Menu Properties
    @Environment(\.modelContext) private var modelContext

    @State private var infoSong: Song?
    @State private var addToPlaylistSong: Song?
    @State private var addToPlaylistMode: AddToPlaylistMode?
    @State private var confirmDeleteSong: Song?

    @ObservedObject var viewModel: MusicLibraryViewModel

    @StateObject private var router = AppRouter()

    @State private var selection: SidebarItem? = .songs
    @State private var showPlayer = true
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
        } detail: {
            content
        }
        .inspector(isPresented: $showPlayer) {
            MusicPlayerView(
                viewModel: viewModel,
                showPlayer: $showPlayer
            )
            .inspectorColumnWidth(min: 320, ideal: 320, max: 320)
        }
        .navigationSplitViewStyle(.balanced)
        .toolbarBackground(.hidden, for: .windowToolbar)

        .onChange(of: selection) { _, _ in
            router.popToRoot()
        }

        // Handle intents from the menu bar
        .onChange(of: viewModel.pendingIntent) { _, intent in
            guard let intent else { return }
            Task { @MainActor in
                handleIntent(intent)
                viewModel.clearPendingIntent()
            }
        }

        // Info sheet
        .sheet(item: $infoSong) { song in
            SongInfoView(song: song)
        }

        // Add to Playlist sheet
        .sheet(item: $addToPlaylistSong) { song in
            switch addToPlaylistMode {
            case .new:
                CreatePlaylistSheet(initialSongURLs: [song.url]) { name, description, artworkData, songURLs in
                    _ = try? PlaylistService(context: modelContext).createPlaylist(
                        name: name,
                        description: description,
                        artworkData: artworkData,
                        songURLs: songURLs
                    )
                }
            case .existing, .none:
                AddToPlaylistSheet(song: song)
            }
        }

        // Delete confirmation
        .confirmationDialog(
            "Delete “\(confirmDeleteSong?.title ?? "")”?",
            isPresented: Binding(
                get: { confirmDeleteSong != nil },
                set: { if !$0 { confirmDeleteSong = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let song = confirmDeleteSong {
                    viewModel.deleteSong(song, in: modelContext)
                }
                confirmDeleteSong = nil
            }
            Button("Cancel", role: .cancel) {
                confirmDeleteSong = nil
            }
        } message: {
            Text("The file will be moved to Trash. You can restore it from Finder.")
        }

        .task {
            await viewModel.restoreLastSession()
        }

        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            ),
            actions: { Button("OK", role: .cancel) {} },
            message: { Text(viewModel.errorMessage ?? "") }
        )
    }

    // MARK: - Intent handling

    private func handleIntent(_ intent: SongIntent) {
        switch intent {
        case .showInfo(let song):
            infoSong = song

        case .addToNewPlaylist(let song):
            addToPlaylistSong = song
            addToPlaylistMode = .new

        case .addToExistingPlaylist(let song):
            addToPlaylistSong = song
            addToPlaylistMode = .existing

        case .goToAlbum(let song):
            if let album = viewModel.album(for: song) {
                router.push(album)
            }

        case .delete(let song):
            confirmDeleteSong = song
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(SidebarItem.allCases, selection: $selection) { item in
            Label(item.title, systemImage: item.systemImage)
                .tag(item)
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 180, ideal: 210, max: 260)
        .safeAreaInset(edge: .bottom) {
            sidebarFooter
        }
    }

    private var sidebarFooter: some View {
        VStack(spacing: 0) {

            Divider()

            HStack(spacing: 12) {

                // App icon
                if let icon = NSApp.applicationIconImage {
                    Image(nsImage: icon)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 44, height: 44)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(
                                    Color.primary.opacity(0.08),
                                    lineWidth: 0.5
                                )
                        )
                        .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                }

                // Name + tagline
                VStack(alignment: .leading, spacing: 1) {
                    Text("Naa Paata")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text("Your Sound. Your World")
                        .font(.system(size: 9, weight: .regular))
                        .foregroundStyle(AppColor.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
    }

    // MARK: - Center Content

    @ViewBuilder
    private var content: some View {
        NavigationStack(path: $router.path) {
            Group {
                switch selection ?? .songs {
                case .search:
                    SearchView(viewModel: viewModel)

                case .songs:
                    SongsView(viewModel: viewModel)

                case .favourites:
                    FavouritesView(viewModel: viewModel)

                case .albums:
                    AlbumsView(viewModel: viewModel)

                case .artists:
                    ArtistsView(viewModel: viewModel)
                    
                case .genres:
                    GenresView(viewModel: viewModel)
                    
                case .playlists:
                    PlaylistsView(viewModel: viewModel)
                }
            }
            .navigationDestination(for: Album.self) { album in
                AlbumDetailView(album: album, viewModel: viewModel)
            }
            .navigationDestination(for: Artist.self) { artist in
                ArtistDetailView(
                    artist: artist,
                    viewModel: viewModel,
                    router: router
                )
            }
            .navigationDestination(for: Genre.self) { genre in
                GenreDetailView(
                    genre: genre,
                    viewModel: viewModel,
                    router: router
                )
            }
            .navigationDestination(for: Playlist.self) { playlist in
                PlaylistDetailView(
                    playlist: playlist,
                    viewModel: viewModel,
                    router: router
                )
            }
            .navigationDestination(for: SmartPlaylistRoute.self) { route in
                SmartPlaylistDetailView(
                    kind: route.kind,
                    viewModel: viewModel
                )
            }
        }
        .environmentObject(router)
    }
}
