//
//  NaaPaataApp.swift
//  NaaPaata
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
    @StateObject private var storeKitManager = StoreManager()

    // MARK: - Dependencies
    let container: ModelContainer
    let dataService: DataServiceProtocol
    let libraryService: SongLibraryService
    let songsViewModel: SongsViewModel
    let albumsViewModel: AlbumsViewModel
    let playlistsViewModel: PlaylistsViewModel

    init() {
        let config = ModelConfiguration("NaaPaata")
        let containerResult: Result<ModelContainer, Error>

        do {
            let container = try ModelContainer(
                for: Song.self,
                Playlist.self,
                SleepTimerModel.self,
                configurations: config
            )
            containerResult = .success(container)
        } catch {
            let storeURL = config.url
            let urlsToRemove = [
                storeURL,
                storeURL.appendingPathExtension("shm"),
                storeURL.appendingPathExtension("wal")
            ]
            for url in urlsToRemove {
                try? FileManager.default.removeItem(at: url)
            }
            do {
                let container = try ModelContainer(
                    for: Song.self,
                    Playlist.self,
                    SleepTimerModel.self,
                    configurations: config
                )
                containerResult = .success(container)
            } catch {
                fatalError("Failed to initialize ModelContainer after reset: \(error)")
            }
        }

        guard case .success(let container) = containerResult else {
            fatalError("ModelContainer is not available")
        }
        self.container = container
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path {
            print("===> Documents directory:\n\(documentsPath)")
        }
        // Instantiate services and view models
        let context = container.mainContext
        self.dataService = DataService(modelContext: context)
        self.libraryService = SongLibraryService(dataService: dataService)
        self.songsViewModel = SongsViewModel(libraryService: libraryService, dataService: dataService)
        self.albumsViewModel = AlbumsViewModel()
        self.playlistsViewModel = PlaylistsViewModel(dataService: dataService)

        AppDelegate.dataService = dataService
        AppDelegate.songLibraryService = libraryService
        AppDelegate.songsViewModel = songsViewModel
        AppDelegate.albumsViewModel = albumsViewModel
        AppDelegate.playlistsViewModel = playlistsViewModel
    }

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
                            sleepTimerManager.setup(modelContext: container.mainContext)

                            Task {
                                await songsViewModel.loadSongs()
                                albumsViewModel.fetchAlbums(from: songsViewModel.songs)
                                playlistsViewModel.loadPlaylists()
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
                    OnboardingView()
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
