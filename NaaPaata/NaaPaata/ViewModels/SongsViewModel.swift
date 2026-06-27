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
    private let musicManager = MusicPlayerManager.shared
    private var modelContext: ModelContext?
    
    @AppStorage("songsSortOption") var currentSort: SortKey = .title
    
    @Published var searchText: String = ""
    @Published var songs: [Song] = []
    @Published var loadingProgress: Double = 0.0
    @Published var isLoading: Bool = true
    @Published var isRefreshing: Bool = false
    
    var totalSongs: Int { songs.count }
    
    enum SortKey: String, CaseIterable {
        case title, artist, duration, dateAddedAscending, dateAddedDescending
    }
    
    var filteredSongs: [Song] {
        guard !searchText.isEmpty else { return songs }
        return songs.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.artist.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // MARK: - Model Context Setup
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - loadSongs
    func loadSongs(forceRefresh: Bool = false) async {
        guard let context = modelContext else {
            debugPrint("❌ ModelContext not set in SongsViewModel")
            return
        }
        let cachedSongs = fetchAllSongsFromDatabase()
        let hasCachedSongs = !cachedSongs.isEmpty
        await MainActor.run {
            songs = cachedSongs
            sortSongs(by: currentSort)
            isLoading = !hasCachedSongs
            loadingProgress = 0.0
        }
        await performBackgroundSync(forceRefresh: forceRefresh)
        musicManager.setPlaylist(songs)
    }
    
    // MARK: - performBackgroundSync
    private func performBackgroundSync(forceRefresh: Bool = false) async {
        await MainActor.run { if !isLoading { isRefreshing = true } }
        guard let context = modelContext else {
            await MainActor.run { isLoading = false; isRefreshing = false }
            return
        }
        
        let fileItems = LoadAllSongsFromDocuments().loadAllAudioFilesWithRelativePaths()
        let currentRelPaths = Set(fileItems.map { $0.relativePath })
        let existingSongs = fetchAllSongsFromDatabase()
        let existingRelPaths = Set(existingSongs.map { $0.relativePath })
        
        debugPrint("🔍 Sync: current files: \(fileItems.count), DB songs: \(existingSongs.count)")
        
        // Safety: if no files but DB has songs, skip deletion
        if fileItems.isEmpty && !existingSongs.isEmpty {
            debugPrint("⚠️ No files found – skipping sync to prevent data loss")
            await MainActor.run { isLoading = false; isRefreshing = false; loadingProgress = 1.0 }
            return
        }
        
        // Determine changes
        let newRelPaths = currentRelPaths.subtracting(existingRelPaths)
        let deletedRelPaths = existingRelPaths.subtracting(currentRelPaths)
        debugPrint("🔍 New: \(newRelPaths.count), Deleted: \(deletedRelPaths.count)")
        
        var changed = false
        
        // UPDATE existing songs with new absolute paths (if needed)
        for song in existingSongs {
            if let matchingFile = fileItems.first(where: { $0.relativePath == song.relativePath }) {
                let newURLString = matchingFile.url.path
                if song.urlString != newURLString {
                    song.urlString = newURLString
                    changed = true
                }
            }
        }
        
        // Insert new songs
        if !newRelPaths.isEmpty {
            let urlsToProcess = fileItems.filter { newRelPaths.contains($0.relativePath) }.map { $0.url }
            let newSongs = await ConcurrentMetadataService.shared.loadSongsMetadata(urls: urlsToProcess) { progress in
                Task { @MainActor in self.loadingProgress = progress }
            }
            for song in newSongs {
                // Ensure relativePath is not empty
                if song.relativePath.isEmpty {
                    let docsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.path + "/"
                    let path = song.urlString
                    song.relativePath = path.replacingOccurrences(of: docsPath, with: "")
                    if song.relativePath.isEmpty { song.relativePath = URL(string: song.urlString)?.lastPathComponent ?? "unknown" }
                }
                context.insert(song)
            }
            changed = true
        }
        
        // Delete songs that no longer exist on disk
        if !deletedRelPaths.isEmpty {
            let songsToDelete = existingSongs.filter { deletedRelPaths.contains($0.relativePath) }
            for song in songsToDelete {
                debugPrint("🗑️ Deleting song: \(song.title) (relativePath: \(song.relativePath))")
                context.delete(song)
            }
            changed = true
        }
        
        if changed {
            try? context.save()
        }
        
        let updatedSongs = fetchAllSongsFromDatabase()
        await MainActor.run {
            songs = updatedSongs
            sortSongs(by: currentSort)
            isLoading = false
            isRefreshing = false
            loadingProgress = 1.0
        }
    }
    
    // MARK: - fetchAllSongsFromDatabase
    private func fetchAllSongsFromDatabase() -> [Song] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<Song>(sortBy: [SortDescriptor(\.title)])
        return (try? context.fetch(descriptor)) ?? []
    }
    
    // MARK: - sortSongs
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
    
    // MARK: - playSong
    func play(_ song: Song) {
        musicManager.playFromAllSongs(songs, startAt: song, fromPlaylist: "All Songs", shuffle: false, repeatMode: .all)
    }
    
    // MARK: - playAll
    func playAll() {
        musicManager.playFromAllSongs(songs, fromPlaylist: "All Songs", shuffle: false, repeatMode: .all)
    }
    
    // MARK: - playShuffled
    func playShuffled() {
        musicManager.playFromAllSongs(songs, fromPlaylist: "All Songs", shuffle: true, repeatMode: .off)
    }
    
    // MARK: - playFromSearchResults
    func playFromSearchResults(_ song: Song) {
        let results = filteredSongs
        musicManager.playFromAllSongs(results, startAt: song, fromPlaylist: "All Songs", shuffle: false, repeatMode: .all)
    }
    
    // MARK: - refresh
    func refresh() {
        Task { await loadSongs(forceRefresh: true) }
    }
}
