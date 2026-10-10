//
//  AnimatedDotsLoader.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 6/24/26.
//

import SwiftUI

struct AnimatedDotsLoader: View {
    @State private var dotIndex = 0
    
    let dotCount = 3
    let animationDuration: Double = 0.6
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<dotCount, id: \.self) { index in
                Circle()
                    .fill(AppColors.primary)
                    .frame(width: 12, height: 12)
                    .scaleEffect(dotIndex == index ? 1.2 : 0.6)
                    .opacity(dotIndex == index ? 1.0 : 0.3)
                    .animation(
                        Animation.easeInOut(duration: animationDuration)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.15),
                        value: dotIndex
                    )
            }
        }
        .onAppear {
            dotIndex = 0
            // Start a timer to cycle through dots
            Timer.scheduledTimer(withTimeInterval: animationDuration / 2, repeats: true) { _ in
                withAnimation {
                    dotIndex = (dotIndex + 1) % dotCount
                }
            }
        }
    }
}

#Preview {
    AnimatedDotsLoader()
        .padding()
        .background(Color.black)
}
