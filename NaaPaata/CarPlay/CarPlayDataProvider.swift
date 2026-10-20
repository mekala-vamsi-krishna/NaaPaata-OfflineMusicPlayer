//
//  CarPlayDataProvider.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/20/26.
//

import Foundation
import SwiftData

@MainActor
final class CarPlayDataProvider {
    private let modelContext: ModelContext
    private let folderService: DocumentFolderService
    private let libraryViewModel: MusicLibraryViewModel

    init(modelContext: ModelContext, folderService: DocumentFolderService, libraryViewModel: MusicLibraryViewModel) {
        self.modelContext = modelContext
        self.folderService = folderService
        self.libraryViewModel = libraryViewModel
    }

    var songs: [Song] { libraryViewModel.songs }
    var albums: [Album] { libraryViewModel.albums }
    var artists: [Artist] { libraryViewModel.artists }
    var genres: [Genre] { libraryViewModel.genres }
    var currentSong: Song? { libraryViewModel.currentSong }
    var isPlaying: Bool { libraryViewModel.isPlaying }

    func fetchPlaylists() -> [Playlist] {
        let descriptor = FetchDescriptor<Playlist>(sortBy: [SortDescriptor(\.dateCreated, order: .reverse)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func resolveFavourites() -> [Song] {
        let descriptor = FetchDescriptor<FavouriteSong>(sortBy: [SortDescriptor(\.dateAdded, order: .reverse)])
        let favourites = (try? modelContext.fetch(descriptor)) ?? []
        return libraryViewModel.songs(forRelativePaths: favourites.map(\.songRelativePath), folderService: folderService)
    }

    func resolvedSongs(for playlist: Playlist) -> [Song] {
        libraryViewModel.songs(forRelativePaths: playlist.songRelativePaths, folderService: folderService)
    }

    func favouritesCountText() -> String {
        let descriptor = FetchDescriptor<FavouriteSong>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        if count == 0 { return "Your picks" }
        return "\(count) favourite\(count == 1 ? "" : "s")"
    }
}
