//
//  ThemeManager.swift
//  NaaPaata
//

import SwiftUI
import Combine

struct AppThemeColor: Identifiable, Hashable {

    let id: String
    let name: String
    let color: Color

    static let defaultID = "violet"

    static let all: [AppThemeColor] = [
        AppThemeColor(id: "violet", name: "Violet",
                      color: Color(red: 0.61, green: 0.11, blue: 0.66)),
        AppThemeColor(id: "pink",   name: "Pink",
                      color: Color(red: 0.93, green: 0.29, blue: 0.60)),
        AppThemeColor(id: "blue",   name: "Blue",
                      color: Color(red: 0.20, green: 0.51, blue: 0.96)),
        AppThemeColor(id: "green",  name: "Green",
                      color: Color(red: 0.13, green: 0.70, blue: 0.42)),
        AppThemeColor(id: "orange", name: "Orange",
                      color: Color(red: 0.96, green: 0.55, blue: 0.15)),
        AppThemeColor(id: "red",    name: "Red",
                      color: Color(red: 0.88, green: 0.22, blue: 0.22))
    ]

    static func color(forID id: String) -> Color {
        all.first(where: { $0.id == id })?.color ?? Color.accentColor
    }
}

enum AppColorScheme: String, CaseIterable, Identifiable {
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

@MainActor
final class ThemeManager: ObservableObject {

    static let shared = ThemeManager()

    // MARK: - Appearance

    @Published var colorScheme: AppColorScheme {
        didSet {
            UserDefaults.standard.set(
                colorScheme.rawValue,
                forKey: "appColorScheme"
            )
        }
    }

    // MARK: - Accent

    @Published var accentID: String {
        didSet {
            UserDefaults.standard.set(accentID, forKey: "appAccentID")
        }
    }

    /// The current accent as a `Color`. Views read this to tint UI.
    var accent: Color {
        AppThemeColor.color(forID: accentID)
    }

    // MARK: - Init

    private init() {
        let storedScheme = UserDefaults.standard.string(forKey: "appColorScheme") ?? ""
        self.colorScheme = AppColorScheme(rawValue: storedScheme) ?? .system

        let storedAccent = UserDefaults.standard.string(forKey: "appAccentID") ?? ""
        self.accentID = AppThemeColor.all.contains(where: { $0.id == storedAccent })
            ? storedAccent
            : AppThemeColor.defaultID
    }

    // MARK: - Mutations

    func set(_ scheme: AppColorScheme) {
        guard scheme != colorScheme else { return }
        colorScheme = scheme
    }

    func setAccent(_ id: String) {
        guard id != accentID else { return }
        accentID = id
    }
}
