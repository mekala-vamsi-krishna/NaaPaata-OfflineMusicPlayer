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
    @StateObject private var musicPlayerManager = MusicPlayerManager.shared
    @StateObject private var playlistsViewModel = PlaylistsViewModel()
    @StateObject private var sleepTimerManager = SleepTimerManager.shared

    @State private var showFullPlayer = false
    @Namespace private var animation

    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        GeometryReader { geometry in
            let layout = AdaptiveLayout(
                horizontalSizeClass: sizeClass,
                screenWidth: geometry.size.width
            )

            ZStack {
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

                    EqualizerView()
                        .tabItem {
                            Image(systemName: "slider.horizontal.3")
                            Text("Equalizer")
                        }
                        .tag(3)
                }
                .accentColor(AppColors.primary)

                // Mini Player
                VStack {
                    Spacer()
                    if musicPlayerManager.currentSong != nil && !showFullPlayer {
                        MiniPlayerView(namespace: animation)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    showFullPlayer = true
                                }
                            }
                            .padding(.horizontal, layout.miniPlayerHorizontalPadding)
                            .padding(.bottom, layout.miniPlayerBottomPadding)
                    }
                }

                // Full Player Overlay
                if showFullPlayer {
                    MusicPlayerView(
                        dismissAction: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                showFullPlayer = false
                            }
                        },
                        namespace: animation
                    )
                    .environmentObject(musicPlayerManager)
                    .environmentObject(playlistsViewModel)
                    .environmentObject(sleepTimerManager)
                    .transition(.identity)
                    .zIndex(1)
                }
            }
        }
    }
}
