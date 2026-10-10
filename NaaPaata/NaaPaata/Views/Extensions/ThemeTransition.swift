//
//  ThemeTransition.swift
//  NaaPaata
//

import SwiftUI
import UIKit

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
    let snapshot = renderer.image { _ in
        window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
    }

    // 2. Apply the new color scheme immediately — happens under the snapshot.
    ThemeManager.shared.set(scheme)          // ← was .select(scheme)

    // 3. Overlay the snapshot on top of the window.
    let snapshotView = UIImageView(image: snapshot)
    snapshotView.frame = window.bounds
    snapshotView.contentMode = .scaleAspectFill
    window.addSubview(snapshotView)

    // 4. Circular mask origin — top-trailing corner.
    let origin = CGPoint(x: window.bounds.maxX, y: window.bounds.minY)
    let maxRadius = hypot(window.bounds.width, window.bounds.height)

    // 5. Mask starts as a full circle (snapshot fully visible) and
    //    collapses to zero (new theme revealed underneath).
    let maskLayer = CAShapeLayer()

    let startPath = UIBezierPath(
        arcCenter: origin,
        radius: maxRadius,
        startAngle: 0,
        endAngle: .pi * 2,
        clockwise: true
    ).cgPath

    let endPath = UIBezierPath(
        arcCenter: origin,
        radius: 0,
        startAngle: 0,
        endAngle: .pi * 2,
        clockwise: true
    ).cgPath

    maskLayer.path = startPath
    snapshotView.layer.mask = maskLayer

    // 6. Animate the collapse.
    let duration: CFTimeInterval = 0.52
    CATransaction.begin()
    CATransaction.setCompletionBlock {
        snapshotView.removeFromSuperview()
    }

    let animation = CABasicAnimation(keyPath: "path")
    animation.fromValue = startPath
    animation.toValue = endPath
    animation.duration = duration
    animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    animation.fillMode = .forwards
    animation.isRemovedOnCompletion = false
    maskLayer.add(animation, forKey: "themeReveal")

    CATransaction.commit()
}
