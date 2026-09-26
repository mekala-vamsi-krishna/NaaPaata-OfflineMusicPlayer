//
//  EqualizerBars.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/16/26.
//

import SwiftUI

struct EqualizerBars: View {

    let isPlaying: Bool
    var size: CGFloat = 36
    var barCount: Int = 4
    var color: Color = AppColor.primary

    private let barSpacing: CGFloat = 3
    private let minHeightRatio: CGFloat = 0.15
    private let speed: Double = 5.5

    /// Keeps the tallest bar off the canvas edge so antialiasing never
    /// makes the bars look shaved at the top or bottom.
    private let verticalInset: CGFloat = 1

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !isPlaying)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, canvasSize in
                drawBars(in: &context, size: canvasSize, time: time)
            }
            .frame(width: size, height: size)
        }
        .transaction { $0.animation = nil }
    }

    private func drawBars(
        in context: inout GraphicsContext,
        size canvasSize: CGSize,
        time: TimeInterval
    ) {
        let totalSpacing = barSpacing * CGFloat(barCount - 1)
        let barWidth = max((canvasSize.width - totalSpacing) / CGFloat(barCount), 2)

        // Usable vertical space, excluding the top/bottom inset.
        let usableHeight = max(canvasSize.height - verticalInset * 2, 1)

        for index in 0..<barCount {
            let ratio = barHeightRatio(index: index, time: time)
            let height = max(usableHeight * CGFloat(ratio), barWidth)
            let x = CGFloat(index) * (barWidth + barSpacing)
            let y = verticalInset + (usableHeight - height) / 2

            let rect = CGRect(x: x, y: y, width: barWidth, height: height)
            let path = Path(roundedRect: rect, cornerRadius: barWidth / 2)

            context.fill(path, with: .color(color))
        }
    }

    private func barHeightRatio(index: Int, time: TimeInterval) -> Double {
        let phase = Double(index) * 0.9

        let wave1 = sin(time * speed + phase)
        let wave2 = sin(time * speed * 0.6 + phase * 1.7)
        let combined = (wave1 + wave2) / 2

        let normalized = (combined + 1) / 2
        return minHeightRatio + (1 - minHeightRatio) * normalized
    }
}

// MARK: - Equatable

extension EqualizerBars: Equatable {
    static func == (lhs: EqualizerBars, rhs: EqualizerBars) -> Bool {
        lhs.isPlaying == rhs.isPlaying
            && lhs.size == rhs.size
            && lhs.barCount == rhs.barCount
    }
}
