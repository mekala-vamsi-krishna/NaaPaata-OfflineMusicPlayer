//
//  AlbumsViewModel.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/18/25.
//

import SwiftUI
import AVFoundation
import Combine

class AlbumsViewModel: ObservableObject {
    @Published var albums: [Album] = []
    @Published var searchText: String = ""
    @Published var loadingProgress: Double = 0.0
    @Published var isLoading: Bool = false

    enum SortKey: String, CaseIterable {
        case name, artist, dateAddedAscending, dateAddedDescending, dateModified, size
    }
    
    @AppStorage("albumsSortOption") var currentSort: SortKey = .name

    var filteredAlbums: [Album] {
        guard !searchText.isEmpty else { return albums }
        return albums.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.songs.contains(where: { $0.artist.localizedCaseInsensitiveContains(searchText) })
        }
    }


    func loadAlbums() async {
        // Cache check: if we already have albums, don't reload
        guard albums.isEmpty else { return }
        
        await MainActor.run {
            isLoading = true
            loadingProgress = 0.0
        }
        
        do {
            let fileManager = FileManager.default
            guard let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                await MainActor.run {
                    isLoading = false
                    loadingProgress = 1.0
                }
                return
            }
            
            let musicFolder = docsURL.appendingPathComponent("Music", isDirectory: true)
            
            if !fileManager.fileExists(atPath: musicFolder.path) {
                try fileManager.createDirectory(at: musicFolder, withIntermediateDirectories: true)
            }
            
            // Find all MP3 files concurrently
            let mp3Files = try await ConcurrentMetadataService.shared.findMP3Files(in: musicFolder)
            
            guard !mp3Files.isEmpty else {
                await MainActor.run {
                    albums = []
                    isLoading = false
                    loadingProgress = 1.0
                }
                return
            }
            
            // Use the concurrent metadata service
            let loadedAlbums = try await ConcurrentMetadataService.shared.loadAlbumsFromSongs(urls: mp3Files) { progress in
                Task { @MainActor in
                    self.loadingProgress = progress
                }
            }
            
            await MainActor.run {
                albums = loadedAlbums
                sortAlbums(by: currentSort)
                isLoading = false
                loadingProgress = 1.0
            }
            
        } catch {
            print("Error loading albums: \(error.localizedDescription)")
            await MainActor.run {
                isLoading = false
                loadingProgress = 1.0
            }
        }
    }

    func sortAlbums(by key: SortKey) {
        switch key {
        case .name:
            albums.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .artist:
            albums.sort {
                let artist1 = $0.songs.first?.artist ?? ""
                let artist2 = $1.songs.first?.artist ?? ""
                return artist1.localizedCaseInsensitiveCompare(artist2) == .orderedAscending
            }
        case .dateAddedAscending:
            albums.sort { $0.dateAdded < $1.dateAdded }
        case .dateAddedDescending:
            albums.sort { $0.dateAdded > $1.dateAdded }
        case .dateModified:
            albums.sort { $0.dateModified < $1.dateModified }
        case .size:
            albums.sort { $0.songs.count > $1.songs.count }
        }
        // Update the current sort option
        currentSort = key
    }
}

