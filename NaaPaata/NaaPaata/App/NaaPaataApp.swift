//
//  NaaPaataApp.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 9/13/25.
//

import SwiftUI
import SwiftData

@main
struct NaaPaataApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @Environment(\.scenePhase) private var scenePhase
    
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    
    @ObservedObject private var tabState = TabState()
    
    @StateObject private var musicPlayerManager = MusicPlayerManager.shared
    @StateObject private var sleepTimerManager = SleepTimerManager.shared
    @StateObject private var themeManager = ThemeManager.shared

    @StateObject private var songsViewModel = SongsViewModel()
    @StateObject private var albumsViewModel = AlbumsViewModel()
    @StateObject private var playlistsViewModel = PlaylistsViewModel()
    @StateObject private var storeKitManager = StoreManager()
    
    // MARK: - SwiftData Container
    let container: ModelContainer
    
    init() {
        // Setup SwiftData with all models
        let config = ModelConfiguration("NaaPaata")
        do {
            container = try ModelContainer(
                for: Song.self,
                Playlist.self,
                SleepTimerModel.self,
                configurations: config
            )
            PlaylistManager.shared.setModelContainer(container)
        } catch {
            // Attempt to recover by deleting corrupted database files
            let storeURL = config.url
            let urlsToRemove = [storeURL, storeURL.appendingPathExtension("shm"), storeURL.appendingPathExtension("wal")]
            for url in urlsToRemove {
                try? FileManager.default.removeItem(at: url)
            }
            do {
                container = try ModelContainer(
                    for: Song.self,
                    Playlist.self,
                    SleepTimerModel.self,
                    configurations: config
                )
                PlaylistManager.shared.setModelContainer(container)
            } catch {
                fatalError("Failed to initialize ModelContainer after reset: \(error)")
            }
        }
    }
    
    // MARK: - Scene
    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    MainTabView()
                        .environmentObject(musicPlayerManager)
                        .environmentObject(playlistsViewModel)
                        .environmentObject(songsViewModel)
                        .environmentObject(albumsViewModel)
                        .environmentObject(tabState)
                        .environmentObject(storeKitManager)
                        .environmentObject(sleepTimerManager)
                        .environmentObject(themeManager)
                        .onAppear {
                            // Set up model contexts for view models
                            songsViewModel.setup(modelContext: container.mainContext)
                            sleepTimerManager.setup(modelContext: container.mainContext)
                            
                            Task {
                                await songsViewModel.loadSongs()
                                albumsViewModel.fetchAlbums(from: songsViewModel.songs)
                            }
                            
                            // Migration: ensure all songs have relativePath
                            Task {
                                let context = container.mainContext
                                let existingSongs = try? context.fetch(FetchDescriptor<Song>())
                                var needsSave = false
                                if let songs = existingSongs {
                                    for song in songs {
                                        if song.relativePath.isEmpty {
                                            if let range = song.urlString.range(of: "Documents/") {
                                                song.relativePath = String(song.urlString[range.upperBound...])
                                            } else {
                                                song.relativePath = URL(string: song.urlString)?.lastPathComponent ?? ""
                                            }
                                            needsSave = true
                                        }
                                    }
                                    if needsSave {
                                        try? context.save()
                                    }
                                }
                            }
                        }
                        .onOpenURL { url in
                            guard url.scheme == "naapaata" else { return }
                            
                            switch url.host {
                            case "playpause":
                                MusicPlayerManager.shared.togglePlayPause()
                            case "next":
                                MusicPlayerManager.shared.playNext()
                            case "previous":
                                MusicPlayerManager.shared.playPrevious()
                            default:
                                print("⚠️ Unknown widget action: \(url.host ?? "nil")")
                            }
                        }
                } else {
                    InstructionView()
                        .environmentObject(musicPlayerManager)
                        .environmentObject(themeManager)
                }
            }
            .withToast()
            .preferredColorScheme(themeManager.colorScheme.swiftUIScheme)
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                musicPlayerManager.saveCurrentPlaybackState()
            case .active:
                musicPlayerManager.restorePlaybackStateWithoutPlaying()
                Task {
                    await storeKitManager.loadProducts()
                    await storeKitManager.updateSubscriptionStatus()
                }
            default:
                break
            }
        }
    }
}

final class PersistenceController {

    static let shared = PersistenceController()

    let container: ModelContainer

    private init() {
        let config = ModelConfiguration("NaaPaata")

        container = try! ModelContainer(
            for: Song.self,
            Playlist.self,
            SleepTimerModel.self,
            configurations: config
        )
    }
}
