//
//  EqualizerBars.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 7/28/26.
//

import SwiftUI

struct EqualizerBars: View {

    let isPlaying: Bool
    var size: CGFloat = 16
    var barCount: Int = 3
    var color: Color = .accentColor

    @State private var heights: [CGFloat]
    @State private var animationTask: Task<Void, Never>?

    private let tickInterval: Double = 0.3
    private let minHeight: CGFloat = 3
    private let maxHeight: CGFloat = 16

    init(
        isPlaying: Bool,
        size: CGFloat = 16,
        barCount: Int = 3,
        color: Color = .accentColor
    ) {
        self.isPlaying = isPlaying
        self.size = size
        self.barCount = barCount
        self.color = color

        // Start with evenly-spaced mid-height bars so the initial render
        // isn't a flat line.
        let initial = Array(repeating: size * 0.5, count: barCount)
        _heights = State(initialValue: initial)
    }

    var body: some View {
        HStack(alignment: .center, spacing: barSpacing) {
            ForEach(0..<barCount, id: \.self) { index in
                Capsule()
                    .fill(color)
                    .frame(width: barWidth, height: heights[index])
            }
        }
        .frame(width: size, height: size)
        .onAppear { updateAnimationState() }
        .onDisappear { stopAnimation() }
        .onChange(of: isPlaying) { _, _ in updateAnimationState() }
    }

    // MARK: - Layout

    private var barSpacing: CGFloat {
        max(size * 0.08, 2)
    }

    private var barWidth: CGFloat {
        let totalSpacing = barSpacing * CGFloat(barCount - 1)
        return max((size - totalSpacing) / CGFloat(barCount), 2)
    }

    // MARK: - Animation

    private func updateAnimationState() {
        stopAnimation()

        guard isPlaying else {
            // Freeze the bars mid-height when paused — same visual as
            // the macOS version. Reads as "this row is the current
            // song, currently paused".
            withAnimation(.easeOut(duration: 0.25)) {
                heights = Array(repeating: size * 0.35, count: barCount)
            }
            return
        }

        animationTask = Task { @MainActor in
            while !Task.isCancelled {
                let newHeights = (0..<barCount).map { _ in
                    CGFloat.random(in: minHeight...maxHeight)
                        * (size / 16)
                }

                withAnimation(.easeInOut(duration: tickInterval * 0.9)) {
                    heights = newHeights
                }

                try? await Task.sleep(
                    nanoseconds: UInt64(tickInterval * 1_000_000_000)
                )
            }
        }
    }

    private func stopAnimation() {
        animationTask?.cancel()
        animationTask = nil
    }
}
