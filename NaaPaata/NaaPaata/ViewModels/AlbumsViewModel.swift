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

    @AppStorage("albumsSortOption") var currentSort: SortKey = .name

    @Published var albums: [Album] = []
    @Published var searchText: String = ""
    
    @Published var isLoading: Bool = true
    @Published var isRefreshing: Bool = false
    
    @Published var loadingProgress: Double = 0.0

    enum SortKey: String, CaseIterable {
        case name, artist, dateAddedAscending, dateAddedDescending, dateModified, size
    }

    var filteredAlbums: [Album] {
        guard !searchText.isEmpty else { return albums }
        return albums.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.artist.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - Fetch albums from already-loaded songs
    func fetchAlbums(from songs: [Song]) {
        isLoading = songs.isEmpty
        isRefreshing = false

        let grouped = Dictionary(grouping: songs, by: { $0.album })
        var result: [Album] = grouped.map { albumName, albumSongs in
            let sorted = albumSongs.sorted { $0.title < $1.title }
            let artist = sorted.first?.artist ?? "Unknown Artist"
            let artwork = sorted.first?.artworkImage
            let dates = sorted.compactMap { $0.dateAdded }
            let dateAdded = dates.min() ?? Date()
            let dateModified = dates.max() ?? Date()
            let totalSize = sorted.reduce(into: 0) { acc, song in
                let attrs = try? FileManager.default.attributesOfItem(atPath: song.urlString)
                acc += (attrs?[.size] as? NSNumber)?.intValue ?? 0
            }
            return Album(
                name: albumName,
                artist: artist,
                songs: sorted,
                artworkImage: artwork,
                dateAdded: dateAdded,
                dateModified: dateModified,
                totalSize: Int64(totalSize)
            )
        }
        sortAlbums(by: currentSort, in: &result)
        albums = result
        isLoading = false
        loadingProgress = 1.0
    }

    // MARK: - Sorting
    func sortAlbums(by key: SortKey) {
        sortAlbums(by: key, in: &albums)
        currentSort = key
    }

    private func sortAlbums(by key: SortKey, in list: inout [Album]) {
        switch key {
        case .name:
            list.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .artist:
            list.sort { $0.artist.localizedCaseInsensitiveCompare($1.artist) == .orderedAscending }
        case .dateAddedAscending:
            list.sort { $0.dateAdded < $1.dateAdded }
        case .dateAddedDescending:
            list.sort { $0.dateAdded > $1.dateAdded }
        case .dateModified:
            list.sort { $0.dateModified < $1.dateModified }
        case .size:
            list.sort { $0.totalSize > $1.totalSize }
        }
        currentSort = key
    }

    // MARK: - Refresh
    func refresh() {
        isRefreshing = true
    }
}
