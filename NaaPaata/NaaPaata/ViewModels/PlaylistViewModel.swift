//
//  PlaylistViewModel.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 06/10/25.
//

import SwiftUI
import SwiftData
import AVFoundation

@MainActor
final class PlaylistsViewModel: ObservableObject {
    private let playlistManager = PlaylistManager.shared
    @Published var isLoading: Bool = false

    init() {}

    // MARK: - addPlaylist (called from PlayListsView — delegates to createPlaylist)
    func addPlaylist(name: String, description: String = "", coverImage: UIImage? = nil, playlists: [Playlist] = []) {
        createPlaylist(name: name, description: description, coverImage: coverImage)
    }

    // MARK: - createPlaylist (with unique name deduplication)
    func createPlaylist(name: String, description: String = "", coverImage: UIImage? = nil) {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        let existing = playlistManager.getAllPlaylists()
        var uniqueName = trimmedName
        var counter = 1
        while existing.contains(where: { $0.name == uniqueName }) {
            uniqueName = "\(trimmedName) (\(counter))"
            counter += 1
        }
        let playlist = Playlist(name: uniqueName, coverImage: coverImage, desc: description, dateCreated: Date())
        playlistManager.savePlaylist(playlist)
    }

    // MARK: - deletePlaylist
    func deletePlaylist(_ playlist: Playlist) {
        playlistManager.deletePlaylistById(id: playlist.id)
    }

    // MARK: - updatePlaylist
    func updatePlaylist(_ playlist: Playlist) {
        playlistManager.savePlaylist(playlist)
    }

    // MARK: - addSongToPlaylist
    func addSongToPlaylist(_ song: Song, to playlist: Playlist) {
        let result = playlistManager.addSongToPlaylist(song, playlist: playlist)
        switch result {
        case .added:
            ToastManager.shared.showToast(message: "Song added to \(playlist.name) playlist")
        case .exists:
            ToastManager.shared.showToast(message: "Song already exists in playlist")
        case .error(let msg):
            print("Error: \(msg)")
        }
    }

    // MARK: - removeSongFromPlaylist
    func removeSongFromPlaylist(_ song: Song, from playlist: Playlist) {
        playlistManager.removeSongFromPlaylist(song, from: playlist)
    }

    // MARK: - addSongToPlaylists (batch, for multi-playlist selection)
    @discardableResult
    func addSongToPlaylists(_ song: Song, playlistIDs: Set<UUID>) -> [UUID: AddSongResult] {
        return playlistManager.addSongToPlaylists(song, playlistIDs: playlistIDs)
    }

    // MARK: - removeSongFromPlaylists (batch)
    func removeSongFromPlaylists(_ song: Song, playlistIDs: Set<UUID>) {
        playlistManager.removeSongFromPlaylists(song, playlistIDs: playlistIDs)
    }

    // MARK: - getSongs(for:)
    func getSongs(for playlist: Playlist) -> [Song] {
        return playlistManager.getSongs(for: playlist)
    }

    // MARK: - getPlaylist(id:)
    func getPlaylist(id: UUID) -> Playlist? {
        return playlistManager.getPlaylist(id: id)
    }

    // MARK: - getAllPlaylists
    func getAllPlaylists() -> [Playlist] {
        return playlistManager.getAllPlaylists()
    }

    // MARK: - loadPlaylist(name:)
    func loadPlaylist(name: String) -> Playlist? {
        return playlistManager.loadPlaylist(name: name)
    }
}
