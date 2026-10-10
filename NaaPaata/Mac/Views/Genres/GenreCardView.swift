//
//  GenreCardView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/26/26.
//

import SwiftUI
import AppKit

struct GenreCardView: View {

    let genre: Genre
    let width: CGFloat

    /// 1.6:1 landscape ratio.
    private var height: CGFloat { width / 1.6 }

    private var cornerRadius: CGFloat { 14 }

    private var thumbnailSize: CGFloat { width * 0.46 }

    var body: some View {
        ZStack(alignment: .topLeading) {

            blurredBackground

            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.55), location: 0.0),
                    .init(color: .black.opacity(0.20), location: 0.5),
                    .init(color: .black.opacity(0.0),  location: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(genre.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .shadow(color: .black.opacity(0.5), radius: 4, y: 1)

                Text(genre.subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.82))
                    .shadow(color: .black.opacity(0.4), radius: 3, y: 1)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            tiltedThumbnail
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.22), radius: 10, y: 5)
    }

    // MARK: - Blurred background

    private var blurredBackground: some View {
        ZStack {
            if let data = genre.artworkData,
               let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .blur(radius: 40)
                    .saturation(1.6)
                    .opacity(0.95)
            } else {
                AppColor.brandGradient
            }
        }
        .frame(width: width, height: height)
        .clipped()
    }

    // MARK: - Tilted thumbnail

    private var tiltedThumbnail: some View {
        ZStack {
            if let data = genre.artworkData,
               let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    AppColor.brandGradient
                    Image(systemName: "guitars")
                        .font(.system(size: thumbnailSize * 0.28, weight: .light))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .frame(width: thumbnailSize, height: thumbnailSize)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .rotationEffect(.degrees(20))
        .shadow(color: .black.opacity(0.4), radius: 8, y: 3)
        .offset(x: 14, y: 14)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .bottomTrailing
        )
        .padding(.trailing, -2)
        .padding(.bottom, -2)
        .allowsHitTesting(false)
    }
}
