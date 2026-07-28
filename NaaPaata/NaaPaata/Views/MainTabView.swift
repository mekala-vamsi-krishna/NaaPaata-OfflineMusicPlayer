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
    @EnvironmentObject var tabState: TabState
    @EnvironmentObject var musicPlayerManager: MusicPlayerManager
    @EnvironmentObject var playlistsViewModel: PlaylistsViewModel
    @EnvironmentObject var sleepTimerManager: SleepTimerManager

    @StateObject private var searchViewModel = SearchViewModel()

    @State private var showFullPlayer = false
    @State private var keyboardHeight: CGFloat = 0
    @Namespace private var playerTransition

    var body: some View {
        GeometryReader { geometry in
            let bottomSafeArea = geometry.safeAreaInsets.bottom

            ZStack(alignment: .bottom) {
                // MARK: - Main TabView (iOS 18+)
                if #available(iOS 18.0, *) {
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
                    .accentColor(AppColors.primary)
                } else {
                    TabView(selection: $tabState.selectedTab) {
                        SongsView()
                            .tabItem {
                                Image(systemName: "music.quarternote.3")
                                Text("Songs")
                            }
                            .tag(0)
                        AlbumsView()
                            .tabItem {
                                Image(systemName: "rectangle.stack.badge.play")
                                Text("Albums")
                            }
                            .tag(1)
                        PlayListsView()
                            .tabItem {
                                Image(systemName: "music.note.list")
                                Text("Lists")
                            }
                            .tag(2)
                        SettingsView()
                            .tabItem {
                                Image(systemName: "gear")
                                Text("Settings")
                            }
                            .tag(3)
                        SearchView()
                            .environmentObject(searchViewModel)
                            .tabItem {
                                Image(systemName: "magnifyingglass")
                                Text("Search")
                            }
                            .tag(4)
                    }
                    .accentColor(AppColors.primary)
                }

                // MARK: - Mini Player / Full Player
                if musicPlayerManager.currentSong != nil {
                    if showFullPlayer {
                        MusicPlayerView(
                            dismissAction: {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                                    showFullPlayer = false
                                }
                            },
                            namespace: playerTransition
                        )
                        .environmentObject(musicPlayerManager)
                        .environmentObject(playlistsViewModel)
                        .environmentObject(sleepTimerManager)
                        .transition(.opacity)
                        .zIndex(1)
                    } else {
                        MiniPlayerView(namespace: playerTransition)
                            .environmentObject(musicPlayerManager)
                            .environmentObject(playlistsViewModel)
                            .environmentObject(sleepTimerManager)
                            .padding(.horizontal, 8)
                            .padding(.bottom, keyboardHeight > 0 ? max(0, keyboardHeight - bottomSafeArea) + 4 : bottomSafeArea + 16)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                                    showFullPlayer = true
                                }
                            }
                            .zIndex(1)
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                if musicPlayerManager.currentSong != nil && !showFullPlayer {
                    keyboardHeight = keyboardFrame.height
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
    }
}
