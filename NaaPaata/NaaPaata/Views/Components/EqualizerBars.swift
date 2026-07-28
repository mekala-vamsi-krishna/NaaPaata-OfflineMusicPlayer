//
//  EqualizerBars.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 7/28/26.
//

import SwiftUI

struct EqualizerBars: View {
    @State private var heights: [CGFloat] = [5, 10, 7]
    @Environment(\.scenePhase) private var scenePhase
    @State private var isAnimating = false
    
    let isPlaying: Bool
    private let timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<heights.count, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppColors.primary)
                    .frame(width: 3, height: heights[i])
            }
        }
        .onReceive(timer) { _ in
            guard isPlaying else { return }
            withAnimation(.linear(duration: 0.25)) {
                heights = heights.map { _ in CGFloat(Int.random(in: 5...15)) }
            }
        }
        .onChange(of: isPlaying) { newValue in
            if !newValue {
                withAnimation(.easeOut(duration: 0.3)) {
                    heights = [5, 5, 5]
                }
            }
        }
    }
}
