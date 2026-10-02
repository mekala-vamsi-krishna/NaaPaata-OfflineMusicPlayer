//
//  NaaPaataApp.swift
//  NaaPaata
//

import SwiftUI
import SwiftData

@main
struct NaaPaataApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var libraryViewModel: MusicLibraryViewModel
    @StateObject private var equalizerViewModel: EqualizerViewModel

    @StateObject private var tabState = TabState()
    @StateObject private var storeManager = StoreManager()
    @StateObject private var folderService = DocumentFolderService()

    @StateObject private var sleepTimerManager = SleepTimerManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    let container: ModelContainer

    init() {
        let container = Self.makeContainer()
        self.container = container

        let folder = DocumentFolderService()
        let playerService = AudioPlayerService()
        let playbackStateService = PlaybackStateService()

        guard let folderURL = folder.naaPaataFolderURL else {
            fatalError("Could not resolve Documents directory.")
        }

        let libraryService = MusicLibraryService(rootFolder: folderURL)

        let library = MusicLibraryViewModel(
            libraryService: libraryService,
            playerService: playerService,
            playbackStateService: playbackStateService,
            folderService: folder
        )

        let equalizer = EqualizerViewModel(playerService: playerService)

        AppDelegate.libraryViewModel = library
        AppDelegate.folderService = folder
        AppDelegate.modelContainer = container

        _libraryViewModel = StateObject(wrappedValue: library)
        _equalizerViewModel = StateObject(wrappedValue: equalizer)
        _folderService = StateObject(wrappedValue: folder)

        WidgetCommandHandler.shared.libraryViewModel = library
        WidgetCommandHandler.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(libraryViewModel)
                .environmentObject(equalizerViewModel)
                .environmentObject(tabState)
                .environmentObject(sleepTimerManager)
                .environmentObject(themeManager)
                .environmentObject(storeManager)
                .environmentObject(folderService)
                .tint(themeManager.accent)
                .preferredColorScheme(themeManager.colorScheme.swiftUIScheme)
                .task {
                    await libraryViewModel.restoreLastSession()
                }
        }
        .modelContainer(container)
    }

    // MARK: - Container

    private static func makeContainer() -> ModelContainer {
        let schema = Schema([Playlist.self])
        let config = ModelConfiguration("NaaPaata", schema: schema)

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            let storeURL = config.url
            for url in [
                storeURL,
                URL(fileURLWithPath: storeURL.path + "-shm"),
                URL(fileURLWithPath: storeURL.path + "-wal")
            ] {
                try? FileManager.default.removeItem(at: url)
            }

            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Failed to initialize ModelContainer: \(error)")
            }
        }
    }
}
