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
    let colorScheme: ColorScheme

    @State private var isDragging = false

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill((colorScheme == .dark ? Color.white : Color.black).opacity(0.12))
                        .frame(height: 3)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.primary, AppColors.primary.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: progressWidth(totalWidth: geometry.size.width), height: 3)
                        .animation(.linear(duration: 0.1), value: currentTime)

                    Circle()
                        .fill(Color.white)
                        .frame(width: 14, height: 14)
                        .shadow(color: AppColors.primary.opacity(0.4), radius: 4, x: 0, y: 0)
                        .offset(x: circleXPosition(geometry: geometry), y: 0)
                        .animation(isDragging ? nil : .linear(duration: 0.1), value: currentTime)
                }
                .frame(height: 30)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            let newPosition = max(0, min(geometry.size.width, value.location.x))
                            let progress = newPosition / geometry.size.width
                            let newTime = progress * duration
                            currentTime = newTime
                            onDragChanged(newTime)
                        }
                        .onEnded { value in
                            isDragging = false
                            let newPosition = max(0, min(geometry.size.width, value.location.x))
                            let progress = newPosition / geometry.size.width
                            let newTime = progress * duration
                            currentTime = newTime
                            onDragChanged(newTime)
                        }
                )
            }
            .frame(height: 30)

            HStack {
                Text(formatTime(currentTime))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor((colorScheme == .dark ? Color.white : Color.black).opacity(0.6))
                Spacer()
                Text(formatTime(duration))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor((colorScheme == .dark ? Color.white : Color.black).opacity(0.6))
            }
        }
    }

    private func progressWidth(totalWidth: CGFloat) -> CGFloat {
        guard duration > 0 else { return 0 }
        return totalWidth * CGFloat(currentTime / duration)
    }

    private func circleXPosition(geometry: GeometryProxy) -> CGFloat {
        guard duration > 0 else { return 0 }
        let halfCircle: CGFloat = 7
        let progress = CGFloat(currentTime / duration)
        let position = progress * geometry.size.width - halfCircle
        let maxOffset = geometry.size.width - 14
        return max(0, min(maxOffset, position))
    }

    private func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite && !time.isNaN && time >= 0 else { return "00:00" }
        let mins = Int(time) / 60
        let secs = Int(time) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
