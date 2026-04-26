//
//  PlaylistViewModel.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 06/10/25.
//

import SwiftUI
import SwiftData
import AVFoundation

final class PlaylistsViewModel: ObservableObject {
    let playlistManager = PlaylistManager.shared
    
    @Published var isLoading: Bool = false
    
    init() {}
    
    // MARK: - Playlist Management
    
    func addPlaylist(name: String, description: String = "", coverImage: UIImage? = nil, playlists: [Playlist] = []) {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        let currentPlaylists = playlists.isEmpty ? playlistManager.getAllPlaylists() : playlists
        
        var uniqueName = trimmedName
        var counter = 1
        while currentPlaylists.contains(where: { $0.name == uniqueName }) {
            uniqueName = "\(trimmedName) (\(counter))"
            counter += 1
        }
        
        let newPlaylist = Playlist(
            name: uniqueName,
            songs: [],
            coverImage: coverImage,   // 👈 use passed image
            desc: description,
            dateCreated: Date()
        )
        
        playlistManager.savePlaylist(newPlaylist)
    }
    
    func deletePlaylist(_ playlist: Playlist) {
        playlistManager.deletePlaylistById(id: playlist.id)
    }
    
    func updatePlaylist(_ playlist: Playlist) {
        playlistManager.savePlaylist(playlist)
    }
    
    func renamePlaylist(_ playlist: Playlist, newName: String) {
        let trimmedName = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty, trimmedName != playlist.name else { return }
        
        playlist.name = trimmedName
        playlistManager.savePlaylist(playlist)
    }
    
    // MARK: - Song Management in Playlist
    
    func addSongToPlaylist(_ song: Song, to playlist: Playlist) {
        playlistManager.addSongToPlaylist(song, playlist: playlist)
    }
    
    func removeSongFromPlaylist(_ song: Song, from playlist: Playlist) {
        playlistManager.removeSongFromPlaylist(song, from: playlist)
    }
    
    // MARK: - Load All Playlists with Songs Concurrently
    func loadAllPlaylistsConcurrently() async -> [Playlist] {
        let playlists = playlistManager.getAllPlaylists()
        
        return await withTaskGroup(of: Playlist?.self) { group in
            for playlist in playlists {
                group.addTask {
                    let validSongs = await self.playlistManager.getSongsInPlaylist(playlistName: playlist.name)
                    return Playlist(
                        id: playlist.id,
                        name: playlist.name,
                        songs: validSongs,
                        coverImage: playlist.coverImage,
                        desc: playlist.desc,
                        dateCreated: playlist.dateCreated
                    )
                }
            }
            
            var loadedPlaylists: [Playlist] = []
            for await playlist in group {
                if let playlist = playlist {
                    loadedPlaylists.append(playlist)
                }
            }
            return loadedPlaylists.sorted { $0.dateCreated > $1.dateCreated }
        }
    }
}

