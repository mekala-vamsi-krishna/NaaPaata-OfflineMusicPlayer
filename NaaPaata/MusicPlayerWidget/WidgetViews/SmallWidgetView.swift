//
//  SmallWidgetView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 6/27/26.
//

import SwiftUI
import AppIntents
import WidgetKit

struct SmallWidgetView: View {
    let title: String
    let artist: String
    let artworkData: Data?
    let isPlaying: Bool

    var body: some View {
        ZStack {
            // 1. Full‑bleed artwork – fills the entire widget
            if let data = artworkData, let image = UIImage(data: data) {
                GeometryReader { proxy in

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width: proxy.size.width,
                            height: proxy.size.height
                        )
                        .clipped()
                }
            } else {
                // Elegant fallback gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.2, green: 0.2, blue: 0.3),
                        Color(red: 0.1, green: 0.1, blue: 0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: 40, weight: .thin))
                        .foregroundColor(.white.opacity(0.15))
                )
            }

            // 2. Subtle gradient overlay for text readability (bottom half)
            LinearGradient(
                colors: [
                    .clear,
                    .black.opacity(0.1),
                    .black.opacity(0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // 3. Content overlay
            VStack {
                // Top row: play button at top‑right
                HStack {
                    Spacer()
                    Button(intent: PlayPauseIntent()) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 38, height: 38)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [.white.opacity(0.4), .white.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 0.8
                                        )
                                )
                                .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 2)

                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .shadow(radius: 1)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.top, 12)
                .padding(.trailing, 12)

                Spacer()

                // Bottom row: title & artist at bottom‑leading
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .shadow(radius: 1)
                    Text(artist)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                        .shadow(radius: 1)
                }
                .padding(.leading, 12)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}
