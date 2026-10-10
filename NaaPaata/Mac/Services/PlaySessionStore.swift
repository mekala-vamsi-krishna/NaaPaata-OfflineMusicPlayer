//
//  PlaySessionStore.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/25/26.
//

import Foundation
import SwiftData

/// Records listening sessions. Configured once at launch with the app's
@MainActor
final class PlaySessionStore {

    static let shared = PlaySessionStore()

    private var context: ModelContext?
    private var currentSession: PlaySession?
    private var lastFlush: Date = .distantPast

    /// Minimum interval between disk writes while a session is running.
    /// Keeps SwiftData from saving on every elapsed tick.
    private let flushInterval: TimeInterval = 5

    private init() {}

    // MARK: - Configure

    func configure(with container: ModelContainer) {
        guard context == nil else { return }
        self.context = ModelContext(container)
    }

    // MARK: - Session lifecycle

    /// Starts a new session for `songPath`, flushing the previous one.
    func beginSession(songPath: String) {
        endCurrentSession()

        guard let context else { return }
        let session = PlaySession(songPath: songPath)
        context.insert(session)
        currentSession = session
        flush(force: true)
    }

    /// Adds elapsed playback time to the current session. Called on
    /// every elapsed-tick from the player.
    func addDuration(_ seconds: TimeInterval) {
        guard seconds > 0, let session = currentSession else { return }
        session.duration += seconds
        flush(force: false)
    }

    /// Closes the current session. Called on pause, song change, or quit.
    func endCurrentSession() {
        flush(force: true)
        currentSession = nil
    }

    // MARK: - Queries

    /// All sessions whose `startedAt` falls inside `interval`.
    func sessions(in interval: DateInterval) -> [PlaySession] {
        guard let context else { return [] }
        let start = interval.start
        let end = interval.end

        let descriptor = FetchDescriptor<PlaySession>(
            predicate: #Predicate { session in
                session.startedAt >= start && session.startedAt < end
            }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Private

    private func flush(force: Bool) {
        guard let context else { return }
        let now = Date()
        guard force || now.timeIntervalSince(lastFlush) >= flushInterval else {
            return
        }
        try? context.save()
        lastFlush = now
    }
}
