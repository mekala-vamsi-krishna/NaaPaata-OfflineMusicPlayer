//
//  TimeSlot.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/25/26.
//

import Foundation

/// The six listening periods shown as columns in the stats heatmap.
enum TimeSlot: Int, CaseIterable, Identifiable {
    case night    // 00:00 – 05:00
    case early    // 05:00 – 08:00
    case morning  // 08:00 – 12:00
    case midday   // 12:00 – 16:00
    case evening  // 16:00 – 20:00
    case late     // 20:00 – 24:00

    var id: Int { rawValue }

    var shortLabel: String {
        switch self {
        case .night:   return "Night"
        case .early:   return "Early"
        case .morning: return "Morn"
        case .midday:  return "Midday"
        case .evening: return "Eve"
        case .late:    return "Late"
        }
    }

    static func from(hour: Int) -> TimeSlot {
        switch hour {
        case 0..<5:   return .night
        case 5..<8:   return .early
        case 8..<12:  return .morning
        case 12..<16: return .midday
        case 16..<20: return .evening
        default:      return .late
        }
    }
}
