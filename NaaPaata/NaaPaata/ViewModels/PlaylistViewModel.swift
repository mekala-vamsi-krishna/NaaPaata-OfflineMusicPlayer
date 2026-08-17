//
//  PlaylistsViewModel.swift
//  NaaPaata
//

import SwiftUI
import SwiftData
import AVFoundation

@MainActor
final class PlaylistsViewModel: ObservableObject {
    private let dataService: DataServiceProtocol

    @Published var playlists: [Playlist] = []
    @Published var isLoading: Bool = false

    init(dataService: DataServiceProtocol) {
        self.dataService = dataService
    }

    // MARK: - Load
    func loadPlaylists() {
        playlists = dataService.fetchPlaylists()
    }

    // MARK: - Create
    func createPlaylist(name: String, description: String = "", coverImage: UIImage? = nil) {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        let existing = dataService.fetchPlaylists()
        var uniqueName = trimmedName
        var counter = 1
        while existing.contains(where: { $0.name == uniqueName }) {
            uniqueName = "\(trimmedName) (\(counter))"
            counter += 1
        }
        let playlist = Playlist(name: uniqueName, coverImage: coverImage, desc: description, dateCreated: Date())
        dataService.savePlaylist(playlist)
        loadPlaylists()
    }

    // MARK: - Delete
    func deletePlaylist(_ playlist: Playlist) {
        dataService.deletePlaylist(playlist)
        loadPlaylists()
    }

    // MARK: - Update
    func updatePlaylist(_ playlist: Playlist) {
        dataService.savePlaylist(playlist)
        loadPlaylists()
    }

    // MARK: - Add Song to Playlist
    func addSongToPlaylist(_ song: Song, to playlist: Playlist) {
        let result = dataService.addSongToPlaylist(song, playlist: playlist)
        switch result {
        case .added:
            ToastManager.shared.showToast(message: "Song added to \(playlist.name)")
        case .exists:
            ToastManager.shared.showToast(message: "Song already exists in playlist")
        case .error(let msg):
            print("Error: \(msg)")
        }
        loadPlaylists()
    }

    // MARK: - Remove Song from Playlist
    func removeSongFromPlaylist(_ song: Song, from playlist: Playlist) {
        dataService.removeSongFromPlaylist(song, from: playlist)
        loadPlaylists()
    }

    // MARK: - Batch Add
    @discardableResult
    func addSongToPlaylists(_ song: Song, playlistIDs: Set<UUID>) -> [UUID: AddSongResult] {
        let results = dataService.addSongToPlaylists(song, playlistIDs: playlistIDs)
        loadPlaylists()
        return results
    }

    // MARK: - Batch Remove
    func removeSongFromPlaylists(_ song: Song, playlistIDs: Set<UUID>) {
        dataService.removeSongFromPlaylists(song, playlistIDs: playlistIDs)
        loadPlaylists()
    }

    // MARK: - Queries
    func getSongs(for playlist: Playlist) -> [Song] {
        return dataService.getSongs(for: playlist)
    }

    func getPlaylist(id: UUID) -> Playlist? {
        return dataService.fetchPlaylist(byId: id)
    }

    func getAllPlaylists() -> [Playlist] {
        return dataService.fetchPlaylists()
    }

    func loadPlaylist(name: String) -> Playlist? {
        return dataService.fetchPlaylist(byName: name)
    }

    // MARK: - Convenience
    func addPlaylist(name: String, description: String = "", coverImage: UIImage? = nil) {
        createPlaylist(name: name, description: description, coverImage: coverImage)
    }
}
