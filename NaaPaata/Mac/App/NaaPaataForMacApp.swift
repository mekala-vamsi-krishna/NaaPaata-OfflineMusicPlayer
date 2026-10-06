//
//  Naa_Paata_for_MacApp.swift
//  Naa Paata for Mac
//
//  Created by Mekala Vamsi Krishna on 9/11/26.
//

import SwiftUI
import SwiftData
import AVFoundation
import Combine

@main
struct NaaPaataForMacApp: App {

    @StateObject private var libraryViewModel: MusicLibraryViewModel
    @StateObject private var appearanceService = AppearanceService()
    @StateObject private var playerService: AudioPlayerService
    @StateObject private var store = StoreManager()
    
    @State private var equalizerEngine = EqualizerEngine()
    @State private var equalizerViewModel = EqualizerViewModel()

    private let container: ModelContainer

    init() {
        UserDefaults.standard.register(defaults: [
            "NSWindowAssertWhenDisplayCycleLimitReached": false
        ])

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
        let player = AudioPlayerService()
        let playbackStateService = PlaybackStateService()

        _libraryViewModel = StateObject(
            wrappedValue: MusicLibraryViewModel(
                libraryService: libraryService,
                playerService: player,
                playbackStateService: playbackStateService
            )
        )
        _playerService = StateObject(wrappedValue: player)
    }

    var body: some Scene {

        WindowGroup {
            HomeView(viewModel: libraryViewModel)
                .musicKeyboardShortcuts(for: libraryViewModel)
                .tint(AppColor.primary)
                .background(WindowConfigurator())
                .environmentObject(equalizerViewModel)
                .environmentObject(equalizerEngine)
                .environmentObject(store)
        }
        .modelContainer(container)
        .windowResizability(.contentSize)
        .windowToolbarStyle(.unified)
        .commands {
            ControlsMenu(viewModel: libraryViewModel)
            SongMenu(viewModel: libraryViewModel)

            CommandGroup(before: .windowList) {
                Button("Mini Player") {
                    WindowCoordinator.shared.showMiniPlayer(
                        libraryViewModel: libraryViewModel
                    )
                }
                .keyboardShortcut("0", modifiers: [.command, .shift])

                Button("Equalizer") {
                    WindowCoordinator.shared.showEqualizer(
                        equalizerViewModel: equalizerViewModel,
                        engine: equalizerEngine,
                        playerService: playerService,
                        store: store
                    )
                }
                .keyboardShortcut("e", modifiers: .command)

                Divider()
            }
        }

        Settings {
            AppSettingsView(viewModel: libraryViewModel)
                .environmentObject(appearanceService)
                .environmentObject(store)
        }
    }
}
