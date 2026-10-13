//
//  ProgressBar.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 6/24/26.
//

import SwiftUI

struct ProgressBar: View {
    @Binding var currentTime: TimeInterval
    let duration: TimeInterval
    let onDragChanged: (TimeInterval) -> Void

    @State private var isDragging = false
    @State private var dragTime: TimeInterval = 0

    // The time we actually display: dragTime when dragging, else currentTime
    private var displayTime: TimeInterval {
        isDragging ? dragTime : currentTime
    }

    // Height of the bar: bigger when dragging
    private var barHeight: CGFloat {
        isDragging ? 10 : 6
    }

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Uncompleted track
                    Capsule()
                        .fill(Color.gray.opacity(0.25))
                        .frame(height: barHeight)

                    // Completed track
                    Capsule()
                        .fill(Color.white)
                        .frame(width: progressWidth(totalWidth: geometry.size.width), height: barHeight)
                        .animation(.linear(duration: 0.1), value: displayTime)
                }
                .frame(height: max(barHeight, 30))
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let newX = max(0, min(geometry.size.width, value.location.x))
                            let progress = newX / geometry.size.width
                            let newTime = progress * duration

                            // Update dragTime but do NOT seek yet
                            if !isDragging {
                                isDragging = true
                            }
                            dragTime = newTime
                        }
                        .onEnded { value in
                            let newX = max(0, min(geometry.size.width, value.location.x))
                            let progress = newX / geometry.size.width
                            let finalTime = progress * duration

                            // Update currentTime and trigger seek
                            currentTime = finalTime
                            onDragChanged(finalTime)
                            
                            DispatchQueue.main.async {
                                isDragging = false
                                dragTime = 0
                            }
                        }
                )
            }
            .frame(height: max(barHeight, 30))

            // Time labels – update during drag
            HStack {
                Text(formatTime(displayTime))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                Text(formatTime(duration))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }

    // MARK: - Helpers
    private func progressWidth(totalWidth: CGFloat) -> CGFloat {
        guard duration > 0 else { return 0 }
        let progress = min(displayTime / duration, 1)
        return totalWidth * CGFloat(progress)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite && !time.isNaN && time >= 0 else { return "00:00" }
        let mins = Int(time) / 60
        let secs = Int(time) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
