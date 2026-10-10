//
//  FilePresetStore.swift
//  Mac
//
//  Created by Mekala Vamsi Krishna on 10/4/26.
//

import Foundation

/// Location:
///   `~/Library/Application Support/NaaPaata/eq-presets.json`

nonisolated final class FilePresetStore: PresetStore {

    private struct PresetFile: Codable {
        let version: Int
        let presets: [EqualizerPreset]
    }

    private static let currentVersion = 1

    private let fileURL: URL

    init(filename: String = "eq-presets.json") {
        let support = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!

        let appFolder = support.appendingPathComponent("NaaPaata", isDirectory: true)

        try? FileManager.default.createDirectory(
            at: appFolder,
            withIntermediateDirectories: true
        )

        self.fileURL = appFolder.appendingPathComponent(filename)
    }

    func loadCustomPresets() throws -> [EqualizerPreset] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let file = try decoder.decode(PresetFile.self, from: data)
        return file.presets
    }

    func saveCustomPresets(_ presets: [EqualizerPreset]) throws {
        let file = PresetFile(
            version: Self.currentVersion,
            presets: presets
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(file)
        try data.write(to: fileURL, options: .atomic)
    }
}

nonisolated final class InMemoryPresetStore: PresetStore {
    private var storage: [EqualizerPreset]

    init(seed: [EqualizerPreset] = []) {
        self.storage = seed
    }

    func loadCustomPresets() throws -> [EqualizerPreset] { storage }
    func saveCustomPresets(_ presets: [EqualizerPreset]) throws { storage = presets }
}
