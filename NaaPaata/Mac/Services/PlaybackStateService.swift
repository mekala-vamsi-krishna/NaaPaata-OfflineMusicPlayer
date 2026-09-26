//
//  PlaybackStateService.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/21/26.
//

import Foundation

protocol PlaybackStateServiceProtocol {
    func load() -> PlaybackState?
    func save(_ state: PlaybackState)
}

final class PlaybackStateService: PlaybackStateServiceProtocol {

    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        let folder = appSupport.appendingPathComponent(
            "Naa Paata",
            isDirectory: true
        )
        try? FileManager.default.createDirectory(
            at: folder,
            withIntermediateDirectories: true
        )

        self.fileURL = folder.appendingPathComponent("playback-state.json")
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
        try? data.write(to: fileURL, options: .atomic)
    }
}
