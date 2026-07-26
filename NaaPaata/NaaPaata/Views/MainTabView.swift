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
    @State private var keyboardHeight: CGFloat = 0
    @Namespace private var playerTransition

    var body: some View {
        GeometryReader { geometry in
            let bottomSafeArea = geometry.safeAreaInsets.bottom

            ZStack(alignment: .bottom) {
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
