//
//  SongsViewModel.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/17/25.
//

import Foundation
import AVFoundation
import SwiftUI

final class SongsViewModel: ObservableObject {
    private let musicManager = MusicPlayerManager.shared
    
    @Published var searchText: String = ""
    @Published var songs: [Song] = []
    @Published var loadingProgress: Double = 0.0
    @Published var isLoading: Bool = false
    var totalSongs: Int { songs.count }
    
    enum SortKey: String, CaseIterable {
        case title, artist, duration, dateAddedAscending, dateAddedDescending
    }
    
    @AppStorage("songsSortOption") var currentSort: SortKey = .title

    var filteredSongs: [Song] {
        guard !searchText.isEmpty else { return songs }
        return songs.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.artist.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleSongDeleted), name: .songDeleted, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Function to play within search results
    func playFromSearchResults(_ song: Song) {
        let results = filteredSongs
        musicManager.playFromAllSongs(results, startAt: song)
    }
    
    @objc private func handleSongDeleted(notification: Notification) {
        guard let song = notification.userInfo?["song"] as? Song else { return }
        
        DispatchQueue.main.async {
            // Remove the song from the list
            if let index = self.songs.firstIndex(where: { $0.urlString == song.urlString }) {
                self.songs.remove(at: index)
            }
        }
    }

    func loadSongs() async {
        guard !isLoading else { return }
        
        await MainActor.run {
            isLoading = true
            loadingProgress = 0.0
        }
        
        do {
            let loader = LoadAllSongsFromDocuments()
            let urls = loader.loadSongsFromDocuments()
            
            guard !urls.isEmpty else {
                await MainActor.run {
                    songs = []
                    isLoading = false
                    loadingProgress = 1.0
                }
                return
            }
            
            // Use the concurrent metadata service
            let loadedSongs = try await ConcurrentMetadataService.shared.loadSongsMetadata(urls: urls) { progress in
                Task { @MainActor in
                    self.loadingProgress = progress
                }
            }
            
            await MainActor.run {
                songs = loadedSongs
                sortSongs(by: currentSort)
                isLoading = false
                loadingProgress = 1.0
            }
            
        } catch {
            print("Error loading songs: \(error.localizedDescription)")
            await MainActor.run {
                isLoading = false
                loadingProgress = 1.0
            }
        }
    }
    
    // Shuffle songs
    func shuffleSongs() -> [Song] {
        songs.shuffled()
    }
    
    // Sort songs (by title or artist)
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
        // Update the current sort option
        currentSort = key
    }
    
    func play(_ song: Song) {
        musicManager.playFromAllSongs(songs, startAt: song, fromPlaylist: "All Songs")
    }
    
    func playAll() {
        musicManager.playFromAllSongs(songs, fromPlaylist: "All Songs")
    }
    
    func playShuffled() {
        // Play all songs first to set the original playlist
        musicManager.playFromAllSongs(songs, fromPlaylist: "All Songs")
        
        // Then toggle shuffle mode to shuffle the playlist while starting from the current song
        musicManager.toggleShuffle()
    }
    
    // Call this after delete or whenever manager changes
    func refresh() {
        Task {
            await loadSongs()
        }
    }
}
