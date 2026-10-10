//
//  NotchShape.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/22/26.
//

import SwiftUI

// Do not delete the comments, they are helpful
struct NotchShape: Shape {

    /// How far the body is inset from the flat top edge. Larger = a
    /// more pronounced outward flare at the shoulders.
    var topCurve: CGFloat

    /// Bottom corner rounding.
    var bottomRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let tc = min(topCurve, rect.width / 2, rect.height / 2)
        let br = min(bottomRadius, rect.width / 2, rect.height / 2)

        // Flat top edge
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))

        // Top-right concave fillet
        // Single quad curve. Control sits at the inner corner of the
        // bounding box, so the curve's tangent is horizontal at the
        // top and vertical at the body — one smooth sweep, no bulge.
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - tc, y: rect.minY + tc),
            control: CGPoint(x: rect.maxX - tc, y: rect.minY)
        )

        // Right side
        path.addLine(to: CGPoint(x: rect.maxX - tc, y: rect.maxY - br))

        // Bottom-right rounded corner
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - tc - br, y: rect.maxY),
            control: CGPoint(x: rect.maxX - tc, y: rect.maxY)
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: rect.minX + tc + br, y: rect.maxY))

        // Bottom-left rounded corner
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + tc, y: rect.maxY - br),
            control: CGPoint(x: rect.minX + tc, y: rect.maxY)
        )

        // Left side ───
        path.addLine(to: CGPoint(x: rect.minX + tc, y: rect.minY + tc))

        // Top-left concave fillet (mirror)
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.minY),
            control: CGPoint(x: rect.minX + tc, y: rect.minY)
        )

        path.closeSubpath()
        return path
    }
}
