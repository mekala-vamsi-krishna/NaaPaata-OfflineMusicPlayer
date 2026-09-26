//
//  SmartPlaylistCardView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/21/26.
//

import SwiftUI

struct SmartPlaylistCardView: View {

    let kind: SmartPlaylistKind
    let count: Int

    static let cardWidth: CGFloat = PlaylistCardView.cardWidth

    var body: some View {
        ZStack(alignment: .topLeading) {

            // Brand gradient
            kind.gradient

            // Title + count
            VStack(alignment: .leading, spacing: 4) {
                Text(kind.title)
                    .font(.system(size: 19, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .shadow(color: .black.opacity(0.35), radius: 4, y: 1)

                Text("\(count) song\(count == 1 ? "" : "s")")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.82))
                    .shadow(color: .black.opacity(0.3), radius: 3, y: 1)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            // Icon in the bottom-right corner
            Image(systemName: kind.systemImage)
                .font(.system(size: 56, weight: .black))
                .foregroundStyle(.white.opacity(0.35))
                .rotationEffect(.degrees(15))
                .padding(.trailing, 16)
                .padding(.bottom, 14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .allowsHitTesting(false)
        }
        .frame(width: Self.cardWidth, height: Self.cardWidth)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.22),
                            .white.opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: AppColor.primary.opacity(0.35), radius: 12, y: 6)
        .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
    }
}
