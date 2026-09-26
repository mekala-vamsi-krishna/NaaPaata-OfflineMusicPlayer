//
//  PlaylistService.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/16/26.
//

import Foundation
import SwiftData

/// All playlist write operations. Reads are handled by `@Query` in views.
///
/// A `ModelContext` is passed per instance because SwiftData provides it
/// through the environment — there is no long-lived store to hold onto.
struct PlaylistService {

    let context: ModelContext

    // MARK: - Create

    @discardableResult
    func createPlaylist(
        name: String,
        description: String,
        artworkData: Data?,
        songURLs: [URL] = []
    ) throws -> Playlist {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let playlist = Playlist(
            name: trimmed,
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            artworkData: artworkData,
            songPaths: songURLs.map(\.path)
        )
        context.insert(playlist)
        try context.save()
        return playlist
    }

    // MARK: - Delete

    func delete(_ playlist: Playlist) throws {
        context.delete(playlist)
        try context.save()
    }

    // MARK: - Add songs

    /// Adds `urls` to each playlist in `playlists`. Duplicates are skipped.
    func addSongs(_ urls: [URL], to playlists: [Playlist]) throws {
        let paths = urls.map(\.path)
        for playlist in playlists {
            for path in paths where !playlist.songPaths.contains(path) {
                playlist.songPaths.append(path)
            }
        }
        try context.save()
    }

    // MARK: - Remove song

    func removeSong(_ url: URL, from playlist: Playlist) throws {
        let path = url.path
        playlist.songPaths.removeAll { $0 == path }
        try context.save()
    }
}
