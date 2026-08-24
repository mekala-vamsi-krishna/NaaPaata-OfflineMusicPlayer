//
//  SettingsManager.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 8/15/26.
//

import Foundation
import Combine

final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let crossfadeDuration = "crossfadeDuration"
        static let fadeEnabled = "fadeEnabled"
        static let fadeDuration = "fadeDuration"
        static let gaplessPlayback = "gaplessPlayback"
    }

    static let crossfadeDurations: [Double] = [0, 3, 6, 9, 12]

    @Published var crossfadeDuration: Double {
        didSet {
            defaults.set(crossfadeDuration, forKey: Keys.crossfadeDuration)
            if crossfadeDuration > 0 && gaplessPlayback {
                gaplessPlayback = false
            }
        }
    }

    @Published var fadeEnabled: Bool {
        didSet { defaults.set(fadeEnabled, forKey: Keys.fadeEnabled) }
    }

    @Published var fadeDuration: Double {
        didSet { defaults.set(fadeDuration, forKey: Keys.fadeDuration) }
    }

    @Published var gaplessPlayback: Bool {
        didSet {
            defaults.set(gaplessPlayback, forKey: Keys.gaplessPlayback)
            if gaplessPlayback && crossfadeDuration > 0 {
                crossfadeDuration = 0
            }
        }
    }

    private init() {
        let storedCrossfadeDuration = defaults.object(forKey: Keys.crossfadeDuration) == nil
            ? 0
            : defaults.double(forKey: Keys.crossfadeDuration)
        let normalizedCrossfadeDuration = Self.crossfadeDurations.min {
            abs($0 - storedCrossfadeDuration) < abs($1 - storedCrossfadeDuration)
        } ?? 0
        crossfadeDuration = normalizedCrossfadeDuration

        fadeEnabled = defaults.bool(forKey: Keys.fadeEnabled)
        let storedFadeDuration = defaults.double(forKey: Keys.fadeDuration)
        fadeDuration = storedFadeDuration == 0 ? 250 : storedFadeDuration
        gaplessPlayback = normalizedCrossfadeDuration == 0 && defaults.bool(forKey: Keys.gaplessPlayback)
    }
}

