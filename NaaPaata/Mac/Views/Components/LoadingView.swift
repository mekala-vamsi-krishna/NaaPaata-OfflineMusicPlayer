//
//  LoadingView.swift
//  Mac
//
//  Created by Mekala Vamsi Krishna on 10/6/26.
//

import SwiftUI

struct LoadingView: View {

    var message: String = "Loading the good vibes…"
    var subtitle: String?

    var body: some View {
        VStack(spacing: 22) {

            EqualizerBars(
                isPlaying: true,
                size: 64,
                barCount: 5,
                color: AppColor.primary
            )

            VStack(spacing: 4) {
                Text(message)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
    }
}

// MARK: - Preview

#Preview {
    LoadingView()
        .frame(width: 400, height: 400)
        .background(Color(nsColor: .windowBackgroundColor))
}
