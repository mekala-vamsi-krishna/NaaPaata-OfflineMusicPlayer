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
    @StateObject private var progressStore: PlaybackProgressStore

    @StateObject private var tabState = TabState()
    @StateObject private var storeManager = StoreManager()
    @StateObject private var folderService = DocumentFolderService()

    @StateObject private var sleepTimerManager = SleepTimerManager.shared
    @StateObject private var appearanceManager = AppearanceManager.shared
    
    let container: ModelContainer

    init() {
        let container = Self.makeContainer()
        self.container = container

        if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            print("Content Directory Path: \(documentsURL.path)")
        }


        let folderService = DocumentFolderService()
        let playerService = AudioPlayerService()
        let playbackStateService = PlaybackStateService()
        let progress = PlaybackProgressStore()
        
        let playHistoryService = PlayHistoryService(context: container.mainContext)

        guard let folderURL = folderService.naaPaataFolderURL else {
            fatalError("Could not resolve Documents directory.")
        }
        
        let libraryService = MusicLibraryService(rootFolder: folderURL)

        let library = MusicLibraryViewModel(
            libraryService: libraryService,
            playerService: playerService,
            playbackStateService: playbackStateService,
            folderService: folderService,
            playHistoryService: playHistoryService,
            progressStore: progress
        )

        let equalizer = EqualizerViewModel(playerService: playerService)

        AppDelegate.libraryViewModel = library
        AppDelegate.folderService = folderService
        AppDelegate.modelContainer = container

        _libraryViewModel = StateObject(wrappedValue: library)
        _equalizerViewModel = StateObject(wrappedValue: equalizer)
        _folderService = StateObject(wrappedValue: folderService)
        _progressStore = StateObject(wrappedValue: progress)
        
        SleepTimerManager.shared.setup(modelContext: container.mainContext)
        SleepTimerManager.shared.libraryViewModel = library
        
        WidgetCommandHandler.shared.libraryViewModel = library
        WidgetCommandHandler.shared.start()
    }
    
    @StateObject private var appUpdateViewModel: AppUpdateViewModel = {
        let repository = AppUpdateRepository(
            remote: VersionHistoryRemoteDataSource(
                url: AppUpdateConfiguration.remoteVersionHistoryURL
            ),
            local: VersionHistoryLocalDataSource(),
            cache: VersionHistoryCache()
        )
        
        let useCase = CheckForAppUpdateUseCase(
            repository: repository,
            currentVersionProvider: BundleCurrentVersionProvider()
        )
        
        return AppUpdateViewModel(
            useCase: useCase,
            repository: repository,
            dismissedStore: UserDefaultsDismissedVersionsStore(),
            appStoreOpener: DefaultAppStoreOpener(
                appStoreID: AppUpdateConfiguration.appStoreID
            ),
            checkGate: AppUpdateCheckGate()
        )
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(libraryViewModel)
                .environmentObject(equalizerViewModel)
                .environmentObject(tabState)
                .environmentObject(sleepTimerManager)
                .environmentObject(appearanceManager)
                .environmentObject(storeManager)
                .environmentObject(folderService)
                .environmentObject(progressStore)
                .environmentObject(appUpdateViewModel)
            
                .preferredColorScheme(appearanceManager.mode.swiftUIScheme)
                .tint(Color.accentColor)
            
                .task {
                    await libraryViewModel.restoreLastSession()
                }
                
                .task {
                    await appUpdateViewModel.checkForUpdateIfNeeded()
                }
                .sheet(isPresented: $appUpdateViewModel.isSheetPresented) {
                    if case .updateAvailable(let info) = appUpdateViewModel.state {
                        AppUpdateSheet(
                            info: info,
                            onDismiss: { appUpdateViewModel.dismiss() },
                            onUpdate: { appUpdateViewModel.openAppStore() }
                        )
                    }
                }
        }
        .modelContainer(container)
    }

    // MARK: - Container

    private static func makeContainer() -> ModelContainer {
        let schema = Schema([
            Playlist.self,
            FavouriteSong.self,
            SleepTimerModel.self,
            PlayHistoryEntry.self,
        ])
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
