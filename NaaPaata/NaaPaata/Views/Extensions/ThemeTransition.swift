//
//  ThemeTransition.swift
//  NaaPaata
//
//  Circular wave transition that expands from the top-trailing corner when the
//  user switches between Light, Dark and System colour schemes.
//  Technique: snapshot the current window, overlay it on top of the new UI,
//  then mask the snapshot with a shrinking circle so the new theme "reveals"
//  from behind as the circle collapses — or use an expanding circle when going
//  in the opposite direction.
//

import SwiftUI
import UIKit

// MARK: - Public trigger

/// Call this instead of directly changing the colour scheme.
/// It takes a screenshot of the current window, applies the new scheme, then
/// runs the circular reveal animation on top.
@MainActor
func performThemeTransition(
    to scheme: AppColorScheme,
    from sourceView: UIView? = nil
) {
    guard let window = UIApplication.shared
        .connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .first?
        .windows
        .first(where: \.isKeyWindow)
    else { return }

    // 1. Snapshot the current appearance.
    let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
    let snapshot = renderer.image { _ in window.drawHierarchy(in: window.bounds, afterScreenUpdates: false) }

    // 2. Apply the new colour scheme immediately (happens under the snapshot).
    ThemeManager.shared.select(scheme)

    // 3. Create a snapshot image view and pin it to the window.
    let snapshotView = UIImageView(image: snapshot)
    snapshotView.frame = window.bounds
    snapshotView.contentMode = .scaleAspectFill
    window.addSubview(snapshotView)

    // 4. Determine the origin corner for the circular mask.
    //    Going dark → expand from top-trailing (sun → moon direction).
    //    Going light → expand from top-trailing as well for consistency.
    let origin = CGPoint(x: window.bounds.maxX, y: window.bounds.minY)

    // Maximum radius needed to cover the whole screen from that corner.
    let maxRadius = hypot(window.bounds.width, window.bounds.height)

    // 5. Create the circular mask layer.
    let maskLayer = CAShapeLayer()
    // Start: full circle covering the snapshot (so snapshot is fully visible).
    let startPath = UIBezierPath(
        arcCenter: origin,
        radius: maxRadius,
        startAngle: 0,
        endAngle: .pi * 2,
        clockwise: true
    ).cgPath
    // End: collapsed to zero (snapshot disappears, new theme fully revealed).
    let endPath = UIBezierPath(
        arcCenter: origin,
        radius: 0,
        startAngle: 0,
        endAngle: .pi * 2,
        clockwise: true
    ).cgPath

    maskLayer.path = startPath
    snapshotView.layer.mask = maskLayer

    // 6. Animate the mask collapsing (revealing the new theme underneath).
    let duration: CFTimeInterval = 0.52
    CATransaction.begin()
    CATransaction.setCompletionBlock {
        snapshotView.removeFromSuperview()
    }
    let animation = CABasicAnimation(keyPath: "path")
    animation.fromValue = startPath
    animation.toValue   = endPath
    animation.duration  = duration
    animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    animation.fillMode  = .forwards
    animation.isRemovedOnCompletion = false
    maskLayer.add(animation, forKey: "themeReveal")
    CATransaction.commit()
}
