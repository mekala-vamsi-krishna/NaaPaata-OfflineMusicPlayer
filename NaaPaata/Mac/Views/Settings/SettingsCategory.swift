//
//  SettingsCategory.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/24/26.
//

import Foundation

enum SettingsCategory: String, CaseIterable, Identifiable, Hashable {
    case appearance
    case notch
    case stats
    case library
    case audioEngine
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .appearance:   return "Appearance"
        case .notch:        return "Notch"
        case .stats:        return "Stats"
        case .library:      return "Library"
        case .audioEngine:  return "Audio Engine"
        case .about:        return "About"
        }
    }

    var systemImage: String {
        switch self {
        case .appearance:   return "paintbrush"
        case .notch:        return "rectangle.topthird.inset.filled"
        case .stats:        return "chart.bar"
        case .library:      return "folder"
        case .audioEngine:  return "waveform"
        case .about:        return "info.circle"
        }
    }
}
