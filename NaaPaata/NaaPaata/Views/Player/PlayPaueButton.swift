//
//  PlayPaueButton.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 6/24/26.
//

import SwiftUI

struct PlayPauseButton: View {
    let isPlaying: Bool
    let size: CGFloat
    let action: () -> Void
    let colorScheme: ColorScheme

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            action()
        }) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: size, height: size)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        (colorScheme == .dark ? Color.white : Color.black).opacity(0.3),
                                        (colorScheme == .dark ? Color.white : Color.black).opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .scaleEffect(isPressed ? 0.92 : 1.0)

                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .contentTransition(.symbolEffect(.replace))
                    .scaleEffect(isPressed ? 0.92 : 1.0)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
