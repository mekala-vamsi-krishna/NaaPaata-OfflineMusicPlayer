//
//  PlaylistManager.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 05/10/25.
//

import Foundation
import SwiftUI
import SwiftData


final class PlaylistManager {
    static let shared = PlaylistManager()
    private var sharedModelContainer: ModelContainer?
    
    private init() {}
    
    /// Set up the shared model container (call from NaaPaataApp.init())
    func setModelContainer(_ container: ModelContainer) {
        self.sharedModelContainer = container
    }
    
    private var modelContext: ModelContext {
        guard let container = sharedModelContainer else {
            fatalError("ModelContainer not set in PlaylistManager. Call setModelContainer() first.")
        }
        return ModelContext(container)
    }
    
    // MARK: - Create Playlist
    func createPlaylist(name: String) {
        let playlist = Playlist(
            name: name,
            songs: [],
            desc: "",
            dateCreated: Date()
        )
        savePlaylist(playlist)
    }
    
    // MARK: - Save Playlist
    func savePlaylist(_ playlist: Playlist) {
        let context = modelContext
        do {
            let id = playlist.id
            // Check if playlist already exists by ID
            let existingPlaylist = try context.fetch(
                FetchDescriptor<Playlist>(
                    predicate: #Predicate { $0.id == id }
                )
            ).first
            
            if existingPlaylist != nil {
                // Update existing playlist
                existingPlaylist?.name = playlist.name
                existingPlaylist?.songs = playlist.songs
                existingPlaylist?.coverImageData = playlist.coverImageData
                existingPlaylist?.desc = playlist.desc
            } else {
                // Insert new playlist
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
            let descriptor = FetchDescriptor<Playlist>(
                predicate: #Predicate { $0.name == name }
            )
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
            let descriptor = FetchDescriptor<Playlist>(
                predicate: #Predicate { $0.id == idValue }
            )
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
    
    // MARK: - Load Playlist Songs Concurrently
    private func loadPlaylistSongsConcurrently(_ songs: [Song]) async -> [Song] {
        guard !songs.isEmpty else { return [] }
        
        return await withTaskGroup(of: Song?.self) { group in
            for song in songs {
                group.addTask {
                    // Validate that the song file still exists
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
            guard let playlist = try context.fetch(
                FetchDescriptor<Playlist>(
                    predicate: #Predicate { $0.name == name }
                )
            ).first else { return }
            
            context.delete(playlist)
            try context.save()
        } catch {
            print("Error deleting playlist \(name): \(error.localizedDescription)")
        }
    }
    
    // MARK: - Delete Playlist By ID
    func deletePlaylistById(id: UUID) {
        let context = modelContext
        do {
            let idValue = id
            guard let playlist = try context.fetch(
                FetchDescriptor<Playlist>(
                    predicate: #Predicate { $0.id == idValue }
                )
            ).first else { return }
            
            context.delete(playlist)
            try context.save()
        } catch {
            print("Error deleting playlist with id \(id): \(error.localizedDescription)")
        }
    }
    
    // MARK: - Add Song to Playlist
    func addSongToPlaylist(_ song: Song, playlist: Playlist) {
        let context = modelContext
        do {
            let playlistId = playlist.id
            // Fetch fresh playlist reference
            guard let currentPlaylist = try context.fetch(
                FetchDescriptor<Playlist>(
                    predicate: #Predicate { $0.id == playlistId }
                )
            ).first else { return }
            
            // Check if song already exists
            if !currentPlaylist.songs.contains(where: { $0.id == song.id }) {
                currentPlaylist.songs.append(song)
                try context.save()
                NotificationCenter.default.post(name: .playlistUpdated, object: nil, userInfo: ["playlistId": playlistId.uuidString])
            }
        } catch {
            print("Error adding song to playlist: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Remove Song from Playlist
    func removeSongFromPlaylist(_ song: Song, from playlist: Playlist) {
        let context = modelContext
        do {
            let playlistId = playlist.id
            // Fetch fresh playlist reference
            guard let currentPlaylist = try context.fetch(
                FetchDescriptor<Playlist>(
                    predicate: #Predicate { $0.id == playlistId }
                )
            ).first else { return }
            
            // Remove song from playlist (but don't delete the song itself)
            currentPlaylist.songs.removeAll { $0.id == song.id }
            try context.save()
            NotificationCenter.default.post(name: .playlistUpdated, object: nil, userInfo: ["playlistId": playlistId.uuidString])
        } catch {
            print("Error removing song from playlist: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Get or Create Favorites Playlist
    func getOrCreateFavoritesPlaylist() -> Playlist {
        let context = modelContext
        
        do {
            if let favPlaylist = try context.fetch(
                FetchDescriptor<Playlist>(
                    predicate: #Predicate { $0.name == "Favorites" }
                )
            ).first {
                return favPlaylist
            }
            
            // Create new Favorites playlist
            let favPlaylist = Playlist(
                name: "Favorites",
                songs: [],
                coverImage: UIImage(named: "Favorites"),
                desc: "Your favorite songs",
                dateCreated: Date()
            )
            context.insert(favPlaylist)
            try context.save()
            return favPlaylist
        } catch {
            print("Error getting/creating favorites playlist: \(error.localizedDescription)")
            return Playlist(
                name: "Favorites",
                songs: [],
                desc: "Your favorite songs"
            )
        }
    }
    
    // MARK: - Toggle Song Favorite (Async)
    func toggleFavoriteSong(_ song: Song) async -> Bool {
        await Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return false }
            let context = ModelContext(self.sharedModelContainer!)
            do {
                let favPlaylist = self.getOrCreateFavoritesPlaylist(in: context)
                
                if let index = favPlaylist.songs.firstIndex(where: { $0.id == song.id }) {
                    // Remove from favorites
                    favPlaylist.songs.remove(at: index)
                    try context.save()
                    return false
                } else {
                    // Add to favorites
                    favPlaylist.songs.append(song)
                    try context.save()
                    return true
                }
            } catch {
                print("Error toggling favorite: \(error.localizedDescription)")
                return false
            }
        }.value
    }
    
    // MARK: - Get or Create Favorites Playlist (with context)
    private func getOrCreateFavoritesPlaylist(in context: ModelContext) -> Playlist {
        do {
            if let favPlaylist = try context.fetch(
                FetchDescriptor<Playlist>(
                    predicate: #Predicate { $0.name == "Favorites" }
                )
            ).first {
                return favPlaylist
            }
            
            // Create new Favorites playlist
            let favPlaylist = Playlist(
                name: "Favorites",
                songs: [],
                coverImage: UIImage(named: "Favorites"),
                desc: "Your favorite songs",
                dateCreated: Date()
            )
            context.insert(favPlaylist)
            try context.save()
            return favPlaylist
        } catch {
            print("Error getting/creating favorites playlist: \(error.localizedDescription)")
            return Playlist(
                name: "Favorites",
                songs: [],
                desc: "Your favorite songs"
            )
        }
    }
    
    // MARK: - Check if Song is Favorite
    func isSongFavorite(_ song: Song) -> Bool {
        let context = modelContext
        do {
            let favPlaylist = getOrCreateFavoritesPlaylist(in: context)
            return favPlaylist.songs.contains(where: { $0.id == song.id })
        } catch {
            print("Error checking favorite status: \(error.localizedDescription)")
            return false
        }
    }
}

extension Notification.Name {
    static let playlistUpdated = Notification.Name("playlistUpdated")
}

