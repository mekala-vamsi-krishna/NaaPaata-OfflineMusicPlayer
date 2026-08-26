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
        let storedCrossfade = defaults.object(forKey: Keys.crossfadeDuration) == nil
            ? 0
            : defaults.double(forKey: Keys.crossfadeDuration)
        let normalizedCrossfade = Self.crossfadeDurations.min {
            abs($0 - storedCrossfade) < abs($1 - storedCrossfade)
        } ?? 0

        let storedFade = defaults.double(forKey: Keys.fadeDuration)
        let normalizedFade = storedFade == 0 ? 250 : storedFade

        let storedGapless = defaults.bool(forKey: Keys.gaplessPlayback)
        let normalizedGapless = normalizedCrossfade == 0 && storedGapless

        self.crossfadeDuration = normalizedCrossfade
        self.fadeDuration = normalizedFade
        self.gaplessPlayback = normalizedGapless
    }
}
