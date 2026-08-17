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
//        static let crossfadeEnabled = "crossfadeEnabled"
//        static let crossfadeDuration = "crossfadeDuration"
        static let fadeEnabled = "fadeEnabled"
        static let fadeDuration = "fadeDuration"
//        static let gaplessPlayback = "gaplessPlayback"
    }

    /*
    @Published var crossfadeEnabled: Bool {
        didSet { defaults.set(crossfadeEnabled, forKey: Keys.crossfadeEnabled) }
    }
    @Published var crossfadeDuration: Double {
        didSet { defaults.set(crossfadeDuration, forKey: Keys.crossfadeDuration) }
    }
     */
    
    @Published var fadeEnabled: Bool {
        didSet { defaults.set(fadeEnabled, forKey: Keys.fadeEnabled) }
    }
    @Published var fadeDuration: Double {
        didSet { defaults.set(fadeDuration, forKey: Keys.fadeDuration) }
    }
    
    /*
    @Published var gaplessPlayback: Bool {
        didSet { defaults.set(gaplessPlayback, forKey: Keys.gaplessPlayback) }
    }
     */
    
    private init() {
//        let crossfadeEnabled = defaults.bool(forKey: Keys.crossfadeEnabled)
//        let crossfadeDuration = defaults.double(forKey: Keys.crossfadeDuration)
        let fadeEnabled = defaults.bool(forKey: Keys.fadeEnabled)
        let fadeDuration = defaults.double(forKey: Keys.fadeDuration)
//        let gaplessPlayback = defaults.bool(forKey: Keys.gaplessPlayback)

//        self.crossfadeEnabled = crossfadeEnabled
//        self.crossfadeDuration = crossfadeDuration == 0 ? 3 : crossfadeDuration
        self.fadeEnabled = fadeEnabled
        self.fadeDuration = fadeDuration == 0 ? 250 : fadeDuration
//        self.gaplessPlayback = gaplessPlayback
    }
}

