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
        return ModelContext(container)
    }
    
    // MARK: - Create Playlist
    func createPlaylist(name: String) {
        let playlist = Playlist(name: name, songs: [], desc: "", dateCreated: Date())
        savePlaylist(playlist)
    }
    
    // MARK: - Save Playlist
    func savePlaylist(_ playlist: Playlist) {
        let context = modelContext
        do {
            let id = playlist.id
            let existing = try context.fetch(FetchDescriptor<Playlist>(
                predicate: #Predicate { $0.id == id }
            )).first
            if let existing = existing {
                existing.name = playlist.name
                existing.songs = playlist.songs
                existing.coverImageData = playlist.coverImageData
                existing.desc = playlist.desc
            } else {
                context.insert(playlist)
            }
            try context.save()
            NotificationCenter.default.post(name: .playlistUpdated, object: nil, userInfo: ["playlistId": playlist.id.uuidString])
        } catch {
            print("Error saving playlist \(playlist.name): \(error.localizedDescription)")
        }
    }
    
    // MARK: - Load All Playlists
    func getAllPlaylists() -> [Playlist] {
        let context = modelContext
        do {
            let descriptor = FetchDescriptor<Playlist>(sortBy: [SortDescriptor(\.dateCreated, order: .reverse)])
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
    
    // MARK: - Get Songs in Playlist (Concurrent)
    func getSongsInPlaylist(playlistName: String) async -> [Song] {
        guard let playlist = loadPlaylist(name: playlistName) else { return [] }
        return await loadPlaylistSongsConcurrently(playlist.songs)
    }
    
    // MARK: - Load Playlist Songs Concurrently (validates file existence)
    private func loadPlaylistSongsConcurrently(_ songs: [Song]) async -> [Song] {
        guard !songs.isEmpty else { return [] }
        return await withTaskGroup(of: Song?.self) { group in
            for song in songs {
                group.addTask {
                    if let url = song.resolvedURL,
                       FileManager.default.fileExists(atPath: url.path) {
                        return song
                    }
                    return nil
                }
            }
            var validSongs: [Song] = []
            for await song in group {
                if let song = song {
                    validSongs.append(song)
                }
            }
            return validSongs
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
    
    // MARK: - Add Song to Playlist (using relativePath)
    @discardableResult
    func addSongToPlaylist(_ song: Song, playlist: Playlist) -> AddSongResult {
        let context = modelContext
        do {
            let playlistId = playlist.id
            guard let currentPlaylist = try context.fetch(FetchDescriptor<Playlist>(
                predicate: #Predicate { $0.id == playlistId }
            )).first else { return .error("Playlist not found") }
            
            let relPath = song.relativePath
            var managedSong: Song? = try context.fetch(FetchDescriptor<Song>(
                predicate: #Predicate { $0.relativePath == relPath }
            )).first
            
            if managedSong == nil {
                context.insert(song)
                managedSong = song
                try context.save()
            }
            
            guard let finalSong = managedSong else {
                return .error("Failed to retrieve or insert song")
            }
            
            if !currentPlaylist.songs.contains(where: { $0.relativePath == relPath }) {
                currentPlaylist.songs.append(finalSong)
                try context.save()
                NotificationCenter.default.post(name: .playlistUpdated, object: nil, userInfo: ["playlistId": playlistId.uuidString])
                return .added
            } else {
                return .exists
            }
        } catch {
            print("Error adding song to playlist: \(error.localizedDescription)")
            return .error(error.localizedDescription)
        }
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
            currentPlaylist.songs.removeAll { $0.relativePath == relPath }
            try context.save()
            NotificationCenter.default.post(name: .playlistUpdated, object: nil, userInfo: ["playlistId": playlistId.uuidString])
        } catch {
            print("Error removing song from playlist: \(error.localizedDescription)")
        }
    }
}

extension Notification.Name {
    static let playlistUpdated = Notification.Name("playlistUpdated")
}
