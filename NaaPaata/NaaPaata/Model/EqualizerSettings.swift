//
//  EqualizerSettings.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 11/29/25.
//

import Foundation

struct EqualizerSettings: Codable {
    var isEnabled: Bool
    var preAmpValue: Double
    var bassValue: Double
    var trebleValue: Double
    var bands: [Double]
    var selectedPreset: String
    var isPreAmpEnabled: Bool
    var isBassEnabled: Bool
    var isTrebleEnabled: Bool
}
