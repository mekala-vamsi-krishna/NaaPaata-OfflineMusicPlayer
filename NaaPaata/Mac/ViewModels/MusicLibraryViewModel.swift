//
//  MusicLibraryViewModel.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/11/26.
//

import Foundation
import Combine
import AppKit
import SwiftData

enum RepeatMode: String, CaseIterable, Codable {
    case off, all, one

    var systemImage: String {
        switch self {
        case .off, .all: return "repeat"
        case .one: return "repeat.1"
        }
    }
}

@MainActor
final class MusicLibraryViewModel: ObservableObject {

    // MARK: - Published Properties (Library)
    @Published private(set) var songs: [Song] = []
    @Published private(set) var albums: [Album] = []
    @Published private(set) var artists: [Artist] = []
    @Published private(set) var genres: [Genre] = []
    @Published private(set) var librarySizeBytes: Int64 = 0
    
    // MARK: - Published Properties (Playback)
    @Published private(set) var currentSong: Song?
    @Published private(set) var isPlaying = false
    @Published private(set) var progress: Double = 0
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var isShuffled = false
    @Published private(set) var repeatMode: RepeatMode = .off
    
    // MARK: - Published Properties (UI State)
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var requiresFolderSelection: Bool = false
    
    @Published private(set) var focusedSong: Song?
    @Published var pendingIntent: SongIntent?

    // MARK: - Dependencies
    private let libraryService: MusicLibraryServiceProtocol
    private let playerService: AudioPlayerServiceProtocol
    private let playbackStateService: PlaybackStateServiceProtocol
    private let folderService = MusicFolderService()

    // MARK: - Security Scope
    /// Must be held for the lifetime of the app to allow AVPlayer to read files.
    private var securityScopedURL: URL?

    // MARK: - Playback State
    private var queue: [Song] = []
    private var originalQueue: [Song] = []
    private var currentIndex: Int?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - State Management
    private var didRestoreState = false
    private var lastStateSaveDate: Date = .distantPast
    private let stateSaveInterval: TimeInterval = 5
    private var lastElapsedTick: TimeInterval = 0

    // MARK: - Computed Properties
    var libraryFolderURL: URL? { securityScopedURL }
    var targetSong: Song? { focusedSong ?? currentSong }
    
    var formattedLibrarySize: String {
        guard librarySizeBytes > 0 else { return "—" }
        return ByteCountFormatter.string(fromByteCount: librarySizeBytes, countStyle: .file)
    }

    var formattedAverageFileSize: String {
        guard !songs.isEmpty, librarySizeBytes > 0 else { return "—" }
        let average = librarySizeBytes / Int64(songs.count)
        return ByteCountFormatter.string(fromByteCount: average, countStyle: .file)
    }

    // MARK: - Initialization

    init(
        libraryService: MusicLibraryServiceProtocol,
        playerService: AudioPlayerServiceProtocol,
        playbackStateService: PlaybackStateServiceProtocol
    ) {
        self.libraryService = libraryService
        self.playerService = playerService
        self.playbackStateService = playbackStateService
        
        // 1. Initialize security scope and check for valid folder
        if let url = libraryService.libraryFolderURL {
            let started = url.startAccessingSecurityScopedResource()
            
            if started && FileManager.default.fileExists(atPath: url.path) {
                self.securityScopedURL = url
                loadCacheFromDisk()
            } else {
                // Folder was deleted or bookmark is stale
                url.stopAccessingSecurityScopedResource()
                folderService.clearBookmark()
                LibraryCacheManager.shared.clearCache()
                self.requiresFolderSelection = true
            }
        } else {
            self.requiresFolderSelection = true
        }
        
        bindPlayer()
        observeAppTermination()
    }
    
    deinit {
        // Properly release the security scope when the view model is destroyed
        securityScopedURL?.stopAccessingSecurityScopedResource()
    }

    // MARK: - Setup & Folder Selection

    func selectFolder() async {
        // We use the async version of NSOpenPanel inside MusicFolderService
        guard let newURL = await folderService.promptForFolderSelection() else { return }
        
        // Release the old folder
        securityScopedURL?.stopAccessingSecurityScopedResource()
        
        // Start accessing the new folder and hold the scope open
        let started = newURL.startAccessingSecurityScopedResource()
        
        if started {
            self.securityScopedURL = newURL
            self.requiresFolderSelection = false
            await loadLibrary()
        } else {
            self.errorMessage = "Could not access the selected folder. Please try a different one."
        }
    }

    // MARK: - Library Management

    func loadLibrary() async {
        if songs.isEmpty { isLoading = true }
        defer { isLoading = false }

        do {
            let fetchedSongs = try await libraryService.loadLibrary()
            self.songs = fetchedSongs
            self.albums = Self.groupAlbums(from: fetchedSongs)
            self.artists = Self.groupArtists(from: fetchedSongs)
            self.genres = Self.groupGenres(from: fetchedSongs)
            
            LibraryCacheManager.shared.save(fetchedSongs)
            await refreshLibrarySize()
            
            requiresFolderSelection = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.requiresFolderSelection = true
        }
    }

    func refresh() async {
        await loadLibrary()
    }
    
    func deleteSong(_ song: Song, in context: ModelContext) {
        do {
            try libraryService.delete(song)
            songs.removeAll { $0.id == song.id }
            albums = Self.groupAlbums(from: songs)
            artists = Self.groupArtists(from: songs)
            self.genres = Self.groupGenres(from: songs)

            originalQueue.removeAll { $0.id == song.id }
            queue.removeAll { $0.id == song.id }

            try? FavouritesService(context: context).removeFavourite(song.url)

            if currentSong?.id == song.id {
                playerService.pause()
                currentSong = nil
                queue = []
                originalQueue = []
                currentIndex = nil
            } else if let idx = currentIndex {
                currentIndex = min(idx, max(queue.count - 1, 0))
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func revealLibraryFolder() {
        guard let url = securityScopedURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    // MARK: - Lookup Helpers
    func album(for song: Song) -> Album? { albums.first { $0.title == song.album } }
    func artist(for song: Song) -> Artist? { artists.first { $0.name == song.artist } }
    func genre(for song: Song) -> Genre? { genres.first { $0.name == song.genre } }

    // MARK: - Playback Controls

    func playAll(_ songs: [Song]) {
        guard let first = songs.first else { return }
        isShuffled = false
        repeatMode = .all
        originalQueue = songs
        queue = songs
        currentIndex = 0
        startPlayback(of: first)
    }

    func shuffleAll(_ songs: [Song]) {
        guard !songs.isEmpty else { return }
        let shuffled = songs.shuffled()
        isShuffled = true
        repeatMode = .all
        originalQueue = songs
        queue = shuffled
        currentIndex = 0
        startPlayback(of: shuffled[0])
    }

    func play(_ song: Song, in songs: [Song]) {
        guard !songs.isEmpty else { return }
        originalQueue = songs

        if isShuffled {
            let others = songs.filter { $0.id != song.id }.shuffled()
            queue = [song] + others
            currentIndex = 0
        } else {
            queue = songs
            currentIndex = songs.firstIndex(where: { $0.id == song.id }) ?? 0
        }

        repeatMode = .all
        startPlayback(of: song)
    }

    func togglePlayPause() {
        guard currentSong != nil else { return }

        if isPlaying {
            playerService.pause()
            PlaySessionStore.shared.endCurrentSession()
        } else {
            playerService.play()
            if let song = currentSong {
                PlaySessionStore.shared.beginSession(songPath: song.url.path)
            }
        }
        savePlaybackState()
    }

    func playNext() {
        guard currentIndex != nil, !queue.isEmpty else { return }
        if repeatMode == .one {
            playerService.seek(toProgress: 0)
            return
        }
        advanceToNext()
        savePlaybackState()
    }

    func playPrevious() {
        guard currentIndex != nil, !queue.isEmpty else { return }
        if repeatMode == .one {
            playerService.seek(toProgress: 0)
            return
        }
        goToPrevious()
    }

    func seek(toProgress progress: Double) {
        playerService.seek(toProgress: progress)
        savePlaybackState()
    }

    func enqueueNext(_ song: Song) {
        guard let currentIndex else {
            play(song, in: [song])
            return
        }
        guard queue[currentIndex].id != song.id else { return }

        var adjustedIndex = currentIndex
        if let existing = queue.firstIndex(where: { $0.id == song.id }) {
            queue.remove(at: existing)
            if existing < currentIndex { adjustedIndex -= 1 }
        }

        let insertAt = min(adjustedIndex + 1, queue.count)
        queue.insert(song, at: insertAt)
        self.currentIndex = adjustedIndex
    }

    func toggleShuffle() {
        isShuffled.toggle()
        guard let current = currentSong, let idx = currentIndex else { return }

        if isShuffled {
            let played = Array(queue[0...idx])
            let upcoming = idx + 1 < queue.count ? Array(queue[(idx + 1)...]).shuffled() : []
            queue = played + upcoming
        } else {
            queue = originalQueue
            currentIndex = queue.firstIndex(where: { $0.id == current.id })
        }
        savePlaybackState()
    }

    func cycleRepeatMode() {
        switch repeatMode {
        case .off: repeatMode = .all
        case .all: repeatMode = .one
        case .one: repeatMode = .off
        }
        applyRepeatMode()
        savePlaybackState()
    }
    
    func setRepeatMode(_ mode: RepeatMode) {
        guard repeatMode != mode else { return }
        repeatMode = mode
        applyRepeatMode()
        savePlaybackState()
    }
    
    func clearPendingIntent() { pendingIntent = nil }
    func focus(_ song: Song) { focusedSong = song }

    // MARK: - Private Playback Logic

    private func startPlayback(of song: Song) {
        // Verify we still have folder access before trying to play
        guard securityScopedURL != nil else {
            errorMessage = "Lost access to the folder. Please choose the folder again."
            requiresFolderSelection = true
            return
        }

        currentSong = song
        focusedSong = song
        lastElapsedTick = 0

        PlaySessionStore.shared.beginSession(songPath: song.url.path)

        do {
            try playerService.load(url: song.url)
            applyRepeatMode()
            playerService.play()
        } catch {
            if FileManager.default.fileExists(atPath: song.url.path) {
                errorMessage = "Could not play \"\(song.title)\". The file may be corrupted."
            } else {
                errorMessage = "The file \"\(song.title)\" no longer exists on your disk."
            }
        }
        
        PlayHistoryStore.shared.recordPlay(song.url)
        savePlaybackState()
    }

    private func advanceToNext() {
        guard let idx = currentIndex else { return }
        let nextIdx = idx + 1

        if nextIdx < queue.count {
            currentIndex = nextIdx
            startPlayback(of: queue[nextIdx])
            return
        }

        guard repeatMode == .all else {
            playerService.pause()
            return
        }

        if isShuffled {
            reshuffleAndRestart()
        } else {
            currentIndex = 0
            startPlayback(of: queue[0])
        }
    }

    private func goToPrevious() {
        guard let idx = currentIndex else { return }
        let prevIdx = idx - 1

        if prevIdx >= 0 {
            currentIndex = prevIdx
            startPlayback(of: queue[prevIdx])
        } else if let current = currentSong {
            startPlayback(of: current)
        }
    }

    private func reshuffleAndRestart() {
        var reshuffled = originalQueue.shuffled()

        if reshuffled.count > 1, let last = currentSong, reshuffled.first?.id == last.id {
            reshuffled.swapAt(0, 1)
        }

        queue = reshuffled
        currentIndex = 0
        if let first = reshuffled.first {
            startPlayback(of: first)
        }
    }

    private func applyRepeatMode() {
        playerService.setLooping(repeatMode == .one)
    }

    private func handleTrackDidFinish() {
        switch repeatMode {
        case .one:
            if let current = currentSong { startPlayback(of: current) }
        case .all, .off:
            advanceToNext()
        }
    }

    // MARK: - State Management & Restoration

    func restorePlaybackState() async {
        guard !didRestoreState else { return }
        didRestoreState = true
        
        // 1. If we don't have a valid folder, abort.
        guard securityScopedURL != nil else {
            requiresFolderSelection = true
            return
        }
        
        // 2. Silent background sync to catch external changes
        Task { await loadLibrary() }
        
        // 3. Load saved state
        guard let state = playbackStateService.load(),
              let currentPath = state.currentSongPath,
              let song = songs.first(where: { $0.url.standardizedFileURL.path == URL(fileURLWithPath: currentPath).standardizedFileURL.path }),
              FileManager.default.fileExists(atPath: song.url.path) // Ensure file actually exists
        else {
            return
        }
        
        let restoredQueue = state.queuePaths.compactMap { path in
            songs.first { $0.url.standardizedFileURL.path == URL(fileURLWithPath: path).standardizedFileURL.path }
        }
        
        let restoredOriginalQueue = state.originalQueuePaths.compactMap { path in
            songs.first { $0.url.standardizedFileURL.path == URL(fileURLWithPath: path).standardizedFileURL.path }
        }
        
        self.queue = restoredQueue.isEmpty ? songs : restoredQueue
        self.originalQueue = restoredOriginalQueue.isEmpty ? self.queue : restoredOriginalQueue
        self.currentIndex = state.currentIndex
        self.isShuffled = state.isShuffled
        self.repeatMode = RepeatMode(rawValue: state.repeatMode) ?? .off
        self.currentSong = song
        
        do {
            try playerService.load(url: song.url)
            playerService.setLooping(repeatMode == .one)
            playerService.seek(toTime: state.elapsed)
        } catch {
            print("⚠️ Failed to restore last song: \(error.localizedDescription)")
            self.currentSong = nil
            return
        }
        
        self.elapsed = state.elapsed
        self.progress = (song.duration ?? 0) > 0 ? state.elapsed / (song.duration ?? 1) : 0
    }
    
    private func savePlaybackState() {
        let state = PlaybackState(
            currentSongPath: currentSong?.url.path,
            elapsed: elapsed,
            queuePaths: queue.map(\.url.path),
            originalQueuePaths: originalQueue.map(\.url.path),
            currentIndex: currentIndex,
            isShuffled: isShuffled,
            repeatMode: repeatMode.rawValue,
            savedAt: Date()
        )
        playbackStateService.save(state)
        lastStateSaveDate = Date()
    }

    private func observeAppTermination() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.savePlaybackState()
            }
        }
    }

    // MARK: - Player Bindings

    private func bindPlayer() {
        playerService.isPlayingPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.isPlaying = $0 }
            .store(in: &cancellables)

        playerService.progressPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newProgress in
                guard let self else { return }
                self.progress = newProgress
                
                let now = Date()
                guard now.timeIntervalSince(self.lastStateSaveDate) >= self.stateSaveInterval, self.isPlaying else { return }
                self.savePlaybackState()
            }
            .store(in: &cancellables)

        playerService.elapsedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newElapsed in
                guard let self else { return }
                let delta = newElapsed - self.lastElapsedTick
                if delta > 0, delta < 2 {
                    PlaySessionStore.shared.addDuration(delta)
                }
                self.lastElapsedTick = newElapsed
                self.elapsed = newElapsed
            }
            .store(in: &cancellables)

        playerService.trackDidFinishPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handleTrackDidFinish() }
            .store(in: &cancellables)
    }

    // MARK: - Helpers

    private func loadCacheFromDisk() {
        if let cachedSongs = LibraryCacheManager.shared.load() {
            self.songs = cachedSongs
            self.albums = Self.groupAlbums(from: cachedSongs)
            self.artists = Self.groupArtists(from: cachedSongs)
            self.genres = Self.groupGenres(from: cachedSongs)
            self.isLoading = false
        }
    }

    private func refreshLibrarySize() async {
        let currentSongs = self.songs
        let total: Int64 = await Task.detached(priority: .utility) {
            currentSongs.reduce(into: Int64(0)) { sum, song in
                let values = try? song.url.resourceValues(forKeys: [.fileSizeKey])
                sum += Int64(values?.fileSize ?? 0)
            }
        }.value
        self.librarySizeBytes = total
    }

    private static func groupAlbums(from songs: [Song]) -> [Album] {
        Dictionary(grouping: songs, by: { $0.album })
            .map { key, value in
                Album(id: key, title: key, artist: value.first?.artist ?? "Unknown Artist", songs: value.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending })
            }
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }
    
    private static func groupArtists(from songs: [Song]) -> [Artist] {
        Dictionary(grouping: songs, by: { $0.artist })
            .map { key, value in
                Artist(id: key, name: key, songs: value.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending })
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
    
    private static func groupGenres(from songs: [Song]) -> [Genre] {
        Dictionary(grouping: songs, by: { $0.genre })
            .map { key, value in
                Genre(id: key, name: key, songs: value.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending })
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}
