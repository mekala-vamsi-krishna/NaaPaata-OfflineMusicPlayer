//
//  SpectrumAnalyzerView.swift
//  Mac
//
//  Created by Mekala Vamsi Krishna on 10/4/26.
//

import SwiftUI

/// Renders `bins` (0…1 normalized) as a mirrored bar graph along the
/// bottom half of the plot, with an exponential decay envelope.
struct SpectrumAnalyzerView: View {
    let bins: [Float]
    let color: Color

    var body: some View {
        Canvas { ctx, size in
            guard !bins.isEmpty else { return }
            let barCount = bins.count
            let barSpacing: CGFloat = 1
            let barWidth = max(1, (size.width - CGFloat(barCount) * barSpacing) / CGFloat(barCount))

            for (i, value) in bins.enumerated() {
                let x = CGFloat(i) * (barWidth + barSpacing)
                let h = CGFloat(value) * size.height
                let rect = CGRect(
                    x: x,
                    y: size.height - h,
                    width: barWidth,
                    height: h
                )
                ctx.fill(Path(rect), with: .color(color))
            }
        }
        .drawingGroup()   // Metal-accelerated
    }
}
