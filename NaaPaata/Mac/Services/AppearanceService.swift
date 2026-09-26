//
//  AppearanceService.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/21/26.
//

import SwiftUI
import Combine
import AppKit

@MainActor
final class AppearanceService: ObservableObject {

    private static let storageKey = "appearancePreference"

    /// User-selected appearance. Setting this persists the choice and
    /// immediately applies it to every window in the app.
    @Published var preference: AppearancePreference {
        didSet {
            guard preference != oldValue else { return }
            UserDefaults.standard.set(preference.rawValue, forKey: Self.storageKey)
            apply()
        }
    }

    init() {
        let stored = UserDefaults.standard.string(forKey: Self.storageKey) ?? ""
        self.preference = AppearancePreference(rawValue: stored) ?? .system
        apply()
    }

    /// Sets `NSApp.appearance`. Passing `nil` reverts to the system.
    /// This cascades to every window the app owns — main, mini player,
    /// settings — without any per-window wiring.
    private func apply() {
        NSApp.appearance = preference.nsAppearance
    }
}
