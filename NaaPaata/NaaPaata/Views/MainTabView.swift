//
//  MainTabView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 9/13/25.
//

import SwiftUI

// MARK: - Tab Enum (RawRepresentable for @AppStorage)
enum AppTab: Int, Hashable, CaseIterable {
    case songs = 0
    case albums = 1
    case playlists = 2
    case settings = 3
    case search = 4
}

// MARK: - Tab State with @AppStorage
class TabState: ObservableObject {
    @AppStorage("selectedTab") var selectedTab: AppTab = .songs
}

// MARK: - Main Tab View
struct MainTabView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @EnvironmentObject var tabState: TabState
    @EnvironmentObject var musicPlayerManager: MusicPlayerManager
    @EnvironmentObject var playlistsViewModel: PlaylistsViewModel
    @EnvironmentObject var sleepTimerManager: SleepTimerManager

    @StateObject private var searchViewModel = SearchViewModel()

    @State private var showFullPlayer = false
    @State private var playerDismissalProgress: CGFloat = 0

    private var playerAnimation: Animation {
        reduceMotion
            ? .easeInOut(duration: 0.2)
            : .spring(response: 0.44, dampingFraction: 0.88, blendDuration: 0.08)
    }

    var body: some View {
        ZStack {
            adaptiveTabView
                .accessibilityHidden(showFullPlayer && playerDismissalProgress == 0)

            if musicPlayerManager.currentSong != nil {
                if showFullPlayer {
                    MusicPlayerView(
                        dismissAction: dismissPlayer,
                        onDismissalProgressChanged: { progress in
                            playerDismissalProgress = progress
                        }
                    )
                    .environmentObject(musicPlayerManager)
                    .environmentObject(playlistsViewModel)
                    .environmentObject(sleepTimerManager)
                    .transition(.move(edge: .bottom))
                    .zIndex(10)
                } else if #available(iOS 26.0, *) {
                    EmptyView()
                }
            }
        }
        .onReceive(musicPlayerManager.$currentSong) { song in
            guard song == nil, showFullPlayer else { return }
            showFullPlayer = false
        }
    }

    @ViewBuilder
    private var adaptiveTabView: some View {
        if #available(iOS 26.0, *) {
            tabs
                .tabViewBottomAccessory {
                    if musicPlayerManager.currentSong != nil {
                        IOS26MiniPlayerAccessory(onOpen: presentPlayer)
                            .opacity(showFullPlayer ? max(playerDismissalProgress, 0.001) : 1)
                            .allowsHitTesting(!showFullPlayer)
                            .accessibilityHidden(showFullPlayer)
                    }
                }
                .tabBarMinimizeBehavior(.onScrollDown)
        } else {
            ZStack(alignment: .bottom) {
                tabs

                if musicPlayerManager.currentSong != nil {
                    MiniPlayerView(
                        style: .legacy,
                        onOpen: presentPlayer
                    )
                    .padding(.horizontal, 8)
                    .padding(.bottom, 58)
                    .opacity(showFullPlayer ? max(playerDismissalProgress, 0.001) : 1)
                    .allowsHitTesting(!showFullPlayer)
                    .accessibilityHidden(showFullPlayer)
                    .zIndex(1)
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }

    private var tabs: some View {
        TabView(selection: $tabState.selectedTab) {
            Tab("Songs", systemImage: "music.quarternote.3", value: .songs) {
                SongsView()
            }

            Tab("Albums", systemImage: "rectangle.stack.badge.play", value: .albums) {
                AlbumsView()
            }

            Tab("Lists", systemImage: "music.note.list", value: .playlists) {
                PlayListsView()
            }

            Tab("Settings", systemImage: "gear", value: .settings) {
                SettingsView()
            }

            Tab("Search", systemImage: "magnifyingglass", value: .search, role: .search) {
                SearchView()
                    .environmentObject(searchViewModel)
            }
        }
        .tint(AppColors.primary)
    }

    private func presentPlayer() {
        guard musicPlayerManager.currentSong != nil else { return }
        playerDismissalProgress = 0
        HapticManager.shared.light()
        withAnimation(playerAnimation) {
            showFullPlayer = true
        }
    }

    private func dismissPlayer() {
        withAnimation(playerAnimation) {
            showFullPlayer = false
        } completion: {
            playerDismissalProgress = 0
        }
    }
}
