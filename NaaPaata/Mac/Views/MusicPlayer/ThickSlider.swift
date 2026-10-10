//
//  ThickSlider.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/15/26.
//

import SwiftUI

struct ThickSlider: View {

    let value: Double
    var trackHeight: CGFloat = 4
    var thumbSize: CGFloat = 12
    var onSeek: (Double) -> Void

    @State private var dragValue: Double?
    @State private var committedValue: Double?

    private var isDragging: Bool { dragValue != nil }
    private var displayValue: Double { dragValue ?? committedValue ?? value }

    private var effectiveTrackHeight: CGFloat {
        isDragging ? trackHeight * 2 : trackHeight
    }

    private var effectiveThumbSize: CGFloat {
        isDragging ? thumbSize * 1.5 : thumbSize
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let clamped = min(max(displayValue, 0), 1)

            // Thumb center: 0 → thumbSize/2, 1 → width - thumbSize/2
            let thumbCenter = effectiveThumbSize / 2
                + (width - effectiveThumbSize) * clamped

            // Fill spans from the leading edge to the thumb's center
            let fillWidth = thumbCenter

            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(.white.opacity(0.28))
                    .frame(width: width, height: effectiveTrackHeight)

                // Filled track — 0 → thumb center
                Capsule()
                    .fill(.white)
                    .frame(
                        width: max(fillWidth, effectiveTrackHeight),
                        height: effectiveTrackHeight
                    )

                // Thumb
                Circle()
                    .fill(.white)
                    .frame(width: effectiveThumbSize, height: effectiveThumbSize)
                    .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                    .offset(x: thumbCenter - effectiveThumbSize / 2)
            }
            // Fixed height — always the max, so children grow symmetrically
            .frame(width: width, height: thumbSize * 1.5)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let ratio = gesture.location.x / width
                        let clamped = min(1, max(0, ratio))

                        if dragValue == nil {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                dragValue = clamped
                            }
                        } else {
                            dragValue = clamped
                        }
                    }
                    .onEnded { _ in
                        if let finalValue = dragValue {
                            committedValue = finalValue
                            onSeek(finalValue)
                        }

                        withAnimation(.easeInOut(duration: 0.15)) {
                            dragValue = nil
                        }
                    }
            )
        }
        .frame(height: thumbSize * 1.5)
        .onChange(of: value) { _, newValue in
            if let committed = committedValue,
               abs(newValue - committed) < 0.001 {
                committedValue = nil
            }
        }
    }
}
