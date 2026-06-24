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
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(isActive ? AppColors.primary : (colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6)))
                .frame(width: 44, height: 44)
                .background(isActive ? (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05)) : Color.clear)
                .clipShape(Circle())
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isActive)
        }
    }
}
