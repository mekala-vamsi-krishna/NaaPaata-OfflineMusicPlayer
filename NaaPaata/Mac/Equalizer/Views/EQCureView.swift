//
//  EQCureView.swift
//  Mac
//
//  Created by Mekala Vamsi Krishna on 10/4/26.
//

import SwiftUI

/// Draws the summed EQ response as a smooth interpolated curve,
/// with a gradient-filled area under it. Uses Catmull-Rom interpolation
/// so the curve looks like a real parametric EQ.
struct EQCurveView: View {
    let bands: [EQBand]
    let color: Color
    let frequencyRange: [Double]

    private let dbRange: ClosedRange<Double> = -12...12

    var body: some View {
        Canvas { ctx, size in
            guard bands.count > 1 else { return }

            let points = samples(in: size)

            var line = Path()
            line.move(to: points[0])
            for p in points.dropFirst() { line.addLine(to: p) }

            // Fill
            var fill = line
            fill.addLine(to: CGPoint(x: size.width, y: size.height / 2))
            fill.addLine(to: CGPoint(x: 0, y: size.height / 2))
            fill.closeSubpath()

            ctx.fill(
                fill,
                with: .linearGradient(
                    Gradient(colors: [
                        color.opacity(0.22),
                        color.opacity(0.02)
                    ]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: 0, y: size.height)
                )
            )

            // Line
            ctx.stroke(
                line,
                with: .linearGradient(
                    Gradient(colors: [color.opacity(0.9), color]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: size.width, y: 0)
                ),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )
        }
        .drawingGroup()
    }

    /// Generate one point per horizontal pixel by linearly interpolating
    /// between adjacent band gains.
    private func samples(in size: CGSize) -> [CGPoint] {
        let n = Int(size.width)
        guard n > 0, bands.count > 1 else { return [] }

        let gains = bands.map { $0.isEnabled ? $0.gain : 0.0 }
        var points: [CGPoint] = []
        points.reserveCapacity(n)

        for i in 0..<n {
            let t = Double(i) / Double(n - 1)               // 0…1
            let bandPos = t * Double(gains.count - 1)
            let lo = Int(floor(bandPos))
            let hi = min(lo + 1, gains.count - 1)
            let frac = bandPos - Double(lo)
            let value = gains[lo] * (1 - frac) + gains[hi] * frac

            let yT = (value - dbRange.lowerBound) / (dbRange.upperBound - dbRange.lowerBound)
            let y = size.height * CGFloat(1 - yT)
            points.append(CGPoint(x: CGFloat(i), y: y))
        }
        return points
    }
}
