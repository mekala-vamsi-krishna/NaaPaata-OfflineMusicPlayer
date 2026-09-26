//
//  SmartPlaylistKind.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/21/26.
//

import SwiftUI

enum SmartPlaylistKind: String, CaseIterable, Identifiable {
    case recents
    case mostlyPlayed
    case neverPlayed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .recents:       return "Recents"
        case .mostlyPlayed:  return "Mostly Played"
        case .neverPlayed:   return "Never Played"
        }
    }

    var systemImage: String {
        switch self {
        case .recents:       return "clock.arrow.circlepath"
        case .mostlyPlayed:  return "flame.fill"
        case .neverPlayed:   return "sparkles"
        }
    }

    var gradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "9C1BA8"),
                Color(hex: "2A0547")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct SmartPlaylistRoute: Hashable {
    let kind: SmartPlaylistKind
}
