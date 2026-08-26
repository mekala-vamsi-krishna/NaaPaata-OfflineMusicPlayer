//
//  SongsViewModel.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/17/25.
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
final class SongsViewModel: ObservableObject {
    // MARK: - Dependencies
    private let libraryService: SongLibraryService
    private let dataService: DataServiceProtocol
    private let musicManager = MusicPlayerManager.shared

    // MARK: - Published Properties
    @Published var songs: [Song] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = true
    @Published var loadingProgress: Double = 0.0

    @AppStorage("songsSortOption") var currentSort: SortKey = .title

    var totalSongs: Int { songs.count }
    
    var filteredSongs: [Song] {
        guard !searchText.isEmpty else { return songs }
        return songs.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.artist.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - Init
    init(libraryService: SongLibraryService, dataService: DataServiceProtocol) {
        self.libraryService = libraryService
        self.dataService = dataService
        observeSongDeletion()
    }

    // MARK: - loadSongs
    /// Loads all songs from disk, syncs with the database, and updates the published list.
    func loadSongs() async {
        await MainActor.run {
            isLoading = true
            loadingProgress = 0.0
        }
        let fetchedSongs = await libraryService.loadAllSongs { progress in
            Task { @MainActor in
                self.loadingProgress = progress
            }
        }
        
        try? await Task.sleep(nanoseconds: 100_000_000)

        await MainActor.run {
            songs = fetchedSongs
            sortSongs(by: currentSort)
            isLoading = false
            loadingProgress = 1.0
            
            MusicPlayerManager.shared.ensureEngineReady()
            musicManager.setPlaylist(songs)
        }
    }

    // MARK: - Sort Songs
    /// Sorts the current song list by the given key.
    func sortSongs(by key: SortKey) {
        switch key {
        case .title: songs.sort { $0.title < $1.title }
        case .artist: songs.sort { $0.artist < $1.artist }
        case .duration: songs.sort { $0.duration < $1.duration }
        case .dateAddedAscending:
            songs.sort { ($0.dateAdded ?? Date.distantPast) < ($1.dateAdded ?? Date.distantPast) }
        case .dateAddedDescending:
            songs.sort { ($0.dateAdded ?? Date.distantPast) > ($1.dateAdded ?? Date.distantPast) }
        }
        currentSort = key
    }

    // MARK: - Playback Actions
    func play(_ song: Song) {
        musicManager.playFromAllSongs(songs, startAt: song, fromPlaylist: "All Songs", shuffle: false, repeatMode: .all)
    }

    func playAll() {
        musicManager.playFromAllSongs(songs, fromPlaylist: "All Songs", shuffle: false, repeatMode: .all)
    }

    func playShuffled() {
        musicManager.playFromAllSongs(songs, fromPlaylist: "All Songs", shuffle: true, repeatMode: .off)
    }

    func playFromSearchResults(_ song: Song) {
        let results = filteredSongs
        musicManager.playFromAllSongs(results, startAt: song, fromPlaylist: "All Songs", shuffle: false, repeatMode: .all)
    }

    // MARK: - Import & Refresh
    func refresh() {
        Task { await loadSongs() }
    }

    /// Copies external audio files into the app's Documents folder and triggers a reload.
    func importSongs(from urls: [URL]) {
        guard let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }

        var importedCount = 0
        for sourceURL in urls {
            let accessed = sourceURL.startAccessingSecurityScopedResource()
            defer { if accessed { sourceURL.stopAccessingSecurityScopedResource() } }

            let destURL = docsURL.appendingPathComponent(sourceURL.lastPathComponent)

            guard !FileManager.default.fileExists(atPath: destURL.path) else {
                ToastManager.shared.showToast(message: "\(sourceURL.lastPathComponent) already exists")
                continue
            }

            do {
                try FileManager.default.copyItem(at: sourceURL, to: destURL)
                importedCount += 1
            } catch {
                print("❌ Failed to import \(sourceURL.lastPathComponent): \(error)")
                ToastManager.shared.showToast(message: "Failed to import \(sourceURL.lastPathComponent)")
            }
        }

        if importedCount > 0 {
            let message = importedCount == 1 ? "1 song imported" : "\(importedCount) songs imported"
            ToastManager.shared.showToast(message: message)
            Task { await loadSongs() }
        }
    }

    // MARK: - Private Helpers
    private func observeSongDeletion() {
        NotificationCenter.default.addObserver(
            forName: .songDeleted,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let song = notification.userInfo?["song"] as? Song else { return }
            // Remove from the published list immediately
            self.songs.removeAll { $0.id == song.id }
        }
    }
}

// MARK: - SortKey
extension SongsViewModel {
    enum SortKey: String, CaseIterable {
        case title, artist, duration, dateAddedAscending, dateAddedDescending
    }
}
