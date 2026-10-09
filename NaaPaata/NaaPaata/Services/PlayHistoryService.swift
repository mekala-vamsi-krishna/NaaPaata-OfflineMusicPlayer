//
//  PlayHistoryService.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/9/26.
//

import Foundation
import SwiftData

@MainActor
struct PlayHistoryService {

    let context: ModelContext

    // MARK: - Record

    /// Increments the play count for the song and updates `lastPlayedAt`.
    /// Creates a new entry if the song hasn't been played before.
    func recordPlay(_ relativePath: String) throws {
        let entry = try fetchOrCreate(relativePath: relativePath)
        entry.playCount += 1
        entry.lastPlayedAt = Date()
        try context.save()
    }

    // MARK: - Read

    func allEntries() -> [PlayHistoryEntry] {
        let descriptor = FetchDescriptor<PlayHistoryEntry>()
        return (try? context.fetch(descriptor)) ?? []
    }

    func entry(for relativePath: String) -> PlayHistoryEntry? {
        let descriptor = FetchDescriptor<PlayHistoryEntry>(
            predicate: #Predicate { $0.songPath == relativePath }
        )
        return (try? context.fetch(descriptor))?.first
    }

    // MARK: - Private

    private func fetchOrCreate(relativePath: String) throws -> PlayHistoryEntry {
        if let existing = entry(for: relativePath) {
            return existing
        }
        let entry = PlayHistoryEntry(songPath: relativePath)
        context.insert(entry)
        return entry
    }
}
