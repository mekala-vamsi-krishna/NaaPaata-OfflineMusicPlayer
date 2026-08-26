//
//  ThemeManager.swift
//  NaaPaata
//

import SwiftUI
import Combine

struct AppThemeColor: Identifiable, Equatable {
    let id: String
    let name: String
    let color: Color

    static let all: [AppThemeColor] = [
        AppThemeColor(id: "purple", name: "Purple", color: Color(hex: "#AF52DE")),
        AppThemeColor(id: "Classic Red", name: "Classic Red",  color: Color(hex: "#FC3C44")),
        AppThemeColor(id: "Green",   name: "Green",    color: Color(hex: "#1ED760")),
        AppThemeColor(id: "coral",  name: "Coral",   color: Color(hex: "#FF6B6B")),
        AppThemeColor(id: "Orange",   name: "Orange",    color: Color(hex: "#FF6B00")),
        AppThemeColor(id: "Blue",   name: "Blue",    color: Color(hex: "#1451F0")),
    ]

    static let `default` = all[0]
}

// MARK: - App colour scheme (light / dark / system)
enum AppColorScheme: String, CaseIterable, Identifiable {
    case system = "system"
    case light  = "light"
    case dark   = "dark"

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

    /// Maps to SwiftUI's ColorScheme? (nil means follow system).
    var swiftUIScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

// MARK: - Theme manager
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published private(set) var current: AppThemeColor
    @Published private(set) var colorScheme: AppColorScheme

    private let colorKey  = "selected_theme_color_id"
    private let schemeKey = "selected_color_scheme"

    private init() {
        let savedColor  = UserDefaults.standard.string(forKey: "selected_theme_color_id") ?? ""
        let savedScheme = UserDefaults.standard.string(forKey: "selected_color_scheme") ?? ""
        current     = AppThemeColor.all.first { $0.id == savedColor } ?? .default
        colorScheme = AppColorScheme(rawValue: savedScheme) ?? .system
    }

    func select(_ theme: AppThemeColor) {
        guard theme != current else { return }
        current = theme
        UserDefaults.standard.set(theme.id, forKey: colorKey)
    }

    func select(_ scheme: AppColorScheme) {
        guard scheme != colorScheme else { return }
        colorScheme = scheme
        UserDefaults.standard.set(scheme.rawValue, forKey: schemeKey)
    }
}
