//
//  AppearanceManager.swift
//  NaaPaata
//

import SwiftUI
import Combine

// MARK: - Appearance Mode

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }

    /// `nil` means "follow the system".
    var swiftUIScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

// MARK: - Appearance Manager

@MainActor
final class AppearanceManager: ObservableObject {

    static let shared = AppearanceManager()

    @Published var mode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: Self.storageKey)
        }
    }

    private static let storageKey = "appAppearanceMode"

    private init() {
        let stored = UserDefaults.standard.string(forKey: Self.storageKey) ?? ""
        self.mode = AppearanceMode(rawValue: stored) ?? .system
    }

    func set(_ mode: AppearanceMode) {
        guard mode != self.mode else { return }
        self.mode = mode
    }
}
