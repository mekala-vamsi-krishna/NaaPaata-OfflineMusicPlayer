//
//  NudgeButton.swift
//  Mac
//
//  Created by Mekala Vamsi Krishna on 10/13/26.
//

import SwiftUI

struct NudgeButton: View {
    @State private var isAnimating = false

    let systemName: String
    let direction: CGFloat
    let size: CGFloat
    let iconSize: CGFloat
    let action: () -> Void

    private let slideDistance: CGFloat = 16
    private let exitDuration: Double = 0.16
    private let entryDuration: Double = 0.32

    @State private var offsetX: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        Button {
            action()
            nudge()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .offset(x: offsetX)
                .opacity(opacity)
        }
        .buttonStyle(.plain)
        .focusable(false)
    }

    private func nudge() {
        guard !isAnimating else { return }
        isAnimating = true

        withAnimation(.easeIn(duration: exitDuration)) {
            offsetX = direction * slideDistance
            opacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + exitDuration) {
            var t = Transaction()
            t.disablesAnimations = true
            withTransaction(t) {
                offsetX = -direction * slideDistance
            }
            withAnimation(.easeOut(duration: entryDuration)) {
                offsetX = 0
                opacity = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + entryDuration) {
                isAnimating = false
            }
        }
    }
}
