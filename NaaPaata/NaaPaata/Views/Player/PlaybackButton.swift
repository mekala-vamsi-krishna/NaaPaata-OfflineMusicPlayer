//
//  PlaybackButton.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 6/24/26.
//

import SwiftUI

struct PlaybackButton: View {
    let icon: String
    let size: CGFloat
    let action: () -> Void
    var matchedGeometryID: String? = nil
    var namespace: Namespace.ID? = nil

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)) {
                    isPressed = false
                }
            }
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .medium))
                .foregroundColor(.white)
                .frame(width: size + 20, height: size + 20)
                .scaleEffect(isPressed ? 0.85 : 1.0)
                .modifier(MatchedGeometryIfAvailable(id: matchedGeometryID, namespace: namespace))
        }
        .buttonStyle(.plain)
    }
}
