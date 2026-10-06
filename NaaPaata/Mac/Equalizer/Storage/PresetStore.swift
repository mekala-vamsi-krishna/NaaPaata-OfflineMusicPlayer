//
//  PresetStore.swift
//  Mac
//
//  Created by Mekala Vamsi Krishna on 10/4/26.
//

import Foundation

nonisolated protocol PresetStore: AnyObject {
    /// Read all custom presets. Returns an empty array on first launch.
    func loadCustomPresets() throws -> [EqualizerPreset]

    /// Atomically replace the persisted set of custom presets.
    func saveCustomPresets(_ presets: [EqualizerPreset]) throws
}
