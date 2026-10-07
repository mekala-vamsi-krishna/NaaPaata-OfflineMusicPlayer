//
//  MainTabView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 9/13/25.
//

import SwiftUI

// MARK: - Tab Enum
enum AppTab: Int, Hashable, CaseIterable {
    case home, playlists, settings, search
}

// MARK: - Tab State
final class TabState: ObservableObject {
    @AppStorage("selectedTab") var selectedTab: AppTab = .home
}

// MARK: - Main Tab View
struct MainTabView: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @EnvironmentObject var tabState: TabState
    @EnvironmentObject var libraryViewModel: MusicLibraryViewModel
    @EnvironmentObject var sleepTimerManager: SleepTimerManager

    @StateObject private var homeRouter = AppRouter()
    @StateObject private var playlistsRouter = AppRouter()
    @StateObject private var searchRouter = AppRouter()

    @State private var showFullPlayer = false
    @State private var playerDismissalProgress: CGFloat = 0

    @StateObject private var uiState = UIState()

    private var playerAnimation: Animation {
        reduceMotion
        ? .easeInOut(duration: 0.2)
        : .spring(response: 0.44, dampingFraction: 0.88, blendDuration: 0.08)
    }

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            adaptiveTabView
                .accessibilityHidden(showFullPlayer)

            if libraryViewModel.currentSong != nil {
                if showFullPlayer {
                    MusicPlayerView(
                        dismissAction: dismissPlayer,
                        onDismissalProgressChanged: { progress in
                            playerDismissalProgress = progress
                        }
                    )
                    .environmentObject(libraryViewModel)
                    .environmentObject(sleepTimerManager)
                    .zIndex(10)
                }
            }
        }
        .environmentObject(uiState)
        .onReceive(libraryViewModel.$currentSong) { song in
            guard song == nil, showFullPlayer else { return }
            withAnimation(playerAnimation) {
                showFullPlayer = false
            }
        }
    }

    // MARK: - Adaptive tab layout

    @ViewBuilder
    private var adaptiveTabView: some View {
        if #available(iOS 26.0, *) {
            tabs
                .tabViewBottomAccessory {
                    IOS26MiniPlayerAccessory(onOpen: presentPlayer)
                        .accessibilityHidden(showFullPlayer)
                }
                .tabBarMinimizeBehavior(.onScrollDown)
        } else {
            ZStack(alignment: .bottom) {
                tabs

                MiniPlayerView(
                    style: .legacy,
                    onOpen: presentPlayer
                )
                .padding(.horizontal, 8)
                .padding(.bottom, 58)
                .accessibilityHidden(showFullPlayer)
                .zIndex(1)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }

    private var tabs: some View {
        TabView(selection: $tabState.selectedTab) {

            // MARK: Home
            Tab("Home", systemImage: "house.fill", value: .home) {
                NavigationStack(path: $homeRouter.path) {
                    HomeView()
                        .navigationDestination(for: LibraryRoute.self) { route in
                            libraryDestination(for: route)
                        }
                        .navigationDestination(for: Album.self) { album in
                            AlbumDetailView(album: album)
                        }
                        .navigationDestination(for: Artist.self) { artist in
                            ArtistDetailView(
                                artist: artist,
                                viewModel: libraryViewModel
                            )
                        }
                }
                .environmentObject(homeRouter)
            }

            // MARK: Playlists
            Tab("Playlists", systemImage: "music.note.list", value: .playlists) {
                NavigationStack(path: $playlistsRouter.path) {
                    PlayListsView()
                        .navigationDestination(for: Album.self) { album in
                            AlbumDetailView(album: album)
                        }
                }
                .environmentObject(playlistsRouter)
            }

            // MARK: Settings
            Tab("Settings", systemImage: "gearshape.fill", value: .settings) {
                NavigationStack {
                    SettingsView()
                }
            }

            // MARK: Search
            Tab("Search", systemImage: "magnifyingglass", value: .search, role: .search) {
                NavigationStack(path: $searchRouter.path) {
                    SearchView()
                        .navigationDestination(for: Album.self) { album in
                            AlbumDetailView(album: album)
                        }
                }
                .environmentObject(searchRouter)
            }
        }
    }

    // MARK: - Library destinations

    @ViewBuilder
    private func libraryDestination(for route: LibraryRoute) -> some View {
        switch route {
        case .songs:
            SongsView()
        case .albums:
            AlbumsView()
        case .artists:
            ArtistsView(viewModel: libraryViewModel)
        case .genres:
            placeholderView(title: "Genres", symbol: "guitars")
        case .favourites:
            placeholderView(title: "Favourites", symbol: "heart.fill")
        }
    }

    private func placeholderView(title: String, symbol: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.tertiary)
            Text("\(title) — coming soon")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Presentation

    private func presentPlayer() {
        guard libraryViewModel.currentSong != nil else { return }
        HapticManager.shared.light()
        withAnimation(playerAnimation) {
            showFullPlayer = true
        }
    }

    private func dismissPlayer() {
        withAnimation(playerAnimation) {
            showFullPlayer = false
        }
    }
}
