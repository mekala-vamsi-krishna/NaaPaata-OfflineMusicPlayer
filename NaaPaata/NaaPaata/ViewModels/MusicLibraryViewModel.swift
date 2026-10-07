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
    @Published private(set) var artists: [Artist] = []
    @Published private(set) var genres: [Genre] = []

    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Playback
    @Published private(set) var currentSong: Song?
    @Published private(set) var isPlaying = false
    @Published private(set) var isShuffled = false
    @Published private(set) var repeatMode: RepeatMode = .off

    // MARK: - Dependencies
    private let folderService: DocumentFolderService
    let libraryService: MusicLibraryServiceProtocol
    let playerService: AudioPlayerServiceProtocol
    let progressStore: PlaybackProgressStore

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
        folderService: DocumentFolderService,
        progressStore: PlaybackProgressStore
    ) {
        self.libraryService = libraryService
        self.playerService = playerService
        self.playbackStateService = playbackStateService
        self.folderService = folderService
        self.progressStore = progressStore

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
            self.artists = Self.groupArtists(from: songs)
            self.genres = Self.groupGenres(from: songs)
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

            // Regroup everything — a deletion can wipe out an artist,
            // album, or genre entirely.
            albums = Self.groupAlbums(from: songs)
            artists = Self.groupArtists(from: songs)
            genres = Self.groupGenres(from: songs)

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

    // MARK: - Private playback

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

                self.progressStore.elapsed = newElapsed

                MPNowPlayingInfoCenter.default().nowPlayingInfo?[
                    MPNowPlayingInfoPropertyElapsedPlaybackTime
                ] = newElapsed
            }
            .store(in: &cancellables)

        playerService.progressPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newProgress in
                guard let self else { return }

                self.progressStore.progress = newProgress

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

            guard !FileManager.default.fileExists(atPath: destination.path) else {
                continue
            }

            do {
                try FileManager.default.copyItem(at: sourceURL, to: destination)
            } catch {
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

        guard
            let state = playbackStateService.load(),
            let relativePath = state.currentSongPath,
            let absoluteURL = folderService.absoluteURL(for: relativePath),
            let song = songs.first(where: { $0.url.path == absoluteURL.path })
        else {
            return
        }

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

        self.progressStore.elapsed = state.elapsed
        self.progressStore.progress = (song.duration ?? 0) > 0
            ? state.elapsed / (song.duration ?? 0)
            : 0

        updateNowPlayingInfo()
    }

    private func persistState() {
        let state = PlaybackState(
            currentSongPath: currentSong.flatMap {
                folderService.relativePath(for: $0.url)
            },
            elapsed: progressStore.elapsed,
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

// MARK: - Grouping

extension MusicLibraryViewModel {

    // MARK: - Albums

    static func groupAlbums(from songs: [Song]) -> [Album] {
        Dictionary(grouping: songs, by: \.album)
            .map { key, value in
                Album(
                    id: key,
                    title: key,
                    // Album artist: whichever artist appears on the album's
                    // first song. Good enough for a library view — albums
                    // rarely have mixed artists, and when they do, the first
                    // song is a defensible representative.
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

    // MARK: - Artists

    static func groupArtists(from songs: [Song]) -> [Artist] {
        Dictionary(grouping: songs, by: \.artist)
            .map { key, value in
                Artist(id: key, name: key, songs: value)
            }
            .sorted {
                $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
    }

    // MARK: - Genres

    static func groupGenres(from songs: [Song]) -> [Genre] {
        Dictionary(grouping: songs, by: \.genre)
            .map { key, value in
                Genre(
                    id: key,
                    name: key,
                    songs: value.sorted {
                        $0.title.localizedStandardCompare($1.title) == .orderedAscending
                    }
                )
            }
            .sorted {
                $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
    }
}

// MARK: - Lookups

extension MusicLibraryViewModel {

    /// Returns the `Artist` object that matches the given song's artist name.
    /// Used when navigating from a song row or album detail.
    func artist(for song: Song) -> Artist? {
        artists.first { $0.name == song.artist }
    }

    /// Returns the `Artist` whose name matches, if any.
    func artist(named name: String) -> Artist? {
        artists.first { $0.name == name }
    }

    /// Returns the `Genre` that matches the given song's genre.
    func genre(for song: Song) -> Genre? {
        genres.first { $0.name == song.genre }
    }

    /// Returns the `Album` that matches the given song's album.
    func album(for song: Song) -> Album? {
        albums.first { $0.title == song.album }
    }
}

// MARK: - Relative-path lookups

extension MusicLibraryViewModel {

    /// Resolves a list of paths (relative to Documents) against the
    /// in-memory library. Missing files are skipped silently.
    func songs(
        forRelativePaths paths: [String],
        folderService: DocumentFolderService
    ) -> [Song] {
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
