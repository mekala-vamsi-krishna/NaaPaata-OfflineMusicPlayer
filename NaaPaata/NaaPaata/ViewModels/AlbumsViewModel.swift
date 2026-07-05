//
//  AlbumsViewModel.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/18/25.
//

import SwiftUI
import SwiftData

@MainActor
final class AlbumsViewModel: ObservableObject {
    private var modelContext: ModelContext?
    private var lastSongsHash: Int = 0
    
    @AppStorage("albumsSortOption") var currentSort: SortKey = .name
    
    @Published var albums: [Album] = []
    @Published var searchText: String = ""
    @Published var loadingProgress: Double = 0.0
    @Published var isLoading: Bool = true
    @Published var isRefreshing: Bool = false

    enum SortKey: String, CaseIterable {
        case name, artist, dateAddedAscending, dateAddedDescending, dateModified, size
    }

    var filteredAlbums: [Album] {
        guard !searchText.isEmpty else { return albums }
        return albums.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.artist.localizedCaseInsensitiveContains(searchText) ||
            $0.songs.contains(where: { $0.artist.localizedCaseInsensitiveContains(searchText) })
        }
    }
    
    // MARK: - Setup
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Load Albums
    func loadAlbums(forceRefresh: Bool = false) async {
        guard let context = modelContext else {
            debugPrint("❌ ModelContext not set in AlbumsViewModel")
            return
        }
        
        let allSongs = fetchAllSongsFromDatabase()
        let songsHash = allSongs.hashValue
        
        // Only rebuild albums if songs have changed or forceRefresh
        if !forceRefresh && songsHash == lastSongsHash && !albums.isEmpty {
            // Just apply sorting (in case user changed it)
            await MainActor.run {
                sortAlbums(by: currentSort)
                isLoading = false
            }
            // Still run background sync to detect new/deleted files
            await performBackgroundSync(forceRefresh: false)
            return
        }
        
        lastSongsHash = songsHash
        
        let groupedAlbums = groupSongsIntoAlbums(songs: allSongs)
        
        await MainActor.run {
            albums = groupedAlbums
            sortAlbums(by: currentSort)
            isLoading = albums.isEmpty
            loadingProgress = 0.0
        }
        
        await performBackgroundSync(forceRefresh: forceRefresh)
    }
    
    // MARK: - Background Sync
    private func performBackgroundSync(forceRefresh: Bool = false) async {
        await MainActor.run {
            if !isLoading { isRefreshing = true }
        }
        
        guard let context = modelContext else {
            await MainActor.run {
                isLoading = false
                isRefreshing = false
            }
            return
        }
        
        let allURLs = LoadAllSongsFromDocuments().loadSongsFromDocuments()
        let currentPaths = Set(allURLs.map { $0.path })
        let existingSongs = fetchAllSongsFromDatabase()
        let existingPaths = Set(existingSongs.map { $0.urlString })
        
        let newPaths = currentPaths.subtracting(existingPaths)
        let deletedPaths = existingPaths.subtracting(currentPaths)
        
        let pathsToProcess = forceRefresh ? allURLs.map { $0.path } : Array(newPaths)
        let urlsToProcess = allURLs.filter { pathsToProcess.contains($0.path) }
        var changed = false
        
        if !urlsToProcess.isEmpty {
            let newSongs = await ConcurrentMetadataService.shared.loadSongsMetadata(
                urls: urlsToProcess
            ) { progress in
                Task { @MainActor in self.loadingProgress = progress }
            }
            for song in newSongs {
                context.insert(song)
            }
            changed = true
        }
        
        if !deletedPaths.isEmpty {
            let songsToDelete = existingSongs.filter { deletedPaths.contains($0.urlString) }
            for song in songsToDelete {
                context.delete(song)
            }
            changed = true
        }
        
        if changed {
            try? context.save()
            lastSongsHash = 0 // Force rebuild next time
        }
        
        // Reload from DB and regroup
        let updatedSongs = fetchAllSongsFromDatabase()
        let updatedAlbums = groupSongsIntoAlbums(songs: updatedSongs)
        
        await MainActor.run {
            albums = updatedAlbums
            sortAlbums(by: currentSort)
            isLoading = false
            isRefreshing = false
            loadingProgress = 1.0
        }
    }
    
    // MARK: - Helpers
    private func fetchAllSongsFromDatabase() -> [Song] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<Song>(sortBy: [SortDescriptor(\.title)])
        return (try? context.fetch(descriptor)) ?? []
    }
    
    private func groupSongsIntoAlbums(songs: [Song]) -> [Album] {
        let grouped = Dictionary(grouping: songs, by: { $0.album })
        var albumObjects: [Album] = []
        for (albumName, albumSongs) in grouped {
            let sortedSongs = albumSongs.sorted { $0.title < $1.title }
            let artist = sortedSongs.first?.artist ?? "Unknown Artist"
            let artwork = sortedSongs.first?.artworkImage
            
            // Compute dates (earliest and latest)
            let dates = sortedSongs.compactMap { $0.dateAdded }
            let dateAdded = dates.min() ?? Date()
            let dateModified = dates.max() ?? Date()
            
            // Compute total size (sum of file sizes)
            let totalSize = sortedSongs.reduce(0) { partialResult, song in
                let attributes = try? FileManager.default.attributesOfItem(atPath: song.urlString)
                let size = (attributes?[.size] as? NSNumber)?.intValue ?? 0
                return partialResult + size
            }
            
            let album = Album(
                name: albumName,
                artist: artist,
                songs: sortedSongs,
                artworkImage: artwork,
                dateAdded: dateAdded,
                dateModified: dateModified,
                totalSize: Int64(totalSize)
            )
            albumObjects.append(album)
        }
        return albumObjects
    }
    
    // MARK: - Sorting
    func sortAlbums(by key: SortKey) {
        switch key {
        case .name:
            albums.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .artist:
            albums.sort { $0.artist.localizedCaseInsensitiveCompare($1.artist) == .orderedAscending }
        case .dateAddedAscending:
            albums.sort { $0.dateAdded < $1.dateAdded }
        case .dateAddedDescending:
            albums.sort { $0.dateAdded > $1.dateAdded }
        case .dateModified:
            albums.sort { $0.dateModified < $1.dateModified }
        case .size:
            albums.sort { $0.totalSize > $1.totalSize } // Descending: largest first
        }
        currentSort = key
    }
    
    // MARK: - Refresh
    func refresh() {
        Task {
            await loadAlbums(forceRefresh: true)
        }
    }
}
