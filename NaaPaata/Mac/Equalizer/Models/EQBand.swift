//
//  EQBand.swift
//  Mac
//
//  Created by Mekala Vamsi Krishna on 10/4/26.
//

import Foundation

/// A single EQ band. `q` is only meaningful in parametric mode.
struct EQBand: Identifiable, Hashable, Codable {
    let id: UUID
    var frequency: Double      // Hz — e.g. 32, 64, 125 ...
    var gain: Double           // dB — typically -12 ... +12
    var q: Double              // 0.1 ... 10 — wider to narrower
    var isEnabled: Bool
    var filterType: FilterType

    enum FilterType: String, Codable, CaseIterable {
        case peaking, lowShelf, highShelf, lowPass, highPass, notch
    }

    init(
        id: UUID = UUID(),
        frequency: Double,
        gain: Double = 0,
        q: Double = 1.0,
        isEnabled: Bool = true,
        filterType: FilterType = .peaking
    ) {
        self.id = id
        self.frequency = frequency
        self.gain = gain
        self.q = q
        self.isEnabled = isEnabled
        self.filterType = filterType
    }
}
