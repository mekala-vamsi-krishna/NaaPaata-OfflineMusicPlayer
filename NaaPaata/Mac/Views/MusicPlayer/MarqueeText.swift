//
//  MarqueeText.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/15/26.
//

import SwiftUI

struct MarqueeText: View {

    let text: String
    let font: Font
    let color: Color

    private let gap: CGFloat = 40
    private let pointsPerSecond: CGFloat = 30
    private let pauseDuration: Double = 1.5

    @State private var textWidth: CGFloat = 0
    @State private var offset: CGFloat = 0
    @State private var animationTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { geometry in
            let containerWidth = geometry.size.width
            let needsScroll = textWidth > containerWidth

            HStack(spacing: gap) {
                Text(text)
                    .font(font)
                    .foregroundStyle(color)
                    .fixedSize()

                if needsScroll {
                    Text(text)
                        .font(font)
                        .foregroundStyle(color)
                        .fixedSize()
                }
            }
            .offset(x: offset)
            .frame(width: containerWidth, alignment: .leading)
            .clipped()
            .background(
                Text(text)
                    .font(font)
                    .fixedSize()
                    .hidden()
                    .background(
                        GeometryReader { textGeo in
                            Color.clear.preference(
                                key: MarqueeTextWidthKey.self,
                                value: textGeo.size.width
                            )
                        }
                    )
            )
            .onPreferenceChange(MarqueeTextWidthKey.self) { newWidth in
                textWidth = newWidth
                startAnimationIfNeeded(containerWidth: containerWidth)
            }
            .onChange(of: text) { _, _ in
                offset = 0
                startAnimationIfNeeded(containerWidth: containerWidth)
            }
            .onDisappear {
                animationTask?.cancel()
                animationTask = nil
            }
        }
    }

    private func startAnimationIfNeeded(containerWidth: CGFloat) {
        animationTask?.cancel()
        offset = 0

        guard textWidth > containerWidth, textWidth > 0 else { return }

        let totalDistance = textWidth + gap
        let scrollDuration = Double(totalDistance / pointsPerSecond)

        animationTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(pauseDuration * 1_000_000_000))

            while !Task.isCancelled {
                withAnimation(.linear(duration: scrollDuration)) {
                    offset = -totalDistance
                }

                try? await Task.sleep(nanoseconds: UInt64(scrollDuration * 1_000_000_000))
                if Task.isCancelled { break }

                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    offset = 0
                }

                try? await Task.sleep(nanoseconds: UInt64(pauseDuration * 1_000_000_000))
            }
        }
    }
}

struct MarqueeTextWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
