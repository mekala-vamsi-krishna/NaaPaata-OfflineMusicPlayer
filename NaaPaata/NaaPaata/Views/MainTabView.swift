//
//  MainTabView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 9/13/25.
//

import SwiftUI

// MARK: - Tab Enum
enum AppTab: String, Hashable, CaseIterable {
    case home = "Home"
    case playlists = "Playlists"
    case settings = "Settings"
    case search = "Search"

    var symbol: String {
        switch self {
        case .home:      return "house"
        case .playlists: return "music.note.list"
        case .settings:  return "gearshape.fill"
        case .search:    return "magnifyingglass"
        }
    }

    @ViewBuilder
    var tabLabel: some View {
        Label(self.rawValue, systemImage: self.symbol)
    }
}

// MARK: - Tab State
final class TabState: ObservableObject {
    @AppStorage("selectedTab") var selectedTab: AppTab = .home
}

// MARK: - Main Tab View
struct MainTabView: View {

    @EnvironmentObject var tabState: TabState
    @EnvironmentObject var libraryViewModel: MusicLibraryViewModel
    @EnvironmentObject var sleepTimerManager: SleepTimerManager
    @EnvironmentObject private var progressStore: PlaybackProgressStore
    @EnvironmentObject private var folderService: DocumentFolderService

    @StateObject private var homeRouter = AppRouter()
    @StateObject private var playlistsRouter = AppRouter()
    @StateObject private var searchRouter = AppRouter()

    @State private var config = PlayerContainerConfig()

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            tabs
                .overlay(alignment: .topLeading, content: {
                    if config.attachExpandedPlayer {
                        PlayerContainer(config: $config)
                            .environmentObject(libraryViewModel)
                            .environmentObject(sleepTimerManager)
                            .environmentObject(progressStore)
                            .environmentObject(folderService)
                            .transition(.identity)
                    }
                })
                .tabViewBottomAccessory(isEnabled: !config.attachExpandedPlayer) {
                    PlayerContainer(config: $config)
                        .environmentObject(libraryViewModel)
                        .environmentObject(sleepTimerManager)
                        .environmentObject(progressStore)
                        .environmentObject(folderService)
                }
                .tabBarMinimizeBehavior(.onScrollDown)
        }
    }

    // MARK: - Tabs

    private var tabs: some View {
        TabView(selection: $tabState.selectedTab) {

            Tab(value: .home) {
                NavigationStack(path: $homeRouter.path) {
                    HomeView()
                        .navigationDestination(for: LibraryRoute.self) { route in
                            libraryDestination(for: route)
                        }
                        .navigationDestination(for: Album.self) { album in
                            AlbumDetailView(album: album)
                        }
                        .navigationDestination(for: Artist.self) { artist in
                            ArtistDetailView(artist: artist, viewModel: libraryViewModel)
                        }
                        .navigationDestination(for: Genre.self) { genre in
                            GenreDetailView(genre: genre, viewModel: libraryViewModel)
                        }
                        .navigationDestination(for: SmartPlaylistRoute.self) { route in
                            SmartPlaylistDetailView(kind: route.kind, viewModel: libraryViewModel)
                        }
                        .navigationDestination(for: Playlist.self) { playlist in
                            PlaylistDetailsView(playlist: playlist)
                        }
                }
                .environmentObject(homeRouter)
            } label: {
                AppTab.home.tabLabel
            }

            Tab(value: .playlists) {
                NavigationStack(path: $playlistsRouter.path) {
                    PlaylistsView()
                        .navigationDestination(for: Playlist.self) { playlist in
                            PlaylistDetailsView(playlist: playlist)
                        }
                        .navigationDestination(for: SmartPlaylistRoute.self) { route in
                            SmartPlaylistDetailView(kind: route.kind, viewModel: libraryViewModel)
                        }
                        .navigationDestination(for: Album.self) { album in
                            AlbumDetailView(album: album)
                        }
                }
                .environmentObject(playlistsRouter)
            } label: {
                AppTab.playlists.tabLabel
            }

            Tab(value: .settings) {
                NavigationStack {
                    SettingsView()
                }
            } label: {
                AppTab.settings.tabLabel
            }

            Tab(value: .search, role: .search) {
                NavigationStack(path: $searchRouter.path) {
                    SearchView()
                        .navigationDestination(for: Album.self) { album in
                            AlbumDetailView(album: album)
                        }
                }
                .environmentObject(searchRouter)
            } label: {
                AppTab.search.tabLabel
            }
        }
    }

    // MARK: - Library Destinations

    @ViewBuilder
    private func libraryDestination(for route: LibraryRoute) -> some View {
        switch route {
        case .songs:      SongsView()
        case .albums:     AlbumsView()
        case .artists:    ArtistsView(viewModel: libraryViewModel)
        case .genres:     GenresView()
        case .favourites: FavouritesView()
        }
    }
}
