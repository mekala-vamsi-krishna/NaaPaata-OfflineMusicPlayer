//
//  PlaylistService.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 9/27/26.
//

import Foundation
import SwiftData

@MainActor
struct PlaylistService {

    let context: ModelContext

    // MARK: - Create

    @discardableResult
    func create(
        name: String,
        description: String,
        coverImageData: Data?,
        songRelativePaths: [String] = []
    ) throws -> Playlist {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw PlaylistError.emptyName
        }

        let playlist = Playlist(
            name: trimmed,
            desc: description.trimmingCharacters(in: .whitespacesAndNewlines),
            coverImageData: coverImageData,
            songRelativePaths: songRelativePaths
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

    // MARK: - Metadata

    func updateName(_ name: String, for playlist: Playlist) throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw PlaylistError.emptyName }
        playlist.name = trimmed
        try context.save()
    }

    func updateDescription(_ description: String, for playlist: Playlist) throws {
        playlist.desc = description
        try context.save()
    }

    func updateCover(_ data: Data?, for playlist: Playlist) throws {
        playlist.coverImageData = data
        try context.save()
    }

    // MARK: - Songs

    /// Adds a song (by relative path). No-op if already present.
    @discardableResult
    func addSong(relativePath: String, to playlist: Playlist) throws -> AddSongResult {
        if playlist.songRelativePaths.contains(relativePath) {
            return .exists
        }
        playlist.songRelativePaths.append(relativePath)
        try context.save()
        return .added
    }

    /// Batch add. Skips duplicates. Returns a per-playlist result.
    @discardableResult
    func addSong(relativePath: String, to playlists: [Playlist]) throws -> [UUID: AddSongResult] {
        var results: [UUID: AddSongResult] = [:]
        for playlist in playlists {
            if playlist.songRelativePaths.contains(relativePath) {
                results[playlist.id] = .exists
            } else {
                playlist.songRelativePaths.append(relativePath)
                results[playlist.id] = .added
            }
        }
        try context.save()
        return results
    }

    func removeSong(relativePath: String, from playlist: Playlist) throws {
        playlist.songRelativePaths.removeAll { $0 == relativePath }
        try context.save()
    }
}

enum PlaylistError: LocalizedError {
    case emptyName

    var errorDescription: String? {
        switch self {
        case .emptyName: return "Playlist name can't be empty."
        }
    }
}

enum AddSongResult: Equatable {
    case added
    case exists
    case error(String)
}
