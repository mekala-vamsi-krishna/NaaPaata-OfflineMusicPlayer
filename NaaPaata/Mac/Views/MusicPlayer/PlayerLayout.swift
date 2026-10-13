//
//  PlayerLayout.swift
//  Mac
//
//  Created by Mekala Vamsi Krishna on 10/13/26.
//

import SwiftUI

struct PlayerLayout {

    let size: CGSize

    private static let referenceSize = CGSize(width: 320, height: 700)
    private static let minScale: CGFloat = 0.55
    private static let maxScale: CGFloat = 1.7

    var scale: CGFloat {
        let wRatio = size.width / Self.referenceSize.width
        let hRatio = size.height / Self.referenceSize.height
        let raw: CGFloat = wRatio >= 1.0 ? hRatio : min(wRatio, hRatio)
        return min(max(raw, Self.minScale), Self.maxScale)
    }

    var horizontalPadding: CGFloat {
        min(24 * scale, size.width * 0.10)
    }

    var contentWidth: CGFloat {
        max(size.width - horizontalPadding * 2, 100)
    }

    var topPadding: CGFloat { 16 * scale }
    var bottomPadding: CGFloat { 16 * scale }

    var artworkSize: CGFloat {
        let byWidth  = contentWidth
        let byHeight = size.height - reservedBelowArtwork
        let target   = min(byWidth, byHeight, 500 * scale)
        return max(target, 80)
    }

    private var reservedBelowArtwork: CGFloat {
        artworkBottomSpacing
            + titleFrameHeight + titleArtistSpacing + artistFrameHeight
            + trackInfoBottomSpacing
            + sliderContainerHeight + sliderTimeSpacing + timeFontSize * 1.4
            + progressBottomSpacing
            + playButtonSize
            + transportBottomSpacing
            + utilityButtonSize
            + topPadding + bottomPadding
    }

    var artworkCornerRadius: CGFloat { 16 * scale }
    var artworkShadowRadius: CGFloat { 18 * scale }
    var artworkShadowY: CGFloat { 10 * scale }
    var placeholderIconSize: CGFloat { 64 * scale }

    var controlButtonSize: CGFloat { 56 * scale }
    var playButtonSize: CGFloat { 76 * scale }
    var utilityButtonSize: CGFloat { 40 * scale }
    var utilityActiveCircleSize: CGFloat { 30 * scale }
    var transportButtonSpacing: CGFloat { 30 * scale }

    var sliderTrackHeight: CGFloat { 4 * scale }
    var sliderThumbSize: CGFloat { 12 * scale }
    var sliderContainerHeight: CGFloat { 20 * scale }

    var artworkBottomSpacing: CGFloat { 18 * scale }
    var trackInfoBottomSpacing: CGFloat { 14 * scale }
    var progressBottomSpacing: CGFloat { 14 * scale }
    var transportBottomSpacing: CGFloat { 10 * scale }
    var titleArtistSpacing: CGFloat { 4 * scale }
    var sliderTimeSpacing: CGFloat { 6 * scale }

    var titleFontSize: CGFloat { 16 * scale }
    var artistFontSize: CGFloat { 13 * scale }
    var timeFontSize: CGFloat { 11 * scale }

    var playIconSize: CGFloat { 36 * scale }
    var transportIconSize: CGFloat { 26 * scale }
    var utilityIconSize: CGFloat { 15 * scale }

    var titleFrameHeight: CGFloat { 22 * scale }
    var artistFrameHeight: CGFloat { 18 * scale }
}
