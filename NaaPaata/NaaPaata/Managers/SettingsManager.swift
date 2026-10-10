//
//  SettingsManager.swift
//  NaaPaata
//

import Foundation
import Combine

@MainActor
final class SettingsManager: ObservableObject {

    static let shared = SettingsManager()

    static let crossfadeDurations: [Double] = [0, 3, 6, 9, 12]

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let crossfadeDuration = "crossfadeDuration"
        static let fadeDuration      = "fadeDuration"
        static let gaplessPlayback   = "gaplessPlayback"
    }

    // MARK: - Persisted properties

    @Published var crossfadeDuration: Double {
        didSet {
            defaults.set(crossfadeDuration, forKey: Keys.crossfadeDuration)

            // Crossfade and gapless are mutually exclusive — turning one
            // on turns the other off.
            if crossfadeDuration > 0, gaplessPlayback {
                gaplessPlayback = false
            }
        }
    }

    @Published var fadeDuration: Double {
        didSet {
            defaults.set(fadeDuration, forKey: Keys.fadeDuration)
        }
    }

    @Published var gaplessPlayback: Bool {
        didSet {
            defaults.set(gaplessPlayback, forKey: Keys.gaplessPlayback)

            if gaplessPlayback, crossfadeDuration > 0 {
                crossfadeDuration = 0
            }
        }
    }

    // MARK: - Init

    private init() {
        // Crossfade — normalize to the nearest valid step, default 0 (Off).
        let rawCrossfade = defaults.object(forKey: Keys.crossfadeDuration) == nil
            ? 0
            : defaults.double(forKey: Keys.crossfadeDuration)

        let normalizedCrossfade = Self.crossfadeDurations.min {
            abs($0 - rawCrossfade) < abs($1 - rawCrossfade)
        } ?? 0

        // Fade — distinguishes "never set" from "explicitly Off".
        let rawFade: Double
        if defaults.object(forKey: Keys.fadeDuration) == nil {
            rawFade = 250                      // first launch default
        } else {
            rawFade = defaults.double(forKey: Keys.fadeDuration)
        }

        // Gapless — only meaningful when crossfade is off.
        let rawGapless = defaults.bool(forKey: Keys.gaplessPlayback)
        let normalizedGapless = normalizedCrossfade == 0 && rawGapless

        self.crossfadeDuration = normalizedCrossfade
        self.fadeDuration      = rawFade
        self.gaplessPlayback   = normalizedGapless
    }
}
