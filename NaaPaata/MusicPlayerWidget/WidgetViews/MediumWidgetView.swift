//
//  MediumWidgetView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 6/27/26.
//

import SwiftUI
import AppIntents
import WidgetKit

struct MediumWidgetView: View {
    let title: String
    let artist: String
    let artworkData: Data?
    let isPlaying: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 1. Full‑bleed blurred artwork background
                if let data = artworkData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .blur(radius: 20)
                        .overlay(.ultraThinMaterial)
                } else {
                    // Fallback gradient
                    LinearGradient(
                        colors: [
                            Color(red: 0.2, green: 0.2, blue: 0.3),
                            Color(red: 0.1, green: 0.1, blue: 0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .overlay(.ultraThinMaterial)
                }

                HStack(alignment: .center, spacing: 16) {
                    // Left: Square artwork (full height with padding)
                    let imageSize = geometry.size.height - 20
                    if let data = artworkData, let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: imageSize, height: imageSize)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .padding(.leading, 10)
                    } else {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(.gray.opacity(0.3))
                            .frame(width: imageSize, height: imageSize)
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white.opacity(0.5))
                            )
                            .padding(.leading, 10)
                    }

                    // Right: Text + controls (vertically centered)
                    VStack(alignment: .leading, spacing: 6) {
                        Spacer()

                        Text(title ?? "No song playing")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .shadow(radius: 1)

                        Text(artist ?? " ")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                            .shadow(radius: 1)

                        Spacer(minLength: 6)

                        // Playback controls
                        HStack(spacing: 20) {
                            Button(intent: PreviousIntent()) {
                                Image(systemName: "backward.fill")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                                    .shadow(radius: 1)
                            }
                            .buttonStyle(PlainButtonStyle())

                            Button(intent: PlayPauseIntent()) {
                                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                                    .shadow(radius: 2)
                            }
                            .buttonStyle(PlainButtonStyle())

                            Button(intent: NextIntent()) {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                                    .shadow(radius: 1)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        Spacer()
                    }
                    .padding(.trailing, 12)
                    .frame(maxHeight: .infinity)

                    Spacer(minLength: 4)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .containerBackground(.clear, for: .widget)
    }
}
