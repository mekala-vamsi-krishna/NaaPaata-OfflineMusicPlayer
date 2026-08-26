//
//  DataServiceProtocol.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 8/17/26.
//
import Foundation
import SwiftData
import UIKit

protocol DataServiceProtocol {
    // MARK: - Songs
    func fetchSongs() -> [Song]
    func fetchSong(byId id: UUID) -> Song?
    func fetchSong(byRelativePath path: String) -> Song?
    func saveSong(_ song: Song)
    func deleteSong(_ song: Song)
    func deleteSongs(_ songs: [Song])

    // MARK: - Playlists
    func fetchPlaylists() -> [Playlist]
    func fetchPlaylist(byId id: UUID) -> Playlist?
    func fetchPlaylist(byName name: String) -> Playlist?
    func savePlaylist(_ playlist: Playlist)
    func deletePlaylist(_ playlist: Playlist)
    func deletePlaylist(byId id: UUID)

    // MARK: - Playlist ↔ Song Relationship (using relative paths)
    func addSongToPlaylist(_ song: Song, playlist: Playlist) -> AddSongResult
    func addSongToPlaylists(_ song: Song, playlistIDs: Set<UUID>) -> [UUID: AddSongResult]
    func removeSongFromPlaylist(_ song: Song, from playlist: Playlist)
    func removeSongFromPlaylists(_ song: Song, playlistIDs: Set<UUID>)
    func getSongs(for playlist: Playlist) -> [Song]
    func isSongInPlaylist(_ song: Song, playlist: Playlist) -> Bool
}

enum AddSongResult: Equatable {
    case added
    case exists
    case error(String)
}

import Foundation
import SwiftData
import UIKit

final class DataService: DataServiceProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Songs
    func fetchSongs() -> [Song] {
        let descriptor = FetchDescriptor<Song>(sortBy: [SortDescriptor(\.title)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchSong(byId id: UUID) -> Song? {
        let descriptor = FetchDescriptor<Song>(predicate: #Predicate { $0.id == id })
        return try? modelContext.fetch(descriptor).first
    }

    func fetchSong(byRelativePath path: String) -> Song? {
        let descriptor = FetchDescriptor<Song>(predicate: #Predicate { $0.relativePath == path })
        return try? modelContext.fetch(descriptor).first
    }

    func saveSong(_ song: Song) {
        if let existing = fetchSong(byRelativePath: song.relativePath) {
            existing.title = song.title
            existing.artist = song.artist
            existing.album = song.album
            existing.duration = song.duration
            existing.artworkData = song.artworkData
            existing.dateAdded = song.dateAdded
            existing.urlString = song.urlString
            existing.bookmarkData = song.bookmarkData
        } else {
            modelContext.insert(song)
        }
        try? modelContext.save()
    }

    func deleteSong(_ song: Song) {
        modelContext.delete(song)
        try? modelContext.save()
    }

    func deleteSongs(_ songs: [Song]) {
        for song in songs {
            modelContext.delete(song)
        }
        try? modelContext.save()
    }

    // MARK: - Playlists
    func fetchPlaylists() -> [Playlist] {
        let descriptor = FetchDescriptor<Playlist>(sortBy: [SortDescriptor(\.dateCreated, order: .reverse)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchPlaylist(byId id: UUID) -> Playlist? {
        let descriptor = FetchDescriptor<Playlist>(predicate: #Predicate { $0.id == id })
        return try? modelContext.fetch(descriptor).first
    }

    func fetchPlaylist(byName name: String) -> Playlist? {
        let descriptor = FetchDescriptor<Playlist>(predicate: #Predicate { $0.name == name })
        return try? modelContext.fetch(descriptor).first
    }

    func savePlaylist(_ playlist: Playlist) {
        if let existing = fetchPlaylist(byId: playlist.id) {
            existing.name = playlist.name
            existing.coverImageData = playlist.coverImageData
            existing.desc = playlist.desc
            // songPaths are managed separately by the relationship methods
        } else {
            modelContext.insert(playlist)
        }
        try? modelContext.save()
    }

    func deletePlaylist(_ playlist: Playlist) {
        modelContext.delete(playlist)
        try? modelContext.save()
    }

    func deletePlaylist(byId id: UUID) {
        guard let playlist = fetchPlaylist(byId: id) else { return }
        deletePlaylist(playlist)
    }

    // MARK: - Playlist ↔ Song Relationship
    func addSongToPlaylist(_ song: Song, playlist: Playlist) -> AddSongResult {
        guard let currentPlaylist = fetchPlaylist(byId: playlist.id) else {
            return .error("Playlist not found")
        }
        ensureSongPersisted(song)
        let relPath = song.relativePath
        if !currentPlaylist.songPaths.contains(relPath) {
            currentPlaylist.songPaths.append(relPath)
            try? modelContext.save()
            notifyPlaylistUpdated(playlistId: playlist.id)
            return .added
        }
        return .exists
    }

    func addSongToPlaylists(_ song: Song, playlistIDs: Set<UUID>) -> [UUID: AddSongResult] {
        guard !playlistIDs.isEmpty else { return [:] }
        var results: [UUID: AddSongResult] = [:]
        let relPath = song.relativePath
        ensureSongPersisted(song)

        for id in playlistIDs {
            if let playlist = fetchPlaylist(byId: id) {
                if !playlist.songPaths.contains(relPath) {
                    playlist.songPaths.append(relPath)
                    results[id] = .added
                } else {
                    results[id] = .exists
                }
            } else {
                results[id] = .error("Playlist not found")
            }
        }
        try? modelContext.save()
        for id in playlistIDs {
            notifyPlaylistUpdated(playlistId: id)
        }
        return results
    }

    func removeSongFromPlaylist(_ song: Song, from playlist: Playlist) {
        guard let currentPlaylist = fetchPlaylist(byId: playlist.id) else { return }
        currentPlaylist.songPaths.removeAll { $0 == song.relativePath }
        try? modelContext.save()
        notifyPlaylistUpdated(playlistId: playlist.id)
    }

    func removeSongFromPlaylists(_ song: Song, playlistIDs: Set<UUID>) {
        guard !playlistIDs.isEmpty else { return }
        let relPath = song.relativePath
        for id in playlistIDs {
            if let playlist = fetchPlaylist(byId: id) {
                playlist.songPaths.removeAll { $0 == relPath }
            }
        }
        try? modelContext.save()
        for id in playlistIDs {
            notifyPlaylistUpdated(playlistId: id)
        }
    }

    func getSongs(for playlist: Playlist) -> [Song] {
        let paths = playlist.songPaths
        guard !paths.isEmpty else { return [] }
        var songs: [Song] = []
        for path in paths {
            if let song = fetchSong(byRelativePath: path),
               let url = song.resolvedURL,
               FileManager.default.fileExists(atPath: url.path) {
                songs.append(song)
            }
        }
        return songs
    }

    func isSongInPlaylist(_ song: Song, playlist: Playlist) -> Bool {
        return playlist.songPaths.contains(song.relativePath)
    }

    // MARK: - Private Helpers
    private func ensureSongPersisted(_ song: Song) {
        if fetchSong(byRelativePath: song.relativePath) == nil {
            modelContext.insert(song)
            try? modelContext.save()
        }
    }

    private func notifyPlaylistUpdated(playlistId: UUID) {
        NotificationCenter.default.post(
            name: .playlistUpdated,
            object: nil,
            userInfo: ["playlistId": playlistId.uuidString]
        )
    }
}

extension Notification.Name {
    static let playlistUpdated = Notification.Name("playlistUpdated")
}
