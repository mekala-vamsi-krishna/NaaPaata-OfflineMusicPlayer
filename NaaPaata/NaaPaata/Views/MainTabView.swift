//
//  MainTabView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 9/13/25.
//

import SwiftUI

// MARK: - Tab Enum
enum AppTab: Int, Hashable, CaseIterable {
    case songs, albums, playlists, settings, search
}

// MARK: - Tab State
final class TabState: ObservableObject {
    @AppStorage("selectedTab") var selectedTab: AppTab = .songs
}

// MARK: - Main Tab View
struct MainTabView: View {
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @EnvironmentObject var tabState: TabState
    @EnvironmentObject var libraryViewModel: MusicLibraryViewModel
    @EnvironmentObject var sleepTimerManager: SleepTimerManager
    
    @StateObject private var songsRouter = AppRouter()
    @StateObject private var albumsRouter = AppRouter()
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
                    IOS26MiniPlayerAccessory(
                        onOpen: presentPlayer
                    )
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

            Tab("Songs", systemImage: "music.quarternote.3", value: .songs) {
                NavigationStack(path: $songsRouter.path) {
                    SongsView()
                        .navigationDestination(for: Album.self) { album in
                            AlbumDetailView(album: album)
                        }
                }
                .environmentObject(songsRouter)
            }

            Tab("Albums", systemImage: "rectangle.stack.badge.play", value: .albums) {
                NavigationStack(path: $albumsRouter.path) {
                    AlbumsView()
                        .navigationDestination(for: Album.self) { album in
                            AlbumDetailView(album: album)
                        }
                }
                .environmentObject(albumsRouter)
            }

            Tab("Lists", systemImage: "music.note.list", value: .playlists) {
                NavigationStack(path: $playlistsRouter.path) {
                    PlayListsView()
                        .navigationDestination(for: Album.self) { album in
                            AlbumDetailView(album: album)
                        }
                }
                .environmentObject(playlistsRouter)
            }

            Tab("Settings", systemImage: "gear", value: .settings) {
                NavigationStack {
                    SettingsView()
                }
            }

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
