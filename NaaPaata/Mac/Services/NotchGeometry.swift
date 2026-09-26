//
//  NotchGeometry.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/22/26.
//

import AppKit

struct NotchGeometry {

    let hasPhysicalNotch: Bool
    let notchSize: CGSize
    let screen: NSScreen

    var topEdgeY: CGFloat { screen.frame.maxY }
    var centerX: CGFloat { screen.frame.midX }

    // MARK: - Detection

    /// Picks the first screen with a physical notch. Falls back to the
    /// main screen if none has one.
    static func detect() -> NotchGeometry? {
        let notched = NSScreen.screens.first { $0.safeAreaInsets.top > 0 }
        let screen = notched ?? NSScreen.main
        guard let screen else { return nil }

        let topInset = screen.safeAreaInsets.top
        let hasNotch = topInset > 0

        let notchSize: CGSize

        if hasNotch {
            let height = topInset
            let width: CGFloat

            // The auxiliary top areas describe the menu bar regions
            // to the left and right of the notch. Their widths plus
            // the notch add up to the screen width.
            if let left = screen.auxiliaryTopLeftArea,
               let right = screen.auxiliaryTopRightArea {
                width = screen.frame.width - left.width - right.width
            } else {
                width = 200
            }

            notchSize = CGSize(width: width, height: height)
        } else {
            // Approximate a 14" MacBook Pro notch for Macs that lack one.
            notchSize = CGSize(width: 200, height: 32)
        }

        return NotchGeometry(
            hasPhysicalNotch: hasNotch,
            notchSize: notchSize,
            screen: screen
        )
    }
}
