//
//  PlayHistoryStore.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/21/26.
//

import Foundation
import SwiftData

@MainActor
final class PlayHistoryStore {

    static let shared = PlayHistoryStore()

    private var container: ModelContainer?
    private var context: ModelContext?

    private init() {}

    func configure(with container: ModelContainer) {
        guard self.container == nil else { return }
        self.container = container
        self.context = ModelContext(container)
    }

    // MARK: - Writes

    func recordPlay(_ url: URL) {
        guard let context else { return }
        let path = url.path

        let descriptor = FetchDescriptor<PlayHistoryEntry>(
            predicate: #Predicate { $0.songPath == path }
        )

        if let entry = try? context.fetch(descriptor).first {
            entry.playCount += 1
            entry.lastPlayedAt = Date()
        } else {
            context.insert(
                PlayHistoryEntry(
                    songPath: path,
                    playCount: 1,
                    lastPlayedAt: Date()
                )
            )
        }

        try? context.save()
    }

    // MARK: - Reads

    func allEntries() -> [PlayHistoryEntry] {
        guard let context else { return [] }
        let descriptor = FetchDescriptor<PlayHistoryEntry>()
        return (try? context.fetch(descriptor)) ?? []
    }

    func entry(for path: String) -> PlayHistoryEntry? {
        guard let context else { return nil }
        let descriptor = FetchDescriptor<PlayHistoryEntry>(
            predicate: #Predicate { $0.songPath == path }
        )
        return try? context.fetch(descriptor).first
    }
}
