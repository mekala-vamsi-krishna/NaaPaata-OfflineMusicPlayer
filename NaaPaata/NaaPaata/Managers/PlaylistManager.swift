//
//  PlaylistManager.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 05/10/25.
//

import Foundation
import SwiftUI
import SwiftData

enum AddSongResult: Equatable {
    case added
    case exists
    case error(String)
}

@MainActor
final class PlaylistManager {
    static let shared = PlaylistManager()
    private var sharedModelContainer: ModelContainer?
    private init() {}

    func setModelContainer(_ container: ModelContainer) {
        self.sharedModelContainer = container
    }

    private var modelContext: ModelContext {
        guard let container = sharedModelContainer else {
            fatalError("ModelContainer not set in PlaylistManager")
        }
        return container.mainContext
    }

    // MARK: - Save Playlist (metadata only — never touches songPaths)
    func savePlaylist(_ playlist: Playlist) {
        let context = modelContext
        do {
            let id = playlist.id
            let existing = try context.fetch(FetchDescriptor<Playlist>(
                predicate: #Predicate { $0.id == id }
            )).first
            if let existing = existing {
                existing.name = playlist.name
                existing.coverImageData = playlist.coverImageData
                existing.desc = playlist.desc
                // NOTE: intentionally NOT copying songPaths — song membership is managed separately
            } else {
                context.insert(playlist)
            }
            try context.save()
            NotificationCenter.default.post(name: .playlistUpdated, object: nil,
                                            userInfo: ["playlistId": playlist.id.uuidString])
        } catch {
            print("Error saving playlist \(playlist.name): \(error.localizedDescription)")
        }
    }

    // MARK: - Load All Playlists
    func getAllPlaylists() -> [Playlist] {
        let context = modelContext
        do {
            let descriptor = FetchDescriptor<Playlist>(
                sortBy: [SortDescriptor(\.dateCreated, order: .reverse)]
            )
            return try context.fetch(descriptor)
        } catch {
            print("Error fetching playlists: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Get Playlist By Name
    func loadPlaylist(name: String) -> Playlist? {
        let context = modelContext
        do {
            let descriptor = FetchDescriptor<Playlist>(predicate: #Predicate { $0.name == name })
            return try context.fetch(descriptor).first
        } catch {
            print("Error loading playlist \(name): \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Get Playlist By ID
    func getPlaylist(id: UUID) -> Playlist? {
        let context = modelContext
        do {
            let idValue = id
            let descriptor = FetchDescriptor<Playlist>(predicate: #Predicate { $0.id == idValue })
            return try context.fetch(descriptor).first
        } catch {
            print("Error loading playlist with id \(id): \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Resolve Songs for a Playlist
    /// Returns Song objects for all paths stored in the playlist.
    /// Songs that no longer exist on disk are filtered out automatically.
    func getSongs(for playlist: Playlist) -> [Song] {
        let context = modelContext
        let paths = playlist.songPaths
        guard !paths.isEmpty else { return [] }
        var songs: [Song] = []
        for path in paths {
            let p = path
            if let song = try? context.fetch(FetchDescriptor<Song>(
                predicate: #Predicate { $0.relativePath == p }
            )).first {
                // Only include songs whose file still exists on disk
                if let url = song.resolvedURL, FileManager.default.fileExists(atPath: url.path) {
                    songs.append(song)
                }
            }
        }
        return songs
    }

    // MARK: - Ensure Song is persisted in SwiftData (insert if missing)
    @discardableResult
    private func ensureSongPersisted(_ song: Song) -> Song {
        let context = modelContext
        let relPath = song.relativePath
        if let existing = try? context.fetch(FetchDescriptor<Song>(
            predicate: #Predicate { $0.relativePath == relPath }
        )).first {
            return existing
        }
        context.insert(song)
        try? context.save()
        return song
    }

    // MARK: - Add Song to Playlist
    @discardableResult
    func addSongToPlaylist(_ song: Song, playlist: Playlist) -> AddSongResult {
        let context = modelContext
        do {
            let playlistId = playlist.id
            guard let currentPlaylist = try context.fetch(FetchDescriptor<Playlist>(
                predicate: #Predicate { $0.id == playlistId }
            )).first else { return .error("Playlist not found") }

            let relPath = song.relativePath

            // Ensure the Song object itself is persisted
            ensureSongPersisted(song)

            if !currentPlaylist.songPaths.contains(relPath) {
                currentPlaylist.songPaths.append(relPath)
                try context.save()
                NotificationCenter.default.post(name: .playlistUpdated, object: nil,
                                                userInfo: ["playlistId": playlistId.uuidString])
                return .added
            } else {
                return .exists
            }
        } catch {
            print("Error adding song to playlist: \(error.localizedDescription)")
            return .error(error.localizedDescription)
        }
    }

    // MARK: - Add Song to Multiple Playlists (atomic, single save)
    @discardableResult
    func addSongToPlaylists(_ song: Song, playlistIDs: Set<UUID>) -> [UUID: AddSongResult] {
        guard !playlistIDs.isEmpty else { return [:] }
        let context = modelContext
        var results: [UUID: AddSongResult] = [:]

        do {
            let relPath = song.relativePath

            // Ensure the Song object is persisted once
            ensureSongPersisted(song)

            // Update each playlist's songPaths array
            for id in playlistIDs {
                let pid = id
                if let playlist = try context.fetch(FetchDescriptor<Playlist>(
                    predicate: #Predicate { $0.id == pid }
                )).first {
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

            // Single save for all mutations
            try context.save()

            for id in playlistIDs {
                NotificationCenter.default.post(name: .playlistUpdated, object: nil,
                                                userInfo: ["playlistId": id.uuidString])
            }
        } catch {
            print("Error in addSongToPlaylists: \(error.localizedDescription)")
            for id in playlistIDs where results[id] == nil {
                results[id] = .error(error.localizedDescription)
            }
        }
        return results
    }

    // MARK: - Remove Song from Playlist
    func removeSongFromPlaylist(_ song: Song, from playlist: Playlist) {
        let context = modelContext
        do {
            let playlistId = playlist.id
            guard let currentPlaylist = try context.fetch(FetchDescriptor<Playlist>(
                predicate: #Predicate { $0.id == playlistId }
            )).first else { return }
            let relPath = song.relativePath
            currentPlaylist.songPaths.removeAll { $0 == relPath }
            try context.save()
            NotificationCenter.default.post(name: .playlistUpdated, object: nil,
                                            userInfo: ["playlistId": playlistId.uuidString])
        } catch {
            print("Error removing song from playlist: \(error.localizedDescription)")
        }
    }

    // MARK: - Remove Song from Multiple Playlists
    func removeSongFromPlaylists(_ song: Song, playlistIDs: Set<UUID>) {
        guard !playlistIDs.isEmpty else { return }
        let context = modelContext
        do {
            let relPath = song.relativePath
            for id in playlistIDs {
                let pid = id
                if let playlist = try context.fetch(FetchDescriptor<Playlist>(
                    predicate: #Predicate { $0.id == pid }
                )).first {
                    playlist.songPaths.removeAll { $0 == relPath }
                }
            }
            try context.save()
            for id in playlistIDs {
                NotificationCenter.default.post(name: .playlistUpdated, object: nil,
                                                userInfo: ["playlistId": id.uuidString])
            }
        } catch {
            print("Error in removeSongFromPlaylists: \(error.localizedDescription)")
        }
    }

    // MARK: - Delete Playlist
    func deletePlaylist(name: String) {
        let context = modelContext
        do {
            guard let playlist = try context.fetch(FetchDescriptor<Playlist>(
                predicate: #Predicate { $0.name == name }
            )).first else { return }
            context.delete(playlist)
            try context.save()
        } catch {
            print("Error deleting playlist \(name): \(error.localizedDescription)")
        }
    }

    func deletePlaylistById(id: UUID) {
        let context = modelContext
        do {
            let idValue = id
            guard let playlist = try context.fetch(FetchDescriptor<Playlist>(
                predicate: #Predicate { $0.id == idValue }
            )).first else { return }
            context.delete(playlist)
            try context.save()
        } catch {
            print("Error deleting playlist with id \(id): \(error.localizedDescription)")
        }
    }
}

extension Notification.Name {
    static let playlistUpdated = Notification.Name("playlistUpdated")
}
