//
//  PlaybackStateService.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 11/9/25.
//
import Foundation

protocol PlaybackStateServiceProtocol {
    func load() -> PlaybackState?
    func save(_ state: PlaybackState)
    func clear()
}

/// Persists the last playback session as JSON in Application Support.
/// Writes are atomic and happen off the main thread.
final class PlaybackStateService: PlaybackStateServiceProtocol {

    private let fileURL: URL
    private let writeQueue = DispatchQueue(
        label: "com.naapaata.playback-state.write",
        qos: .utility
    )

    init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        try? FileManager.default.createDirectory(
            at: appSupport,
            withIntermediateDirectories: true
        )

        self.fileURL = appSupport.appendingPathComponent("playback-state.json")
    }

    func load() -> PlaybackState? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        return try? JSONDecoder().decode(PlaybackState.self, from: data)
    }

    func save(_ state: PlaybackState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        let url = fileURL
        writeQueue.async {
            try? data.write(to: url, options: .atomic)
        }
    }

    func clear() {
        let url = fileURL
        writeQueue.async {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
