//
//  MainTabView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 9/13/25.
//

import SwiftUI

class TabState: ObservableObject {
    @AppStorage("selectedTab") var selectedTab: Int = 0
}

struct MainTabView: View {
    @EnvironmentObject var tabState: TabState
    @EnvironmentObject var musicPlayerManager: MusicPlayerManager
    @EnvironmentObject var playlistsViewModel: PlaylistsViewModel
    @EnvironmentObject var sleepTimerManager: SleepTimerManager

    @State private var showFullPlayer = false
    @Namespace private var playerTransition

    var body: some View {
        GeometryReader { geometry in
            let bottomSafeArea = geometry.safeAreaInsets.bottom

            ZStack(alignment: .bottom) {
                // Main TabView
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
                }
                .accentColor(AppColors.primary)

                if musicPlayerManager.currentSong != nil {
                    if showFullPlayer {
                        // Full Player
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
                        // Mini Player
                        MiniPlayerView(namespace: playerTransition)
                            .environmentObject(musicPlayerManager)
                            .environmentObject(playlistsViewModel)
                            .environmentObject(sleepTimerManager)
                            .padding(.horizontal, 8)
                            .padding(.bottom, bottomSafeArea + 22) 
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
    }
}
