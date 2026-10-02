//
//  MusicLibraryViewModel.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 9/26/26.
//

import Combine
import Foundation
import MediaPlayer
import UIKit
import WidgetKit

@MainActor
class MusicLibraryViewModel: ObservableObject {

    // MARK: - Library
    @Published private(set) var songs: [Song] = []
    @Published private(set) var albums: [Album] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Playback
    @Published private(set) var currentSong: Song?
    @Published private(set) var isPlaying = false
    @Published private(set) var progress: Double = 0
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var isShuffled = false
    @Published private(set) var repeatMode: RepeatMode = .off

    // MARK: - Dependencies
    private let folderService: DocumentFolderService
    let libraryService: MusicLibraryServiceProtocol
    let playerService: AudioPlayerServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Queue
    private var queue: [Song] = []
    private var currentIndex: Int?
    
    // MARK: - Persistence
    private let playbackStateService: PlaybackStateServiceProtocol
    private var hasRestoredSession = false
    private var lastPersistDate: Date = .distantPast
    private let persistInterval: TimeInterval = 5

    init(
        libraryService: MusicLibraryServiceProtocol,
        playerService: AudioPlayerServiceProtocol,
        playbackStateService: PlaybackStateServiceProtocol,
        folderService: DocumentFolderService
    ) {
        self.libraryService = libraryService
        self.playerService = playerService
        self.playbackStateService = playbackStateService
        self.folderService = folderService
        bindPlayer()
        setupRemoteCommandCenter()
        observeAppLifecycle()
    }

    // MARK: - Library

    func loadLibrary() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let songs = try await libraryService.loadLibrary()
            self.songs = songs
            self.albums = Self.groupAlbums(from: songs)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func refresh() async {
        await loadLibrary()
    }
    
    @MainActor
    func syncLibrary() async {
        await loadLibrary()
    }

    func deleteSong(_ song: Song) {
        do {
            try libraryService.delete(song)
            songs.removeAll { $0.id == song.id }
            albums = Self.groupAlbums(from: songs)
            queue.removeAll { $0.id == song.id }

            if currentSong?.id == song.id {
                playerService.stop()
                currentSong = nil
                queue = []
                currentIndex = nil
                syncWidget()
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
    
    func pausePlayback() {
        playerService.pause()
    }

    // MARK: - Transport

    func togglePlayPause() {
        guard currentSong != nil else { return }
        isPlaying ? playerService.pause() : playerService.play()
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

    // MARK: - Private

    private func startPlayback(of song: Song) {
        currentSong = song
        do {
            try playerService.load(url: song.url)
            playerService.setLooping(repeatMode == .one)
            playerService.play()
        } catch {
            errorMessage = "Could not play \"\(song.title)\"."
        }
        updateNowPlayingInfo()
        persistState()
        syncWidget()
    }

    private func bindPlayer() {
        playerService.isPlayingPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] playing in
                guard let self else { return }
                self.isPlaying = playing
                self.updateNowPlayingInfo()
                self.syncWidget()
            }
            .store(in: &cancellables)

        playerService.elapsedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newElapsed in
                guard let self else { return }
                self.elapsed = newElapsed
                MPNowPlayingInfoCenter.default().nowPlayingInfo?[
                    MPNowPlayingInfoPropertyElapsedPlaybackTime
                ] = newElapsed
            }
            .store(in: &cancellables)

        playerService.progressPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newProgress in
                guard let self else { return }
                self.progress = newProgress

                let now = Date()
                guard now.timeIntervalSince(self.lastPersistDate) >= self.persistInterval,
                      self.isPlaying else { return }

                self.persistState()
            }
            .store(in: &cancellables)

        playerService.trackDidFinishPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handleTrackFinished() }
            .store(in: &cancellables)
    }

    private func handleTrackFinished() {
        switch repeatMode {
        case .one:
            if let current = currentSong {
                startPlayback(of: current)
            }
        case .all, .off:
            playNext()
        }
    }
    
    func importSongs(from urls: [URL]) async {
        guard let docsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else { return }

        for sourceURL in urls {
            let accessed = sourceURL.startAccessingSecurityScopedResource()
            defer {
                if accessed { sourceURL.stopAccessingSecurityScopedResource() }
            }

            let destination = docsURL.appendingPathComponent(sourceURL.lastPathComponent)

            // Skip if the file already exists.
            guard !FileManager.default.fileExists(atPath: destination.path) else {
                continue
            }

            do {
                try FileManager.default.copyItem(at: sourceURL, to: destination)
            } catch {
                // Non-fatal — skip files that can't be copied.
                continue
            }
        }

        await loadLibrary()
    }
    
    func enqueueNext(_ song: Song) {
        guard let currentIndex, !queue.isEmpty else {
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
    
    func restoreLastSession() async {
        guard !hasRestoredSession else { return }
        hasRestoredSession = true

        if songs.isEmpty {
            await loadLibrary()
        }

        // Read the saved state.
        guard
            let state = playbackStateService.load(),
            let relativePath = state.currentSongPath,
            let absoluteURL = folderService.absoluteURL(for: relativePath),
            let song = songs.first(where: { $0.url.path == absoluteURL.path })
        else {
            return
        }

        // Rebuild the queue by resolving each saved relative path.
        let restoredQueue: [Song] = state.queuePaths.compactMap { path in
            guard let url = folderService.absoluteURL(for: path) else { return nil }
            return songs.first { $0.url.path == url.path }
        }

        self.queue = restoredQueue.isEmpty ? songs : restoredQueue
        self.currentIndex = state.currentIndex
        self.isShuffled = state.isShuffled
        self.repeatMode = RepeatMode(rawValue: state.repeatMode) ?? .off
        self.currentSong = song

        do {
            try playerService.load(url: song.url)
            playerService.setLooping(repeatMode == .one)
            playerService.seek(toTime: state.elapsed)
        } catch {
            errorMessage = "Could not restore last song."
            return
        }

        self.elapsed = state.elapsed
        self.progress = (song.duration ?? 0) > 0
            ? state.elapsed / (song.duration ?? 0)
            : 0

        updateNowPlayingInfo()
    }
    
    private func persistState() {
        let state = PlaybackState(
            currentSongPath: currentSong.flatMap {
                folderService.relativePath(for: $0.url)
            },
            elapsed: elapsed,
            queuePaths: queue.compactMap {
                folderService.relativePath(for: $0.url)
            },
            currentIndex: currentIndex,
            isShuffled: isShuffled,
            repeatMode: repeatMode.rawValue,
            savedAt: Date()
        )
        playbackStateService.save(state)
        lastPersistDate = Date()
    }
    
    private static func groupAlbums(from songs: [Song]) -> [Album] {
        Dictionary(grouping: songs, by: \.album)
            .map { key, value in
                Album(
                    id: key,
                    title: key,
                    artist: value.first?.artist ?? "Unknown Artist",
                    songs: value.sorted {
                        $0.title.localizedStandardCompare($1.title) == .orderedAscending
                    }
                )
            }
            .sorted {
                $0.title.localizedStandardCompare($1.title) == .orderedAscending
            }
    }
    
    private func observeAppLifecycle() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.persistState()
            }
        }
    }
}

extension MusicLibraryViewModel {

    /// Resolves a list of paths (relative to Documents) against the
    /// in-memory library. Missing files are skipped silently.
    func songs(
        forRelativePaths paths: [String],
        folderService: DocumentFolderService
    ) -> [Song] {
        // Build the lookup once per call. O(n) for the library, O(m)
        // for the requested paths.
        var byRelativePath: [String: Song] = [:]
        byRelativePath.reserveCapacity(songs.count)

        for song in songs {
            if let rel = folderService.relativePath(for: song.url) {
                byRelativePath[rel] = song
            }
        }

        return paths.compactMap { byRelativePath[$0] }
    }
}

// MARK: - Widget Commands

extension MusicLibraryViewModel {

    /// Pushes the current playback state to the shared container and asks
    /// WidgetKit to refresh. Called whenever the song or play state changes.
    private func syncWidget() {
        SharedDataManager.shared.updateWidgetData(
            title: currentSong?.title,
            artist: currentSong?.artist,
            artworkData: currentSong?.artworkData,
            isPlaying: isPlaying
        )

        WidgetCenter.shared.reloadTimelines(ofKind: "MusicPlayerWidget")
    }
}
