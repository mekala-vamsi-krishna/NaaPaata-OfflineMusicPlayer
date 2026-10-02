//
//  AppColors.swift
//  NaaPaata
//

import SwiftUI

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

extension Color {
    static let darkStart = Color(red: 50 / 255, green: 60 / 255, blue: 65 / 255)
    static let darkEnd   = Color(red: 25 / 255, green: 25 / 255, blue: 30 / 255)
}

struct AppColors {

    // MARK: - Brand
    /// The app's accent. Reads `Color.accentColor`, which is resolved
    /// from the AccentColor asset and adapts to light/dark automatically.
    static var primary: Color { Color.accentColor }
    static let secondary = Color(hex: "#D8B4FE")

    // MARK: - Backgrounds
    static var background: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.07, green: 0.07, blue: 0.09, alpha: 1.0)
                : UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
        })
    }

    static var cardBackground: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.14, green: 0.14, blue: 0.16, alpha: 1.0)
                : UIColor(white: 0.95, alpha: 1.0)
        })
    }

    // MARK: - Text
    static var textPrimary: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? .white
                : UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
        })
    }

    static var textSecondary: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(white: 0.75, alpha: 1.0)
                : UIColor(red: 0.39, green: 0.39, blue: 0.40, alpha: 1.0)
        })
    }

    static let error = Color(hex: "#FF453A")
}
