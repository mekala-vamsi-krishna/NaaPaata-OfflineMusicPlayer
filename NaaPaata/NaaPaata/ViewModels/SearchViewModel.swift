//
//  SearchViewModel.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 7/10/26.
//

import SwiftUI

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var matchedSongs: [Song] = []
    @Published var matchedAlbums: [Album] = []

    private let musicManager = MusicPlayerManager.shared

    func search(allSongs: [Song], allAlbums: [Album]) {
        guard !searchText.isEmpty else {
            matchedSongs = []
            matchedAlbums = []
            return
        }

        let query = searchText.lowercased()

        // Search songs by title or artist
        matchedSongs = allSongs.filter {
            $0.title.lowercased().contains(query) ||
            $0.artist.lowercased().contains(query)
        }

        // Search albums by name or artist
        matchedAlbums = allAlbums.filter {
            $0.name.lowercased().contains(query) ||
            $0.artist.lowercased().contains(query)
        }
    }

    /// Play a song from the search results.
    /// Isolated playback: next/prev/shuffle/repeat operate only on matched songs.
    func playSongFromSearchResults(_ song: Song) {
        guard matchedSongs.firstIndex(where: { $0.id == song.id }) != nil else { return }
        musicManager.playFromAllSongs(
            matchedSongs,
            startAt: song,
            fromPlaylist: "Search Results",
            shuffle: false,
            repeatMode: .off
        )
    }
}
