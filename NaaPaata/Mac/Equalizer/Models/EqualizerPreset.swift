//
//  EqualizerPreset.swift
//  Mac
//
//  Created by Mekala Vamsi Krishna on 10/4/26.
//

import Foundation

struct EqualizerPreset: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var category: Category
    var bands: [Double]        // 10 gain values in dB
    var preamp: Double         // dB
    var isBuiltIn: Bool
    var dateCreated: Date

    enum Category: String, Codable, CaseIterable {
        case builtIn, custom, genre, reference, user

        var label: String {
            switch self {
            case .builtIn:   return "Built-in"
            case .custom:    return "My Presets"
            case .genre:     return "Genre"
            case .reference: return "Reference"
            case .user:      return "Custom"
            }
        }
    }

    static let frequencies: [Double] = [
        32, 64, 125, 250, 500, 1_000, 2_000, 4_000, 8_000, 16_000
    ]

    static func flat() -> EqualizerPreset {
        EqualizerPreset(
            id: UUID(),
            name: "Flat",
            category: .builtIn,
            bands: Array(repeating: 0, count: 10),
            preamp: 0,
            isBuiltIn: true,
            dateCreated: .distantPast
        )
    }
}
