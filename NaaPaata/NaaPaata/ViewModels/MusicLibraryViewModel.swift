//
//  MusicLibraryViewModel.swift
//  NaaPaata
//

import Combine
import Foundation
import MediaPlayer
import UIKit
import WidgetKit
import SwiftData

@MainActor
class MusicLibraryViewModel: ObservableObject {

    // MARK: - Library
    @Published private(set) var songs: [Song] = []
    @Published private(set) var albums: [Album] = []
    @Published private(set) var artists: [Artist] = []
    @Published private(set) var genres: [Genre] = []

    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Playback
    @Published private(set) var currentSong: Song?
    @Published private(set) var isPlaying = false
    @Published private(set) var isShuffled = false
    @Published private(set) var repeatMode: RepeatMode = .off
    
    @Published private(set) var isCurrentSongFavourite: Bool = false

    // MARK: - Dependencies
    private let folderService: DocumentFolderService
    let libraryService: MusicLibraryServiceProtocol
    let playerService: AudioPlayerServiceProtocol
    let progressStore: PlaybackProgressStore
    private let playHistoryService: PlayHistoryService

    private var playerTasks: [Task<Void, Never>] = []
    private var pendingPauseTask: Task<Void, Never>?

    // MARK: - Queue
    private var queue: [Song] = []
    private var currentIndex: Int?

    // MARK: - Persistence
    private let playbackStateService: PlaybackStateServiceProtocol
    private var hasRestoredSession = false
    private var lastPersistDate: Date = .distantPast
    private let persistInterval: TimeInterval = 5
    
    var queueSnapshot: [Song] { queue }
    var currentQueueIndex: Int? { currentIndex }

    init(
        libraryService: MusicLibraryServiceProtocol,
        playerService: AudioPlayerServiceProtocol,
        playbackStateService: PlaybackStateServiceProtocol,
        folderService: DocumentFolderService,
        playHistoryService: PlayHistoryService,
        progressStore: PlaybackProgressStore
    ) {
        self.libraryService = libraryService
        self.playerService = playerService
        self.playbackStateService = playbackStateService
        self.folderService = folderService
        self.playHistoryService = playHistoryService
        self.progressStore = progressStore

        bindPlayer()
        setupRemoteCommandCenter()
        observeAppLifecycle()
    }

    deinit {
        playerTasks.forEach { $0.cancel() }
        pendingPauseTask?.cancel()
    }

    // MARK: - Library
    func loadLibrary() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let songs = try await libraryService.loadLibrary()
            self.songs = songs
            self.albums = Self.groupAlbums(from: songs)
            self.artists = Self.groupArtists(from: songs)
            self.genres = Self.groupGenres(from: songs)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func refresh() async { await loadLibrary() }

    @MainActor
    func syncLibrary() async { await loadLibrary() }

    func deleteSong(_ song: Song) {
        do {
            try libraryService.delete(song)
            songs.removeAll { $0.id == song.id }
            albums = Self.groupAlbums(from: songs)
            artists = Self.groupArtists(from: songs)
            genres = Self.groupGenres(from: songs)
            queue.removeAll { $0.id == song.id }

            if currentSong?.id == song.id {
                playerService.stop()
                currentSong = nil
                queue = []
                currentIndex = nil
                SharedDataManager.shared.clearWidgetData()
                WidgetCenter.shared.reloadTimelines(ofKind: "MusicPlayerWidget")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Playback entry
    func playAll(_ songs: [Song]) {
        guard let first = songs.first else { return }
        isShuffled = false
        repeatMode = .all
        queue = songs
        currentIndex = 0
        startPlayback(of: first)
    }

    func shuffleAll(_ songs: [Song]) {
        guard !songs.isEmpty else { return }
        let shuffled = songs.shuffled()
        isShuffled = true
        repeatMode = .all
        queue = shuffled
        currentIndex = 0
        startPlayback(of: shuffled[0])
    }

    func play(_ song: Song, in songs: [Song]) {
        guard !songs.isEmpty else { return }
        queue = songs
        currentIndex = songs.firstIndex { $0.id == song.id } ?? 0
        repeatMode = .all
        startPlayback(of: song)
    }

    func pausePlayback() { playerService.pause() }

    // MARK: - Transport
    func togglePlayPause() {
        guard currentSong != nil else { return }
        
        if isPlaying {
            playerService.pause()
        } else {
            playerService.play()
        }
        persistState()
    }

    func playNext() {
        guard let index = currentIndex, !queue.isEmpty else { return }
        if repeatMode == .one {
            playerService.seek(toTime: 0)
            return
        }
        let next = index + 1
        if next < queue.count {
            currentIndex = next
            startPlayback(of: queue[next])
        } else if repeatMode == .all {
            currentIndex = 0
            startPlayback(of: queue[0])
        } else {
            playerService.pause()
        }
        persistState()
    }

    func playPrevious() {
        guard let index = currentIndex, !queue.isEmpty else { return }
        if repeatMode == .one {
            playerService.seek(toTime: 0)
            return
        }
        let previous = index - 1
        if previous >= 0 {
            currentIndex = previous
            startPlayback(of: queue[previous])
        } else if let current = currentSong {
            startPlayback(of: current)
        }
        persistState()
    }

    func seek(toProgress value: Double) {
        playerService.seek(toProgress: value)
        
        if let duration = currentSong?.duration, duration > 0 {
            progressStore.elapsed = value * duration
            progressStore.progress = value
            updateNowPlayingInfo()
        }
        persistState()
    }
    
    func toggleShuffle() {
        isShuffled.toggle()
        persistState()
    }
    
    func cycleRepeatMode() {
        switch repeatMode {
        case .off: repeatMode = .all
        case .all: repeatMode = .one
        case .one: repeatMode = .off
        }
        playerService.setLooping(repeatMode == .one)
        persistState()
    }
    
    // MARK: - Favourites
    private func updateFavouriteState() {
        guard let song = currentSong,
              let relativePath = folderService.relativePath(for: song.url),
              let context = AppDelegate.modelContainer?.mainContext else {
            isCurrentSongFavourite = false
            return
        }
        let service = FavouritesService(context: context)
        isCurrentSongFavourite = service.isFavourite(relativePath)
    }
    
    func toggleFavourite() {
        guard let song = currentSong,
              let relativePath = folderService.relativePath(for: song.url),
              let context = AppDelegate.modelContainer?.mainContext else { return }
        
        let service = FavouritesService(context: context)
        _ = try? service.toggleFavourite(relativePath)
        updateFavouriteState()
    }

    // MARK: - Private playback
    private func startPlayback(of song: Song) {
        currentSong = song
        updateFavouriteState()
        progressStore.elapsed = 0
        progressStore.progress = 0
        
        do {
            try playerService.load(url: song.url)
            playerService.setLooping(repeatMode == .one)
            playerService.play()
        } catch {
            errorMessage = "Could not play \"\(song.title)\"."
        }
        
        if let rel = folderService.relativePath(for: song.url) {
            try? playHistoryService.recordPlay(rel)
        }
        
        updateNowPlayingInfo()
        persistState()
        syncWidget()
    }

    // MARK: - Async/Await Observation
    private func bindPlayer() {
        // Observe isPlaying
        playerTasks.append(Task { [weak self] in
            guard let self = self else { return }
            for await playing in self.playerService.isPlayingPublisher.values {
                if playing {
                    // Cancel pending pause updates if playback resumes/starts
                    self.pendingPauseTask?.cancel()
                    await MainActor.run {
                        self.isPlaying = true
                        self.updateNowPlayingInfo()
                        self.syncWidget()
                    }
                } else {
                    // Debounce: Wait 150ms before showing the Pause state
                    self.pendingPauseTask?.cancel()
                    self.pendingPauseTask = Task { [weak self] in
                        try? await Task.sleep(nanoseconds: 150_000_000)
                        guard !Task.isCancelled else { return }
                        
                        await MainActor.run {
                            self?.isPlaying = false
                            self?.updateNowPlayingInfo()
                            self?.syncWidget()
                        }
                    }
                }
            }
        })
        
        // Observe elapsed time
        playerTasks.append(Task { [weak self] in
            guard let self = self else { return }
            for await newElapsed in self.playerService.elapsedPublisher.values {
                await MainActor.run {
                    self.progressStore.elapsed = newElapsed
                }
            }
        })
        
        // Observe progress
        playerTasks.append(Task { [weak self] in
            guard let self = self else { return }
            for await newProgress in self.playerService.progressPublisher.values {
                await MainActor.run {
                    self.progressStore.progress = newProgress
                    
                    let now = Date()
                    guard now.timeIntervalSince(self.lastPersistDate) >= self.persistInterval, self.isPlaying else { return }
                    self.persistState()
                }
            }
        })
        
        // Observe track finished
        playerTasks.append(Task { [weak self] in
            guard let self = self else { return }
            for await _ in self.playerService.trackDidFinishPublisher.values {
                await MainActor.run {
                    self.handleTrackFinished()
                }
            }
        })
    }

    private func handleTrackFinished() {
        switch repeatMode {
        case .one:
            if let current = currentSong { startPlayback(of: current) }
        case .all, .off:
            playNext()
        }
    }

    func importSongs(from urls: [URL]) async {
        guard let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        for sourceURL in urls {
            let accessed = sourceURL.startAccessingSecurityScopedResource()
            defer { if accessed { sourceURL.stopAccessingSecurityScopedResource() } }
            let destination = docsURL.appendingPathComponent(sourceURL.lastPathComponent)
            guard !FileManager.default.fileExists(atPath: destination.path) else { continue }
            do { try FileManager.default.copyItem(at: sourceURL, to: destination) } catch { continue }
        }
        await loadLibrary()
    }

    func enqueueNext(_ song: Song) {
        guard let currentIndex, !queue.isEmpty else { play(song, in: [song]); return }
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
    
    // MARK: - Lyrics
    
    func saveLyrics(_ text: String, for song: Song) throws {
        try libraryService.saveLyrics(text, for: song)
        
        if let index = songs.firstIndex(where: { $0.id == song.id }) {
            songs[index].lyrics = text
            if currentSong?.id == song.id {
                currentSong = songs[index]
            }
        }
    }

    // MARK: - Restore Session
    func restoreLastSession() async {
        guard !hasRestoredSession else { return }
        if songs.isEmpty { await loadLibrary() }
        guard !songs.isEmpty else { return }
        
        guard let state = playbackStateService.load(),
              let relativePath = state.currentSongPath,
              let absoluteURL = folderService.absoluteURL(for: relativePath) else {
            hasRestoredSession = true; return
        }
        
        let targetURL = absoluteURL.standardizedFileURL
        guard let song = songs.first(where: { $0.url.standardizedFileURL == targetURL }) else {
            hasRestoredSession = true; return
        }
        
        let restoredQueue: [Song] = state.queuePaths.compactMap { path in
            guard let url = folderService.absoluteURL(for: path)?.standardizedFileURL else { return nil }
            return songs.first { $0.url.standardizedFileURL == url }
        }
        
        self.queue = restoredQueue.isEmpty ? songs : restoredQueue
        self.currentIndex = state.currentIndex
        self.isShuffled = state.isShuffled
        self.repeatMode = RepeatMode(rawValue: state.repeatMode) ?? .off
        self.currentSong = song
        updateFavouriteState()
        
        do {
            try playerService.load(url: song.url)
            playerService.setLooping(repeatMode == .one)
            playerService.seek(toTime: state.elapsed)
        } catch {
            errorMessage = "Could not restore last song."; return
        }
        
        self.progressStore.elapsed = state.elapsed
        self.progressStore.progress = (song.duration ?? 0) > 0 ? state.elapsed / (song.duration ?? 1) : 0
        hasRestoredSession = true
        updateNowPlayingInfo()
        syncWidget()
    }

    // MARK: - Persistence & Lifecycle
    private func persistState() {
        let currentSongPath = currentSong.flatMap { folderService.relativePath(for: $0.url.standardizedFileURL) }
        let state = PlaybackState(
            currentSongPath: currentSongPath, elapsed: progressStore.elapsed,
            queuePaths: queue.compactMap { folderService.relativePath(for: $0.url.standardizedFileURL) },
            currentIndex: currentIndex, isShuffled: isShuffled, repeatMode: repeatMode.rawValue, savedAt: Date()
        )
        playbackStateService.save(state)
        lastPersistDate = Date()
    }

    private func observeAppLifecycle() {
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in self?.persistState() }
        }
        NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in self?.persistState() }
        }
    }
}

// MARK: - Grouping & Lookups
extension MusicLibraryViewModel {
    static func groupAlbums(from songs: [Song]) -> [Album] {
        Dictionary(grouping: songs, by: \.album).map { key, value in
            Album(id: key, title: key, artist: value.first?.artist ?? "Unknown Artist", songs: value.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending })
        }.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }
    static func groupArtists(from songs: [Song]) -> [Artist] {
        Dictionary(grouping: songs, by: \.artist).map { key, value in Artist(id: key, name: key, songs: value) }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
    static func groupGenres(from songs: [Song]) -> [Genre] {
        Dictionary(grouping: songs, by: \.genre).map { key, value in Genre(id: key, name: key, songs: value.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }) }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
    func artist(for song: Song) -> Artist? { artists.first { $0.name == song.artist } }
    func artist(named name: String) -> Artist? { artists.first { $0.name == name } }
    func genre(for song: Song) -> Genre? { genres.first { $0.name == song.genre } }
    func album(for song: Song) -> Album? { albums.first { $0.title == song.album } }
    func songs(forRelativePaths paths: [String], folderService: DocumentFolderService) -> [Song] {
        var byRelativePath: [String: Song] = [:]
        for song in songs { if let rel = folderService.relativePath(for: song.url) { byRelativePath[rel] = song } }
        return paths.compactMap { byRelativePath[$0] }
    }
    private func syncWidget() {
        SharedDataManager.shared.updateWidgetData(title: currentSong?.title, artist: currentSong?.artist, artworkData: currentSong?.artworkData, isPlaying: isPlaying)
        WidgetCenter.shared.reloadTimelines(ofKind: "MusicPlayerWidget")
    }
}
