//
//  SmartPlaylistService.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/9/26.
//

import Foundation
import SwiftData

@MainActor
struct SmartPlaylistService {

    let context: ModelContext
    let folderService: DocumentFolderService

    // MARK: - Public

    func allSmartPlaylists(from library: [Song]) -> [SmartPlaylist] {
        SmartPlaylistKind.allCases.compactMap { kind in
            let songs = compute(kind: kind, from: library)
            guard !songs.isEmpty else { return nil }
            return SmartPlaylist(kind: kind, songs: songs)
        }
    }

    func compute(kind: SmartPlaylistKind, from library: [Song]) -> [Song] {
        switch kind {

        case .recents:
            let history = fetchHistory()
            let sortedPaths = history
                .filter { $0.playCount > 0 }
                .sorted { $0.lastPlayedAt > $1.lastPlayedAt }
                .prefix(50)
                .map(\.songPath)

            return resolve(paths: Array(sortedPaths), in: library)

        case .mostlyPlayed:
            let history = fetchHistory()
            let sortedPaths = history
                .filter { $0.playCount > 0 }
                .sorted { $0.playCount > $1.playCount }
                .prefix(50)
                .map(\.songPath)

            return resolve(paths: Array(sortedPaths), in: library)

        case .neverPlayed:
            let playedPaths = Set(
                fetchHistory()
                    .filter { $0.playCount > 0 }
                    .map(\.songPath)
            )

            let neverPlayed = library.filter { song in
                guard let rel = folderService.relativePath(for: song.url) else {
                    return false
                }
                return !playedPaths.contains(rel)
            }

            return Array(
                neverPlayed
                    .sorted {
                        $0.title.localizedStandardCompare($1.title) == .orderedAscending
                    }
                    .prefix(100)
            )
        }
    }

    // MARK: - SwiftData

    private func fetchHistory() -> [PlayHistoryEntry] {
        let descriptor = FetchDescriptor<PlayHistoryEntry>()
        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Path resolution

    private func resolve(paths: [String], in library: [Song]) -> [Song] {
        var byRelativePath: [String: Song] = [:]
        for song in library {
            if let rel = folderService.relativePath(for: song.url) {
                byRelativePath[rel] = song
            }
        }
        return paths.compactMap { byRelativePath[$0] }
    }
}
