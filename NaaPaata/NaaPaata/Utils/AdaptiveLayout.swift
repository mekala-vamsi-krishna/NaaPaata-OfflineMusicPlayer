//
//  AdaptiveLayout.swift
//  NaaPaata
//
//  Created for adaptive layouts across devices
//

import SwiftUI

struct AdaptiveLayout {
    let horizontalSizeClass: UserInterfaceSizeClass?
    let screenWidth: CGFloat

    // MARK: - Grid Columns
    var gridColumns: Int {
        if screenWidth > 1200 { return 6 }
        if screenWidth > 900 { return 4 }
        if screenWidth > 600 { return 3 }
        return 2
    }

    // MARK: - Card Sizing
    /// Increased image size: 92% of card width, cap at 240
    var cardImageSize: CGFloat {
        let availableWidth = screenWidth - (horizontalPadding * 2) - (CGFloat(gridColumns - 1) * gridSpacing)
        let cardWidth = availableWidth / CGFloat(gridColumns)
        return min(cardWidth * 0.92, 240)   // 🔥 bigger
    }

    var playlistCardHeight: CGFloat {
        return min(cardImageSize * 0.9, 160)
    }

    // MARK: - Spacing & Padding
    var gridSpacing: CGFloat {
        screenWidth > 900 ? 24 : 16
    }

    var horizontalPadding: CGFloat {
        screenWidth > 900 ? 40 : 10
    }

    var verticalSpacing: CGFloat {
        screenWidth > 900 ? 16 : 10
    }

    var miniPlayerBottomPadding: CGFloat {
        screenWidth > 600 ? 60 : 48
    }

    var miniPlayerHorizontalPadding: CGFloat {
        screenWidth > 900 ? 20 : 8
    }

    // MARK: - Music Player Sizing
    var albumArtSize: CGFloat {
        if horizontalSizeClass == .regular && screenWidth > 600 {
            return min(screenWidth * 0.6, 500)
        }
        return min(screenWidth * 0.85, 350)
    }

    var controlButtonSize: CGFloat {
        horizontalSizeClass == .regular ? 60 : 50
    }

    var playButtonSize: CGFloat {
        horizontalSizeClass == .regular ? 80 : 70
    }

    // MARK: - Detail View Sizing
    var detailArtworkSize: CGFloat {
        if horizontalSizeClass == .regular && screenWidth > 600 {
            return 280
        }
        return 200
    }

    // MARK: - Font Scaling
    var titleFontScale: CGFloat {
        screenWidth > 900 ? 1.2 : 1.0
    }

    var bodyFontScale: CGFloat {
        screenWidth > 900 ? 1.1 : 1.0
    }
}

extension EnvironmentValues {
    var adaptiveLayout: AdaptiveLayout {
        AdaptiveLayout(
            horizontalSizeClass: self.horizontalSizeClass,
            screenWidth: UIScreen.main.bounds.width
        )
    }
}
