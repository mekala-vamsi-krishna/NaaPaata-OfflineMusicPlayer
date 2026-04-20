//
//  NaaPaataApp.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 9/13/25.
//

import SwiftUI
import SwiftData
import GoogleMobileAds

@main
struct NaaPaataApp: App {
    @StateObject var musicPlayerManager = MusicPlayerManager.shared
    @StateObject var playlistsViewModel =  PlaylistsViewModel()
    @StateObject var songsViewModel = SongsViewModel() // Initialize here
    @ObservedObject var tabState = TabState()
    @StateObject private var storeKitManager = StoreManager()
    @StateObject private var sleepTimerManager = SleepTimerManager.shared
    
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    
    let container: ModelContainer
    
    init() {
        MobileAds.shared.start(completionHandler: nil)
        let config = ModelConfiguration()
        do {
            // Initialize SwiftData with Song, Playlist, and SleepTimerModel
            container = try ModelContainer(for: Song.self, Playlist.self, SleepTimerModel.self, configurations: config)
            PlaylistManager.shared.setModelContainer(container)
        } catch {
            print("SwiftData init failed, attempting reset: \(error)")
            let storeURL = config.url
            let urlsToRemove = [storeURL, storeURL.appendingPathExtension("shm"), storeURL.appendingPathExtension("wal")]
            for url in urlsToRemove {
                try? FileManager.default.removeItem(at: url)
            }
            do {
                container = try ModelContainer(for: Song.self, Playlist.self, SleepTimerModel.self, configurations: config)
                PlaylistManager.shared.setModelContainer(container)
            } catch {
                fatalError("Failed to initialize ModelContainer after reset: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
                    .environmentObject(musicPlayerManager)
                    .environmentObject(playlistsViewModel)
                    .environmentObject(songsViewModel) // Inject into environment
                    .environmentObject(tabState)
                    .environmentObject(storeKitManager)
                    .environmentObject(sleepTimerManager)
                    .onAppear {
                        Task {
                            await songsViewModel.loadSongs() // Load songs on app launch
                        }
                        sleepTimerManager.setup(modelContext: container.mainContext)
                    }
            } else {
                OnboardingView()
                    .environmentObject(musicPlayerManager)
            }
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                // Save playback state when app goes to background
                musicPlayerManager.saveCurrentPlaybackState()
            } else if newPhase == .active {
                // Restore playback state when app becomes active
                musicPlayerManager.restoreLastPlaybackState()
                /// whenver app comes on forground after reaminings for long in background fetched the refresh status whether user has taken a subscription plan or not.
                Task {
                    await storeKitManager.loadProducts()
                    await storeKitManager.updateSubscriptionStatus()
                }
             
                
            }
        }
    }
    
    @Environment(\.scenePhase) private var scenePhase
}
