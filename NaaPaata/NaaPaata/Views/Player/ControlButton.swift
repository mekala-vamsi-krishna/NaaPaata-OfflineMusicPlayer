//
//  ControlButton.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 6/24/26.
//
import SwiftUI

struct ControlButton: View {
    let icon: String
    let isActive: Bool
    let action: () -> Void

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
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(isActive ? Color.white : Color.white.opacity(0.5))
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(isActive ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
                )
                .shadow(color: isActive ? Color.white.opacity(0.2) : .clear, radius: 4)
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isActive)
        }
        .buttonStyle(.plain)
    }
}
