//
//  Color+Ext.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/12/26.
//

import SwiftUI
import AppKit

enum AppColor {

    // MARK: - Backgrounds
    static let background = dynamic(light: "#FAFAFA", dark: "#09090B")
    static let surface    = dynamic(light: "#FFFFFF", dark: "#18181B")
    static let sidebar    = dynamic(light: "#F4F4F5", dark: "#18181B")

    // MARK: - Text
    static let textPrimary   = dynamic(light: "#18181B", dark: "#FAFAFA")
    static let textSecondary = dynamic(light: "#52525B", dark: "#A1A1AA")
    static let textTertiary  = dynamic(light: "#71717A", dark: "#71717A")

    // MARK: - Borders
    static let border    = dynamic(light: "#E4E4E7", dark: "#27272A")
    static let separator = dynamic(light: "#E4E4E7", dark: "#27272A")

    // MARK: - Brand
    static let primary       = dynamic(light: "#9C1BA8", dark: "#C24FC9")
    static let primaryHover  = dynamic(light: "#B93FB3", dark: "#D9A0DE")
    static let primarySubtle = dynamic(light: "#F9F2FB", dark: "#2A0547")
    static let onPrimary     = Color.white

    // MARK: - Status
    static let danger  = dynamic(light: "#DC2626", dark: "#EF4444")
    static let success = dynamic(light: "#16A34A", dark: "#22C55E")

    // MARK: - Gradient (icon / artwork placeholder)
    static let brandGradient = LinearGradient(
        colors: [Color(hex: "#4B0B7E"), Color(hex: "#9C1BA8"), Color(hex: "#C21AA9")],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Helpers

    private static func dynamic(light: String, dark: String) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return NSColor(hex: isDark ? dark : light) ?? .labelColor
        })
    }
}

// MARK: - Hex string parsing

extension Color {
    /// Accepts "#RRGGBB", "RRGGBB", "#RGB", "RGB", or "#RRGGBBAA".
    init(hex: String) {
        let parsed = Self.parse(hex: hex) ?? (r: 0, g: 0, b: 0, a: 1)
        self.init(
            .sRGB,
            red:   parsed.r,
            green: parsed.g,
            blue:  parsed.b,
            opacity: parsed.a
        )
    }

    fileprivate static func parse(hex: String) -> (r: Double, g: Double, b: Double, a: Double)? {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") { s.removeFirst() }

        // Expand shorthand "RGB" or "RGBA" to full form.
        if s.count == 3 || s.count == 4 {
            s = s.map { "\($0)\($0)" }.joined()
        }

        guard s.count == 6 || s.count == 8,
              let value = UInt64(s, radix: 16) else { return nil }

        let hasAlpha = s.count == 8
        let r = Double((value >> (hasAlpha ? 24 : 16)) & 0xFF) / 255
        let g = Double((value >> (hasAlpha ? 16 : 8))  & 0xFF) / 255
        let b = Double((value >> (hasAlpha ? 8  : 0))  & 0xFF) / 255
        let a = hasAlpha ? Double(value & 0xFF) / 255 : 1
        return (r, g, b, a)
    }
}

extension NSColor {
    /// Accepts "#RRGGBB", "RRGGBB", "#RGB", "RGB", or "#RRGGBBAA".
    convenience init?(hex: String) {
        guard let parsed = Color.parse(hex: hex) else { return nil }
        self.init(
            srgbRed: CGFloat(parsed.r),
            green:   CGFloat(parsed.g),
            blue:    CGFloat(parsed.b),
            alpha:   CGFloat(parsed.a)
        )
    }
}
