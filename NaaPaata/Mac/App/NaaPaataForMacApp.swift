//
//  Naa_Paata_for_MacApp.swift
//  Naa Paata for Mac
//
//  Created by Mekala Vamsi Krishna on 9/11/26.
//

import SwiftUI
import SwiftData

@main
struct NaaPaataForMacApp: App {

    @StateObject private var libraryViewModel: MusicLibraryViewModel
    @StateObject private var appearanceService = AppearanceService()

    private let container: ModelContainer

    init() {
        UserDefaults.standard.register(defaults: [
            "NSWindowAssertWhenDisplayCycleLimitReached": false
        ])

        // Shared SwiftData container.
        let schema = Schema([
            Playlist.self,
            FavouriteSong.self,
            PlayHistoryEntry.self,
            PlaySession.self
        ])
        let configuration = ModelConfiguration(schema: schema)
        let container = try! ModelContainer(
            for: schema,
            configurations: [configuration]
        )
        self.container = container

        Task { @MainActor in
            PlayHistoryStore.shared.configure(with: container)
            PlaySessionStore.shared.configure(with: container)
        }

        let folderService = MusicFolderService()
        let libraryService = MusicLibraryService(folderService: folderService)
        let playerService = AudioPlayerService()
        let playbackStateService = PlaybackStateService()

        _libraryViewModel = StateObject(
            wrappedValue: MusicLibraryViewModel(
                libraryService: libraryService,
                playerService: playerService,
                playbackStateService: playbackStateService
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            HomeView(viewModel: libraryViewModel)
                .musicKeyboardShortcuts(for: libraryViewModel)
                .tint(AppColor.primary)
                .background(WindowConfigurator())
                .task {
                    // Re-open the notch panel if the user had it enabled.
                    if UserDefaults.standard.bool(forKey: "showNotchMedia") {
                        NotchWindowController.shared.show(viewModel: libraryViewModel)
                    }
                }
        }
        .modelContainer(container)
        .windowResizability(.contentSize)
        .windowToolbarStyle(.unified)
        .commands {
            ControlsMenu(viewModel: libraryViewModel)
            SongMenu(viewModel: libraryViewModel)
        }
        
        Window("Mini Player", id: WindowID.miniPlayer) {
            MiniPlayerView(viewModel: libraryViewModel)
        }
        .modelContainer(container)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 380, height: 380)
        .defaultPosition(.topTrailing)

        Settings {
            AppSettingsView(viewModel: libraryViewModel)
                .environmentObject(appearanceService)
        }
    }
}
