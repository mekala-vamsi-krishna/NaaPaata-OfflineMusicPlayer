//
//  AppearancePreview.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/21/26.
//

import SwiftUI

struct AppearancePreview: View {

    let preference: AppearancePreference

    var body: some View {
        GeometryReader { geo in
            ZStack {
                background

                windowMockup(
                    width: geo.size.width * 0.66,
                    height: geo.size.height * 0.56,
                    dark: windowIsDark
                )
            }
        }
    }

    // MARK: - Background

    @ViewBuilder
    private var background: some View {
        switch preference {
        case .light:
            lightWallpaper

        case .dark:
            darkWallpaper

        case .system:
            ZStack {
                lightWallpaper
                darkWallpaper
                    .mask(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.35),
                                .init(color: .black, location: 0.65)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
    }

    private var lightWallpaper: some View {
        LinearGradient(
            colors: [
                Color(red: 0.62, green: 0.76, blue: 0.94),
                Color(red: 0.92, green: 0.94, blue: 0.97)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var darkWallpaper: some View {
        LinearGradient(
            colors: [
                Color(red: 0.10, green: 0.13, blue: 0.22),
                Color(red: 0.02, green: 0.03, blue: 0.06)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Window mockup

    private var windowIsDark: Bool {
        switch preference {
        case .light, .system: return false
        case .dark:           return true
        }
    }

    private func windowMockup(width: CGFloat, height: CGFloat, dark: Bool) -> some View {
        ZStack {
            // Body
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(dark ? Color(white: 0.22) : .white)
                .shadow(color: .black.opacity(0.18), radius: 3, y: 1)

            VStack(spacing: 0) {
                // Title bar with traffic lights
                HStack(spacing: 3) {
                    Circle().fill(Color(red: 1.00, green: 0.37, blue: 0.34))
                        .frame(width: 5, height: 5)
                    Circle().fill(Color(red: 1.00, green: 0.74, blue: 0.15))
                        .frame(width: 5, height: 5)
                    Circle().fill(Color(red: 0.22, green: 0.78, blue: 0.28))
                        .frame(width: 5, height: 5)
                    Spacer()
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(dark ? Color(white: 0.16) : Color(white: 0.95))

                // Content strip — a couple of gray bars to suggest text
                VStack(alignment: .leading, spacing: 4) {
                    Capsule()
                        .fill(dark ? Color(white: 0.35) : Color(white: 0.82))
                        .frame(width: width * 0.5, height: 4)
                    Capsule()
                        .fill(dark ? Color(white: 0.28) : Color(white: 0.88))
                        .frame(width: width * 0.35, height: 4)
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.top, 6)
            }
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
        .frame(width: width, height: height)
    }
}
